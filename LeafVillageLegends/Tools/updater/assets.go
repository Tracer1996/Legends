package main

import (
	"bytes"
	_ "embed"
	"image/png"

	"github.com/lxn/walk"
)

// banner.png and icon.png are pre-converted (see assets/gen) from the
// LeafVillageLegends addon's own Textures/ashen_header_banner.tga and
// Textures/ashen_rank_1.tga, so the updater visually matches the addon
// it's updating instead of looking like a generic Win32 tool.
//
//go:embed assets/banner.png
var bannerPNGData []byte

//go:embed assets/icon.png
var iconPNGData []byte

// tavern.wav is trimmed to 60s and downsampled to mono/22050Hz (see
// assets/gen) from the addon's Sounds/magic_tavern.wav, which is
// otherwise 68MB of uncompressed 44.1kHz stereo - full length/quality
// would have nearly 9x'd this exe's size for a background loop.
//
//go:embed assets/tavern.wav
var tavernWAVData []byte

// button_normal/_hover/_pressed.png all derive from the addon's own
// ab_btn.tga (ab_btn_h.tga and ab_btn_d.tga turned out to be byte-identical
// to it - the addon differentiates states at runtime via an additive
// blend layer, not distinct art; see button.go / assets/gen's -brightness
// flag for the equivalent done here ahead of time).
//
//go:embed assets/button_normal.png
var buttonNormalPNGData []byte

//go:embed assets/button_hover.png
var buttonHoverPNGData []byte

//go:embed assets/button_pressed.png
var buttonPressedPNGData []byte

var (
	buttonNormalImg  *walk.Bitmap
	buttonHoverImg   *walk.Bitmap
	buttonPressedImg *walk.Bitmap
)

func init() {
	buttonNormalImg, _ = decodeBitmap(buttonNormalPNGData)
	buttonHoverImg, _ = decodeBitmap(buttonHoverPNGData)
	buttonPressedImg, _ = decodeBitmap(buttonPressedPNGData)
}

func decodeBitmap(data []byte) (*walk.Bitmap, error) {
	img, err := png.Decode(bytes.NewReader(data))
	if err != nil {
		return nil, err
	}
	return walk.NewBitmapFromImage(img)
}

func loadBannerBitmap() (*walk.Bitmap, error) {
	return decodeBitmap(bannerPNGData)
}

func loadAppIcon() (*walk.Icon, error) {
	img, err := png.Decode(bytes.NewReader(iconPNGData))
	if err != nil {
		return nil, err
	}
	return walk.NewIconFromImage(img)
}
