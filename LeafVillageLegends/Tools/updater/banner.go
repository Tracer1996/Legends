package main

import (
	"github.com/lxn/walk"
	. "github.com/lxn/walk/declarative"
)

// titledBanner paints the header banner art with a title drawn on top,
// matching how the addon itself brands "The Ashen Banner" elsewhere
// (gold #D8A24A text, e.g. Core.lua's various SetText("|cFFD8A24AThe Ashen
// Banner|r") lines). Built the same way as texturedButton - a CustomWidget
// so the text can be drawn as real, crisp system-rendered text on top of
// the bitmap rather than baked into the PNG at conversion time.
type titledBanner struct {
	cw    *walk.CustomWidget
	img   *walk.Bitmap
	title string
}

var bannerFont *walk.Font

func init() {
	// Cambria ships with Windows by default and reads as more "banner
	// title" than the UI's regular Segoe UI; NewFont degrades to a
	// substitute font rather than failing if it's somehow missing.
	bannerFont, _ = walk.NewFont("Cambria", 20, walk.FontBold)
}

func TitledBanner(img *walk.Bitmap, title string, size Size) Widget {
	tb := &titledBanner{img: img, title: title}

	inner := CustomWidget{
		AssignTo:            &tb.cw,
		Background:          themeBrush(),
		Paint:               tb.paint,
		InvalidatesOnResize: true,
	}

	// Same greedy-layout-item quirk as texturedButton - pin the size via
	// an outer fixed-size Composite rather than relying on CustomWidget's
	// own MinSize/MaxSize, which it ignores.
	return Composite{
		Layout:   VBox{MarginsZero: true, SpacingZero: true},
		MinSize:  size,
		MaxSize:  size,
		Children: []Widget{inner},
	}
}

func (tb *titledBanner) paint(canvas *walk.Canvas, _ walk.Rectangle) error {
	bounds := tb.cw.ClientBounds()

	if tb.img != nil {
		if err := canvas.DrawImageStretched(tb.img, bounds); err != nil {
			return err
		}
	}

	format := walk.TextCenter | walk.TextVCenter | walk.TextSingleLine

	// Nudged down from dead-center so it clears the banner art's crest
	// emblem instead of sitting on top of it.
	textBounds := bounds
	textBounds.Y += bounds.Height / 10

	shadow := textBounds
	shadow.X += 2
	shadow.Y += 2
	canvas.DrawText(tb.title, bannerFont, walk.RGB(0x1a, 0x14, 0x08), shadow, format)

	return canvas.DrawText(tb.title, bannerFont, themeGold, textBounds, format)
}
