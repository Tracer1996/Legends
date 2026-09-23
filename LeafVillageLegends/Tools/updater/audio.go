package main

import (
	"encoding/binary"
	"fmt"
	"sync"
	"unsafe"

	"golang.org/x/sys/windows"
)

// Minimal winmm.dll waveOut* bindings - just enough to loop one in-memory
// PCM buffer with real per-stream volume control (as opposed to
// PlaySound, which offers no volume/mute hook of its own).
var (
	winmm                      = windows.NewLazySystemDLL("winmm.dll")
	procWaveOutOpen            = winmm.NewProc("waveOutOpen")
	procWaveOutPrepareHeader   = winmm.NewProc("waveOutPrepareHeader")
	procWaveOutWrite           = winmm.NewProc("waveOutWrite")
	procWaveOutUnprepareHeader = winmm.NewProc("waveOutUnprepareHeader")
	procWaveOutReset           = winmm.NewProc("waveOutReset")
	procWaveOutClose           = winmm.NewProc("waveOutClose")
	procWaveOutSetVolume       = winmm.NewProc("waveOutSetVolume")
)

const (
	waveFormatPCM = 1
	waveMapperID  = 0xFFFFFFFF // -1 as UINT: let Windows pick the default output device
	callbackEvent = 0x00050000
	mmsyserrNoErr = 0
)

type waveFormatEx struct {
	wFormatTag      uint16
	nChannels       uint16
	nSamplesPerSec  uint32
	nAvgBytesPerSec uint32
	nBlockAlign     uint16
	wBitsPerSample  uint16
	cbSize          uint16
}

type waveHdr struct {
	lpData          uintptr
	dwBufferLength  uint32
	dwBytesRecorded uint32
	dwUser          uintptr
	dwFlags         uint32
	dwLoops         uint32
	lpNext          uintptr
	reserved        uintptr
}

// parseWAV extracts the fmt/data chunks from a standard (non-extensible)
// PCM .wav file. That's all this app ever embeds, so anything fancier
// (ADPCM, WAVE_FORMAT_EXTENSIBLE, etc.) is out of scope.
func parseWAV(data []byte) (waveFormatEx, []byte, error) {
	var format waveFormatEx
	if len(data) < 12 || string(data[0:4]) != "RIFF" || string(data[8:12]) != "WAVE" {
		return format, nil, fmt.Errorf("not a RIFF/WAVE file")
	}

	var pcm []byte
	haveFormat := false
	pos := 12
	for pos+8 <= len(data) {
		chunkID := string(data[pos : pos+4])
		chunkSize := binary.LittleEndian.Uint32(data[pos+4 : pos+8])
		chunkStart := pos + 8
		chunkEnd := chunkStart + int(chunkSize)
		if chunkEnd > len(data) {
			break
		}

		switch chunkID {
		case "fmt ":
			if chunkSize < 16 {
				return format, nil, fmt.Errorf("fmt chunk too small")
			}
			chunk := data[chunkStart:chunkEnd]
			format.wFormatTag = binary.LittleEndian.Uint16(chunk[0:2])
			format.nChannels = binary.LittleEndian.Uint16(chunk[2:4])
			format.nSamplesPerSec = binary.LittleEndian.Uint32(chunk[4:8])
			format.nAvgBytesPerSec = binary.LittleEndian.Uint32(chunk[8:12])
			format.nBlockAlign = binary.LittleEndian.Uint16(chunk[12:14])
			format.wBitsPerSample = binary.LittleEndian.Uint16(chunk[14:16])
			haveFormat = true
		case "data":
			pcm = data[chunkStart:chunkEnd]
		}

		pos = chunkEnd
		if chunkSize%2 == 1 {
			pos++ // chunks are word-aligned
		}
	}

	if !haveFormat {
		return format, nil, fmt.Errorf("no fmt chunk found")
	}
	if pcm == nil {
		return format, nil, fmt.Errorf("no data chunk found")
	}
	if format.wFormatTag != waveFormatPCM {
		return format, nil, fmt.Errorf("unsupported wFormatTag %d (only PCM is handled)", format.wFormatTag)
	}
	return format, pcm, nil
}

// player loops a single in-memory PCM buffer via waveOut, with real
// per-stream volume/mute (waveOutSetVolume scoped to our own device
// handle - unlike PlaySound, this can't affect any other app's audio).
type player struct {
	mu      sync.Mutex
	hwo     uintptr
	hdr     *waveHdr
	event   windows.Handle
	pcm     []byte // kept alive here so the GC never moves/frees it under winmm
	stopCh  chan struct{}
	started bool

	volume float64 // 0..1, independent of mute
	muted  bool
}

func newPlayer(wavData []byte) (*player, error) {
	format, pcm, err := parseWAV(wavData)
	if err != nil {
		return nil, err
	}

	event, err := windows.CreateEvent(nil, 0 /* auto-reset */, 0 /* initially non-signaled */, nil)
	if err != nil {
		return nil, fmt.Errorf("CreateEvent: %w", err)
	}

	var hwo uintptr
	r1, _, _ := procWaveOutOpen.Call(
		uintptr(unsafe.Pointer(&hwo)),
		uintptr(waveMapperID),
		uintptr(unsafe.Pointer(&format)),
		uintptr(event),
		0,
		uintptr(callbackEvent),
	)
	if r1 != mmsyserrNoErr {
		windows.CloseHandle(event)
		return nil, fmt.Errorf("waveOutOpen failed (mmresult %d) - no audio output device?", r1)
	}

	hdr := &waveHdr{
		lpData:         uintptr(unsafe.Pointer(&pcm[0])),
		dwBufferLength: uint32(len(pcm)),
	}
	if r1, _, _ := procWaveOutPrepareHeader.Call(hwo, uintptr(unsafe.Pointer(hdr)), unsafe.Sizeof(*hdr)); r1 != mmsyserrNoErr {
		procWaveOutClose.Call(hwo)
		windows.CloseHandle(event)
		return nil, fmt.Errorf("waveOutPrepareHeader failed (mmresult %d)", r1)
	}

	return &player{
		hwo:    hwo,
		hdr:    hdr,
		event:  event,
		pcm:    pcm,
		stopCh: make(chan struct{}),
		volume: 1,
	}, nil
}

// Start begins looping playback (already applying the current
// volume/mute) and returns immediately; looping runs on its own
// goroutine until Stop is called.
func (p *player) Start() error {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.started {
		return nil
	}
	p.started = true
	p.applyVolumeLocked()

	if r1, _, _ := procWaveOutWrite.Call(p.hwo, uintptr(unsafe.Pointer(p.hdr)), unsafe.Sizeof(*p.hdr)); r1 != mmsyserrNoErr {
		p.started = false
		return fmt.Errorf("waveOutWrite failed (mmresult %d)", r1)
	}

	go p.loop()
	return nil
}

func (p *player) loop() {
	for {
		r, err := windows.WaitForSingleObject(p.event, 2000)
		select {
		case <-p.stopCh:
			return
		default:
		}
		if err != nil || r == uint32(windows.WAIT_TIMEOUT) {
			continue
		}
		// Buffer finished - resubmit the same header to loop it.
		procWaveOutWrite.Call(p.hwo, uintptr(unsafe.Pointer(p.hdr)), unsafe.Sizeof(*p.hdr))
	}
}

func (p *player) Stop() {
	p.mu.Lock()
	defer p.mu.Unlock()
	if !p.started {
		return
	}
	close(p.stopCh)
	procWaveOutReset.Call(p.hwo)
	procWaveOutUnprepareHeader.Call(p.hwo, uintptr(unsafe.Pointer(p.hdr)), unsafe.Sizeof(*p.hdr))
	procWaveOutClose.Call(p.hwo)
	windows.CloseHandle(p.event)
	p.started = false
}

func (p *player) SetVolume(v float64) {
	p.mu.Lock()
	defer p.mu.Unlock()
	if v < 0 {
		v = 0
	}
	if v > 1 {
		v = 1
	}
	p.volume = v
	p.applyVolumeLocked()
}

func (p *player) SetMuted(muted bool) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.muted = muted
	p.applyVolumeLocked()
}

func (p *player) applyVolumeLocked() {
	if !p.started {
		return
	}
	v := p.volume
	if p.muted {
		v = 0
	}
	v16 := uint16(v * 0xFFFF)
	param := uint32(v16) | uint32(v16)<<16 // same level on both channels
	procWaveOutSetVolume.Call(p.hwo, uintptr(param))
}
