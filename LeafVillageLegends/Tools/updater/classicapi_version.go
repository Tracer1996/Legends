package main

import (
	"fmt"
	"unsafe"

	"golang.org/x/sys/windows"
)

// version.dll bindings to read a PE file's embedded VS_VERSIONINFO
// FileVersion (the same value Explorer's Properties > Details tab shows)
// - split into its own file, unlike the rest of classicapi.go, since this
// is the one piece that genuinely needs a Windows API rather than plain
// stdlib, and keeping it isolated made the rest of that file easy to
// exercise with a throwaway Linux test program while developing it.
var (
	verDLL                      = windows.NewLazySystemDLL("version.dll")
	procGetFileVersionInfoSizeW = verDLL.NewProc("GetFileVersionInfoSizeW")
	procGetFileVersionInfoW     = verDLL.NewProc("GetFileVersionInfoW")
	procVerQueryValueW          = verDLL.NewProc("VerQueryValueW")
)

// vsFixedFileInfo mirrors the Win32 VS_FIXEDFILEINFO struct. FileVersionMS
// packs the major version in its high 16 bits and minor in its low 16;
// FileVersionLS packs build (high) and revision (low) the same way.
type vsFixedFileInfo struct {
	Signature        uint32
	StrucVersion     uint32
	FileVersionMS    uint32
	FileVersionLS    uint32
	ProductVersionMS uint32
	ProductVersionLS uint32
	FileFlagsMask    uint32
	FileFlags        uint32
	FileOS           uint32
	FileType         uint32
	FileSubtype      uint32
	FileDateMS       uint32
	FileDateLS       uint32
}

// fileVersion reads the four-part FileVersion (e.g. "1.15.7.0") from a
// PE file's version resource. Detects a ClassicAPI.dll that was placed
// there manually, or by a previous version of this tool, without relying
// on our own install having recorded it in updater-config.json.
func fileVersion(path string) (string, error) {
	pPath, err := windows.UTF16PtrFromString(path)
	if err != nil {
		return "", err
	}

	var handle uint32
	size, _, _ := procGetFileVersionInfoSizeW.Call(uintptr(unsafe.Pointer(pPath)), uintptr(unsafe.Pointer(&handle)))
	if size == 0 {
		return "", fmt.Errorf("file has no version info")
	}

	buf := make([]byte, size)
	ok, _, _ := procGetFileVersionInfoW.Call(uintptr(unsafe.Pointer(pPath)), 0, uintptr(size), uintptr(unsafe.Pointer(&buf[0])))
	if ok == 0 {
		return "", fmt.Errorf("GetFileVersionInfoW failed")
	}

	rootPtr, err := windows.UTF16PtrFromString(`\`)
	if err != nil {
		return "", err
	}

	var pFixed unsafe.Pointer
	var fixedLen uint32
	ok2, _, _ := procVerQueryValueW.Call(
		uintptr(unsafe.Pointer(&buf[0])),
		uintptr(unsafe.Pointer(rootPtr)),
		uintptr(unsafe.Pointer(&pFixed)),
		uintptr(unsafe.Pointer(&fixedLen)),
	)
	if ok2 == 0 || pFixed == nil {
		return "", fmt.Errorf("VerQueryValueW failed")
	}

	fixed := (*vsFixedFileInfo)(pFixed)
	major := fixed.FileVersionMS >> 16
	minor := fixed.FileVersionMS & 0xFFFF
	build := fixed.FileVersionLS >> 16
	revision := fixed.FileVersionLS & 0xFFFF
	return fmt.Sprintf("%d.%d.%d.%d", major, minor, build, revision), nil
}
