package main

import (
	"sync"
	"time"

	"github.com/lxn/walk"
	. "github.com/lxn/walk/declarative"
	"github.com/lxn/win"
)

// texturedButton is a button skinned with the addon's own ab_btn.tga /
// ab_btn_h.tga / ab_btn_d.tga (normal/hover/pressed) textures instead of a
// stock Win32 button face. walk's CustomWidget gives us Paint plus
// mouse down/up, which covers the "pressed" state directly; hover has no
// equivalent WM_MOUSELEAVE hook exposed through walk's public API, so it's
// tracked separately by polling the cursor position against each button's
// screen rect (see hoverTicker below) rather than deep window-proc
// subclassing.
type texturedButton struct {
	mu         sync.Mutex
	cw         *walk.CustomWidget
	text       string
	textColor  walk.Color
	visualSize walk.Size // the actual drawn/clickable size, enforced in paint() - see visualBounds
	isHover    bool
	isPressed  bool
	onClick    func()
}

var buttonFont *walk.Font

func init() {
	buttonFont, _ = walk.NewFont("Segoe UI", 10, walk.FontBold)
}

// TexturedButton returns a declarative Widget (to place directly in a
// Children slice, same as PushButton) plus the handle used afterward for
// SetText/SetEnabled - mirroring the AssignTo pattern used elsewhere in
// this app for consistency, but returned directly since CustomWidget's own
// AssignTo only yields the raw *walk.CustomWidget, not our wrapper.
func TexturedButton(text string, size Size, enabled bool, onClick func()) (Widget, *texturedButton) {
	tb := &texturedButton{
		text:       text,
		textColor:  themeText,
		visualSize: walk.Size{Width: size.Width, Height: size.Height},
		onClick:    onClick,
	}

	inner := CustomWidget{
		AssignTo:            &tb.cw,
		Enabled:             enabled,
		Background:          themeBrush(), // shows through the plate art's transparent scalloped corners, and behind the visual size below
		Paint:               tb.paint,
		OnMouseDown:         tb.onMouseDown,
		OnMouseUp:           tb.onMouseUp,
		InvalidatesOnResize: true,
	}

	// CustomWidget always reports itself to the layout engine as a
	// "greedy" item (wants to fill all available space) with no way to
	// turn that off, and that flag survives being wrapped in any
	// Composite/Grid/HBox/VBox container regardless of MinSize/MaxSize -
	// walk's own size-clamping logic explicitly skips clamping whenever
	// the growable flag is set (see gridlayout.go's per-cell sizing), so
	// no combination of wrapper/layout here can pin the actual allocated
	// size to `size`. paint()/onMouseUp() self-constrain instead: they
	// only draw/hit-test a `size`-sized rect centered in whatever bounds
	// the layout actually grants, so the button looks and clicks right
	// regardless of how much space its container hands it.
	wrapper := Composite{
		Layout:   VBox{MarginsZero: true, SpacingZero: true},
		MinSize:  size,
		MaxSize:  size,
		Children: []Widget{inner},
	}

	registerHoverTracked(tb)
	return wrapper, tb
}

// visualBounds returns the fixed-size rect this button actually draws
// into and hit-tests against, centered within whatever the layout engine
// granted the underlying widget.
func (tb *texturedButton) visualBounds() walk.Rectangle {
	full := tb.cw.ClientBounds()

	w, h := tb.visualSize.Width, tb.visualSize.Height
	if w <= 0 || w > full.Width {
		w = full.Width
	}
	if h <= 0 || h > full.Height {
		h = full.Height
	}

	return walk.Rectangle{
		X:      full.X + (full.Width-w)/2,
		Y:      full.Y + (full.Height-h)/2,
		Width:  w,
		Height: h,
	}
}

func (tb *texturedButton) SetText(text string) {
	tb.mu.Lock()
	tb.text = text
	tb.mu.Unlock()
	if tb.cw != nil {
		tb.cw.Invalidate()
	}
}

func (tb *texturedButton) SetTextColor(color walk.Color) {
	tb.mu.Lock()
	tb.textColor = color
	tb.mu.Unlock()
	if tb.cw != nil {
		tb.cw.Invalidate()
	}
}

func (tb *texturedButton) SetEnabled(enabled bool) {
	if tb.cw != nil {
		tb.cw.SetEnabled(enabled)
		tb.cw.Invalidate()
	}
}

func (tb *texturedButton) paint(canvas *walk.Canvas, _ walk.Rectangle) error {
	bounds := tb.visualBounds()

	tb.mu.Lock()
	text := tb.text
	color := tb.textColor
	pressed := tb.isPressed
	hover := tb.isHover
	tb.mu.Unlock()

	enabled := tb.cw.Enabled()

	img := buttonNormalImg
	switch {
	case !enabled:
		img = buttonNormalImg
	case pressed:
		img = buttonPressedImg
	case hover:
		img = buttonHoverImg
	}
	if img != nil {
		if err := canvas.DrawImageStretched(img, bounds); err != nil {
			return err
		}
	}

	if !enabled {
		color = walk.RGB(0x8a, 0x82, 0x6c)
	}
	return canvas.DrawText(text, buttonFont, color, bounds, walk.TextCenter|walk.TextVCenter|walk.TextSingleLine|walk.TextNoPrefix)
}

func (tb *texturedButton) onMouseDown(x, y int, button walk.MouseButton) {
	if button != walk.LeftButton || !tb.cw.Enabled() {
		return
	}
	tb.mu.Lock()
	tb.isPressed = true
	tb.mu.Unlock()
	tb.cw.Invalidate()
}

func (tb *texturedButton) onMouseUp(x, y int, button walk.MouseButton) {
	if button != walk.LeftButton {
		return
	}
	tb.mu.Lock()
	wasPressed := tb.isPressed
	tb.isPressed = false
	tb.mu.Unlock()
	tb.cw.Invalidate()

	if wasPressed && tb.cw.Enabled() {
		b := tb.visualBounds()
		if x >= b.X && x < b.X+b.Width && y >= b.Y && y < b.Y+b.Height && tb.onClick != nil {
			tb.onClick()
		}
	}
}

// --- hover tracking (polling; see the texturedButton doc comment) ---

var (
	hoverMu      sync.Mutex
	hoverButtons []*texturedButton
	hoverStarted bool
)

func registerHoverTracked(tb *texturedButton) {
	hoverMu.Lock()
	hoverButtons = append(hoverButtons, tb)
	alreadyRunning := hoverStarted
	hoverStarted = true
	hoverMu.Unlock()

	if !alreadyRunning {
		go hoverTickerLoop()
	}
}

func hoverTickerLoop() {
	for {
		time.Sleep(80 * time.Millisecond)

		var cursor win.POINT
		win.GetCursorPos(&cursor)

		hoverMu.Lock()
		snapshot := append([]*texturedButton(nil), hoverButtons...)
		hoverMu.Unlock()

		for _, tb := range snapshot {
			tb.updateHover(cursor)
		}
	}
}

func (tb *texturedButton) updateHover(cursor win.POINT) {
	if tb.cw == nil || tb.cw.Handle() == 0 {
		return
	}

	var origin win.POINT
	win.ClientToScreen(tb.cw.Handle(), &origin)
	b := tb.cw.ClientBoundsPixels()

	hovered := int32(cursor.X) >= origin.X && int32(cursor.X) < origin.X+int32(b.Width) &&
		int32(cursor.Y) >= origin.Y && int32(cursor.Y) < origin.Y+int32(b.Height)

	tb.mu.Lock()
	changed := hovered != tb.isHover
	tb.isHover = hovered
	if !hovered && tb.isPressed {
		tb.isPressed = false
		changed = true
	}
	tb.mu.Unlock()

	if changed {
		tb.cw.Synchronize(func() {
			tb.cw.Invalidate()
		})
	}
}
