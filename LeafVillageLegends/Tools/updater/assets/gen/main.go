// gen is an offline, one-off tool for converting the LeafVillageLegends
// addon's .tga art into the .png/.ico files the updater embeds. It is not
// part of the shipped updater - it's only run by maintainers when they
// want to swap which texture is used for the banner or app icon.
//
// Usage:
//
//	go run . -in ../../../../Textures/ashen_header_banner.tga -out ../banner.png -w 480
//	go run . -in ../../../../Textures/dossier_wisdom_emblem.tga -out ../icon.ico -ico -sizes 16,32,48,64,128
package main

import (
	"bytes"
	"encoding/binary"
	"flag"
	"fmt"
	"image"
	"image/color"
	"image/png"
	"os"
	"strconv"
	"strings"

	"golang.org/x/image/draw"
)

func main() {
	in := flag.String("in", "", "input .tga path")
	out := flag.String("out", "", "output path (.png or .ico)")
	asIco := flag.Bool("ico", false, "write a multi-size .ico instead of a .png")
	sizesFlag := flag.String("sizes", "16,32,48,64,128", "comma-separated square sizes for -ico")
	width := flag.Int("w", 0, "resize output png to this width (height scaled to match), 0 = no resize")
	tint := flag.String("tint", "", "RRGGBB to multiply-tint the (often near-grayscale, meant to be tinted in-game) source art")
	brightness := flag.Int("brightness", 0, "add this to every RGB channel, clamped 0-255 (negative darkens) - for deriving hover/pressed button states from one base texture")
	flag.Parse()

	if *in == "" || *out == "" {
		fmt.Fprintln(os.Stderr, "usage: gen -in file.tga -out file.png [-w 480] [-tint D8A24A]  |  gen -in file.tga -out file.ico -ico [-sizes 16,32,48,64,128] [-tint D8A24A]")
		os.Exit(2)
	}

	img, err := decodeTGA(*in)
	if err != nil {
		fatal("decode tga: %v", err)
	}

	if *tint != "" {
		tr, tg, tb, err := parseHexColor(*tint)
		if err != nil {
			fatal("bad -tint: %v", err)
		}
		img = tintImage(img, tr, tg, tb)
	}

	if *brightness != 0 {
		img = adjustBrightness(img, *brightness)
	}

	if *asIco {
		sizes, err := parseSizes(*sizesFlag)
		if err != nil {
			fatal("bad -sizes: %v", err)
		}
		if err := writeICO(*out, img, sizes); err != nil {
			fatal("write ico: %v", err)
		}
		fmt.Println("wrote", *out)
		return
	}

	if *width > 0 {
		img = resizeToWidth(img, *width)
	}
	f, err := os.Create(*out)
	if err != nil {
		fatal("create: %v", err)
	}
	defer f.Close()
	if err := png.Encode(f, img); err != nil {
		fatal("encode png: %v", err)
	}
	fmt.Println("wrote", *out)
}

func fatal(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}

func parseSizes(s string) ([]int, error) {
	var sizes []int
	for _, part := range strings.Split(s, ",") {
		n, err := strconv.Atoi(strings.TrimSpace(part))
		if err != nil {
			return nil, err
		}
		sizes = append(sizes, n)
	}
	return sizes, nil
}

func parseHexColor(s string) (r, g, b byte, err error) {
	s = strings.TrimPrefix(s, "#")
	if len(s) != 6 {
		return 0, 0, 0, fmt.Errorf("expected 6 hex digits (RRGGBB), got %q", s)
	}
	v, err := strconv.ParseUint(s, 16, 32)
	if err != nil {
		return 0, 0, 0, err
	}
	return byte(v >> 16), byte(v >> 8), byte(v), nil
}

// tintImage multiplies each pixel's RGB by tr/tg/tb (as 0-255 factors over
// 255), leaving alpha untouched. Many WoW UI textures are painted
// near-grayscale/white and are colorized in-game via vertex color; this
// reproduces that so the art doesn't look washed out standalone.
func tintImage(img image.Image, tr, tg, tb byte) image.Image {
	b := img.Bounds()
	dst := image.NewRGBA(b)
	for y := b.Min.Y; y < b.Max.Y; y++ {
		for x := b.Min.X; x < b.Max.X; x++ {
			r, g, bl, a := img.At(x, y).RGBA()
			// img.At returns 16-bit-per-channel values; scale down to 8-bit.
			r8, g8, b8, a8 := byte(r>>8), byte(g>>8), byte(bl>>8), byte(a>>8)
			nr := byte(uint16(r8) * uint16(tr) / 255)
			ng := byte(uint16(g8) * uint16(tg) / 255)
			nb := byte(uint16(b8) * uint16(tb) / 255)
			dst.SetRGBA(x, y, color.RGBA{R: nr, G: ng, B: nb, A: a8})
		}
	}
	return dst
}

// adjustBrightness adds delta to every RGB channel, clamped to 0-255.
// Mirrors the addon's own hover/pressed technique (see
// ApplyAshenUniversalButtonTexture in Core.lua): it reuses one button
// texture for every state and lightens it on hover via an additive blend
// layer (SetBlendMode("ADD")) rather than having distinct hover/pressed
// art - ab_btn/_h/_d.tga are in fact byte-identical files.
func adjustBrightness(img image.Image, delta int) image.Image {
	b := img.Bounds()
	dst := image.NewRGBA(b)
	for y := b.Min.Y; y < b.Max.Y; y++ {
		for x := b.Min.X; x < b.Max.X; x++ {
			r, g, bl, a := img.At(x, y).RGBA()
			r8, g8, b8, a8 := byte(r>>8), byte(g>>8), byte(bl>>8), byte(a>>8)
			dst.SetRGBA(x, y, color.RGBA{R: clampAdd(r8, delta), G: clampAdd(g8, delta), B: clampAdd(b8, delta), A: a8})
		}
	}
	return dst
}

func clampAdd(v byte, delta int) byte {
	n := int(v) + delta
	if n < 0 {
		return 0
	}
	if n > 255 {
		return 255
	}
	return byte(n)
}

func resizeToWidth(img image.Image, width int) image.Image {
	b := img.Bounds()
	height := b.Dy() * width / b.Dx()
	dst := image.NewRGBA(image.Rect(0, 0, width, height))
	draw.CatmullRom.Scale(dst, dst.Bounds(), img, b, draw.Over, nil)
	return dst
}

func resizeSquare(img image.Image, size int) image.Image {
	dst := image.NewRGBA(image.Rect(0, 0, size, size))
	draw.CatmullRom.Scale(dst, dst.Bounds(), img, img.Bounds(), draw.Over, nil)
	return dst
}

// --- minimal uncompressed-truecolor TGA decoder ---
// Handles image type 2 (uncompressed truecolor), 24 or 32 bpp, which is
// what every texture in LeafVillageLegends/Textures uses.

func decodeTGA(path string) (image.Image, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	if len(data) < 18 {
		return nil, fmt.Errorf("file too small to be a tga")
	}

	idLen := int(data[0])
	imgType := data[2]
	width := int(binary.LittleEndian.Uint16(data[12:14]))
	height := int(binary.LittleEndian.Uint16(data[14:16]))
	bpp := int(data[16])
	descriptor := data[17]
	topDown := descriptor&0x20 != 0

	if imgType != 2 {
		return nil, fmt.Errorf("unsupported tga image type %d (only uncompressed truecolor/type 2 is handled)", imgType)
	}
	if bpp != 24 && bpp != 32 {
		return nil, fmt.Errorf("unsupported tga bit depth %d (only 24/32 handled)", bpp)
	}

	offset := 18 + idLen
	bytesPerPixel := bpp / 8
	rowSize := width * bytesPerPixel
	if len(data) < offset+rowSize*height {
		return nil, fmt.Errorf("file shorter than expected pixel data")
	}

	img := image.NewRGBA(image.Rect(0, 0, width, height))
	for row := 0; row < height; row++ {
		srcRow := row
		if !topDown {
			srcRow = height - 1 - row // tga default origin is bottom-left
		}
		rowStart := offset + srcRow*rowSize
		for col := 0; col < width; col++ {
			p := rowStart + col*bytesPerPixel
			b := data[p]
			g := data[p+1]
			r := data[p+2]
			a := byte(255)
			if bytesPerPixel == 4 {
				a = data[p+3]
			}
			img.SetRGBA(col, row, color.RGBA{R: r, G: g, B: b, A: a})
		}
	}
	return img, nil
}

// --- minimal ICO writer (PNG-compressed frames, supported since Vista) ---

type icoEntry struct {
	size int
	png  []byte
}

func writeICO(path string, src image.Image, sizes []int) error {
	var entries []icoEntry
	for _, size := range sizes {
		resized := resizeSquare(src, size)
		var buf bytes.Buffer
		if err := png.Encode(&buf, resized); err != nil {
			return err
		}
		entries = append(entries, icoEntry{size: size, png: buf.Bytes()})
	}

	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	// ICONDIR
	binary.Write(f, binary.LittleEndian, uint16(0)) // reserved
	binary.Write(f, binary.LittleEndian, uint16(1)) // type: icon
	binary.Write(f, binary.LittleEndian, uint16(len(entries)))

	headerSize := 6 + 16*len(entries)
	offset := uint32(headerSize)
	for _, e := range entries {
		dim := byte(e.size)
		if e.size >= 256 {
			dim = 0 // 0 means 256 in ICO format
		}
		f.Write([]byte{dim, dim, 0, 0})                          // width, height, colorCount, reserved
		binary.Write(f, binary.LittleEndian, uint16(1))          // planes
		binary.Write(f, binary.LittleEndian, uint16(32))         // bitcount
		binary.Write(f, binary.LittleEndian, uint32(len(e.png))) // bytes in resource
		binary.Write(f, binary.LittleEndian, offset)             // offset
		offset += uint32(len(e.png))
	}
	for _, e := range entries {
		f.Write(e.png)
	}
	return nil
}
