package main

import (
	"archive/zip"
	"fmt"
	"path/filepath"

	"github.com/lxn/walk"
	. "github.com/lxn/walk/declarative"
)

// Theme colors, matching the addon's own gold-on-dark-parchment palette
// (see LeafVillageLegends/Core THEME.gold / the chat-text gold codes)
// instead of the stock Win32 light-gray form.
var (
	themeBG    = walk.RGB(0x16, 0x14, 0x0f) // dark background
	themeText  = walk.RGB(0xE8, 0xE2, 0xD0) // cream body text
	themeGold  = walk.RGB(0xD8, 0xA2, 0x4A) // gold accent / headings
	themeGreen = walk.RGB(0x7F, 0xAE, 0x5C) // up to date
	themeRed   = walk.RGB(0xD9, 0x63, 0x5A) // not installed / missing
)

func themeBrush() Brush { return SolidColorBrush{Color: themeBG} }

// infoFont is used for the Installed/Latest/Status rows - bigger and
// bolder than the Win32 default so that information reads clearly against
// the dark background instead of disappearing.
var infoFont = Font{PointSize: 10, Bold: true}

// addonPanel holds the widgets for one addon's GroupBox so handlers can
// update them after a check or update completes.
type addonPanel struct {
	name         string
	installedLbl *walk.Label
	remoteLbl    *walk.Label
	statusLbl    *walk.Label
	updateBtn    *texturedButton
}

type appState struct {
	exeDir string
	cfg    config

	zipData      []byte        // cached download, so Update doesn't always re-fetch
	lastStatuses []addonStatus // last known status per addon, used to restore button state after an op

	mw           *walk.MainWindow
	pathEdit     *walk.LineEdit
	checkBtn     *texturedButton
	updateAllBtn *texturedButton
	statusLbl    *walk.Label
	panels       []*addonPanel

	music        *player
	muteCheck    *walk.CheckBox
	volumeSlider *walk.Slider
	volumeLbl    *walk.Label

	classicAPISt           classicAPIStatus
	classicAPIInstalledLbl *walk.Label
	classicAPILatestLbl    *walk.Label
	classicAPIStatusLbl    *walk.Label
	classicAPIBtn          *texturedButton
}

func runGUI() {
	exeDir, err := exeDirectory()
	if err != nil {
		walk.MsgBox(nil, "AshenBannerUpdater", "Could not determine where this program lives:\n"+err.Error(), walk.MsgBoxIconError)
		return
	}

	a := &appState{
		exeDir: exeDir,
		cfg:    loadConfig(exeDir),
	}

	panelWidgets, panels := a.buildAddonPanels()
	a.panels = panels

	var children []Widget
	if banner, err := loadBannerBitmap(); err == nil {
		bs := banner.Size()
		bannerHeight := 480 * bs.Height / bs.Width // matches the window's content width
		children = append(children, TitledBanner(banner, "The Ashen Banner", Size{Width: 480, Height: bannerHeight}))
	}
	browseBtn, _ := TexturedButton("Browse...", Size{Width: 90, Height: 30}, true, a.onBrowse)
	saveBtn, _ := TexturedButton("Save & Check", Size{Width: 120, Height: 30}, true, a.onSaveAndCheck)
	children = append(children, Composite{
		Layout:     HBox{},
		Background: themeBrush(),
		Children: []Widget{
			Label{Text: "AddOns folder:", TextColor: themeText},
			LineEdit{AssignTo: &a.pathEdit, Text: a.cfg.AddonsPath},
			browseBtn,
			saveBtn,
		},
	})
	children = append(children, panelWidgets...)
	children = append(children, a.buildClassicAPIPanel())
	children = append(children, Composite{
		Layout:     HBox{},
		Background: themeBrush(),
		Children: []Widget{
			Label{Text: "Tavern Music:", TextColor: themeText},
			CheckBox{AssignTo: &a.muteCheck, Checked: !a.cfg.MusicMuted, OnCheckedChanged: a.onPlayingChanged},
			Slider{AssignTo: &a.volumeSlider, MinValue: 0, MaxValue: 100, Value: a.cfg.MusicVolume, OnValueChanged: a.onVolumeChanged},
			Label{AssignTo: &a.volumeLbl, Text: fmt.Sprintf("%d%%", a.cfg.MusicVolume), TextColor: themeText, MinSize: Size{Width: 36}},
		},
	})
	var checkBtnWidget, updateAllWidget, closeWidget Widget
	checkBtnWidget, a.checkBtn = TexturedButton("Check for Updates", Size{Width: 150, Height: 30}, true, a.onCheck)
	updateAllWidget, a.updateAllBtn = TexturedButton("Update All Out of Date", Size{Width: 180, Height: 30}, false, a.onUpdateAll)
	closeWidget, _ = TexturedButton("Close", Size{Width: 90, Height: 30}, true, func() { a.mw.Close() })
	children = append(children, Composite{
		Layout:     HBox{},
		Background: themeBrush(),
		Children: []Widget{
			checkBtnWidget,
			updateAllWidget,
			HSpacer{},
			closeWidget,
		},
	})
	children = append(children, Label{AssignTo: &a.statusLbl, Text: a.initialStatusText(), TextColor: themeGold})

	icon, _ := loadAppIcon() // nil is fine; walk falls back to a default icon

	err = MainWindow{
		AssignTo:   &a.mw,
		Title:      "The Ashen Banner - Addon Updater",
		Icon:       icon,
		Background: themeBrush(),
		Size:       Size{Width: 520, Height: 520},
		Layout:     VBox{},
		Children:   children,
	}.Create()
	if err != nil {
		walk.MsgBox(nil, "AshenBannerUpdater", "Could not create window:\n"+err.Error(), walk.MsgBoxIconError)
		return
	}

	// Reflect installed versions immediately (no network needed for that
	// half), then kick off a background check if we already have a saved
	// path so the window never sits there with stale "-" placeholders.
	a.applyStatuses(buildAddonStatuses(nil, a.cfg.AddonsPath))
	a.classicAPISt = computeClassicAPIStatus(a.cfg)
	a.applyClassicAPIStatus()
	if isValidAddonsDir(a.cfg.AddonsPath) {
		go a.check()
	}

	a.startMusic()

	a.mw.Run()

	if a.music != nil {
		a.music.Stop()
	}
}

// startMusic loads and loops the embedded tavern ambiance at the saved
// volume/mute. Any failure (no audio device, e.g. on a VM) just disables
// the controls instead of blocking the rest of the app.
func (a *appState) startMusic() {
	music, err := newPlayer(tavernWAVData)
	if err != nil {
		a.muteCheck.SetEnabled(false)
		a.volumeSlider.SetEnabled(false)
		return
	}
	music.SetVolume(float64(a.cfg.MusicVolume) / 100)
	music.SetMuted(a.cfg.MusicMuted)
	if err := music.Start(); err != nil {
		a.muteCheck.SetEnabled(false)
		a.volumeSlider.SetEnabled(false)
		return
	}
	a.music = music
}

// onPlayingChanged handles the "Tavern Music" checkbox: checked = playing,
// unchecked = stopped/muted (the checkbox reflects playback state, not a
// "mute" toggle, so its default-checked state means music starts on open).
func (a *appState) onPlayingChanged() {
	playing := a.muteCheck.Checked()
	a.cfg.MusicMuted = !playing
	if a.music != nil {
		a.music.SetMuted(!playing)
	}
	saveConfig(a.exeDir, a.cfg)
}

func (a *appState) onVolumeChanged() {
	v := a.volumeSlider.Value()
	a.cfg.MusicVolume = v
	a.volumeLbl.SetText(fmt.Sprintf("%d%%", v))
	if a.music != nil {
		a.music.SetVolume(float64(v) / 100)
	}
	saveConfig(a.exeDir, a.cfg)
}

func (a *appState) initialStatusText() string {
	if isValidAddonsDir(a.cfg.AddonsPath) {
		return "Checking for updates..."
	}
	return "Enter your Interface\\AddOns folder path above and click \"Save & Check\"."
}

func (a *appState) buildAddonPanels() ([]Widget, []*addonPanel) {
	var widgets []Widget
	var panels []*addonPanel

	for _, name := range addons {
		p := &addonPanel{name: name}
		panels = append(panels, p)

		updateWidget, updateBtn := TexturedButton("Update", Size{Width: 120, Height: 30}, false, func() { go a.updateOne(p) })
		p.updateBtn = updateBtn

		// Win32 GroupBox titles are drawn by the system theme in its own
		// (dark-on-light) text color, unreadable against our dark
		// background with no override available - so instead of a native
		// GroupBox, this fakes one: a slim gold Composite (the "border")
		// wrapping a dark inner Composite, with our own colored title
		// label up top.
		widgets = append(widgets, Composite{
			Layout:     VBox{Margins: Margins{Left: 2, Top: 2, Right: 2, Bottom: 2}, SpacingZero: true},
			Background: SolidColorBrush{Color: themeGold},
			Children: []Widget{
				Composite{
					Layout:     VBox{Margins: Margins{Left: 10, Top: 8, Right: 10, Bottom: 10}},
					Background: themeBrush(),
					Children: []Widget{
						Label{Text: name, TextColor: themeGold, Font: Font{Bold: true, PointSize: 11}},
						Composite{
							// A 3rd column (empty except on the middle row)
							// puts the button beside "Latest (main):"
							// without it inheriting CustomWidget's
							// "greedy" full-row-height sizing - Grid sizes
							// each row from its own actual content instead
							// of the flag-driven fill-available-space
							// scheme HBox/VBox use.
							Layout:     Grid{Columns: 3},
							Background: themeBrush(),
							Children: []Widget{
								Label{Text: "Installed:", TextColor: themeText, Font: infoFont},
								Label{AssignTo: &p.installedLbl, Text: "-", TextColor: themeText, Font: infoFont},
								Label{},
								Label{Text: "Latest (main):", TextColor: themeText, Font: infoFont},
								Label{AssignTo: &p.remoteLbl, Text: "-", TextColor: themeText, Font: infoFont},
								updateWidget,
								Label{Text: "Status:", TextColor: themeText, Font: infoFont},
								Label{AssignTo: &p.statusLbl, Text: "Not checked", TextColor: themeText, Font: infoFont},
								Label{},
							},
						},
					},
				},
			},
		})
	}
	return widgets, panels
}

// buildClassicAPIPanel mirrors buildAddonPanels' gold-bordered card, since
// ClassicAPI is a required companion for LeafVillageAchievements even
// though it isn't an addon itself (a client DLL loaded by VanillaFixes -
// see the repo README's "Required: ClassicAPI" section).
func (a *appState) buildClassicAPIPanel() Widget {
	updateWidget, btn := TexturedButton("Install", Size{Width: 120, Height: 30}, false, a.onFixClassicAPI)
	a.classicAPIBtn = btn

	return Composite{
		Layout:     VBox{Margins: Margins{Left: 2, Top: 2, Right: 2, Bottom: 2}, SpacingZero: true},
		Background: SolidColorBrush{Color: themeGold},
		Children: []Widget{
			Composite{
				Layout:     VBox{Margins: Margins{Left: 10, Top: 8, Right: 10, Bottom: 10}},
				Background: themeBrush(),
				Children: []Widget{
					Label{Text: "ClassicAPI", TextColor: themeGold, Font: Font{Bold: true, PointSize: 11}},
					Composite{
						Layout:     Grid{Columns: 3},
						Background: themeBrush(),
						Children: []Widget{
							Label{Text: "Installed:", TextColor: themeText, Font: infoFont},
							Label{AssignTo: &a.classicAPIInstalledLbl, Text: "-", TextColor: themeText, Font: infoFont},
							Label{},
							Label{Text: "Latest (GitHub):", TextColor: themeText, Font: infoFont},
							Label{AssignTo: &a.classicAPILatestLbl, Text: "-", TextColor: themeText, Font: infoFont},
							updateWidget,
							Label{Text: "Status:", TextColor: themeText, Font: infoFont},
							Label{AssignTo: &a.classicAPIStatusLbl, Text: "Not checked", TextColor: themeText, Font: infoFont},
							Label{},
						},
					},
				},
			},
		},
	}
}

// --- state application (always marshals onto the UI thread) ---

// applyStatuses stores statuses as the new source of truth and repaints
// every widget that depends on it: per-addon labels/buttons and the
// "Update All" button. Safe to call from any goroutine.
func (a *appState) applyStatuses(statuses []addonStatus) {
	a.lastStatuses = statuses

	byName := map[string]addonStatus{}
	for _, s := range statuses {
		byName[s.Name] = s
	}

	a.mw.Synchronize(func() {
		anyOutdated := false
		for _, p := range a.panels {
			s := byName[p.name]

			installed := s.InstalledVersion
			if installed == "" {
				installed = "(not installed)"
			}
			p.installedLbl.SetText(installed)

			remote := s.RemoteVersion
			if remote == "" {
				remote = "(not checked)"
			}
			p.remoteLbl.SetText(remote)

			switch {
			case s.RemoteVersion == "":
				p.statusLbl.SetText("Not checked")
				p.statusLbl.SetTextColor(themeText)
				p.updateBtn.SetText("Update")
			case s.InstalledVersion == "":
				p.statusLbl.SetText("Not installed")
				p.statusLbl.SetTextColor(themeRed)
				p.updateBtn.SetText("Install")
				anyOutdated = true
			case s.NeedsUpdate:
				p.statusLbl.SetText("Update available")
				p.statusLbl.SetTextColor(themeGold)
				p.updateBtn.SetText("Update")
				anyOutdated = true
			default:
				p.statusLbl.SetText("Up to date")
				p.statusLbl.SetTextColor(themeGreen)
				p.updateBtn.SetText("Reinstall")
			}
			p.updateBtn.SetEnabled(s.RemoteVersion != "")
		}
		a.updateAllBtn.SetEnabled(anyOutdated)
	})
}

// applyClassicAPIStatus repaints the ClassicAPI panel from a.classicAPISt.
// Safe to call from any goroutine.
func (a *appState) applyClassicAPIStatus() {
	st := a.classicAPISt

	a.mw.Synchronize(func() {
		if !st.RootValid {
			a.classicAPIInstalledLbl.SetText("-")
			a.classicAPILatestLbl.SetText("-")
			a.classicAPIStatusLbl.SetText("Can't locate WoW folder")
			a.classicAPIStatusLbl.SetTextColor(themeText)
			a.classicAPIBtn.SetEnabled(false)
			return
		}

		installed := st.InstalledVersion
		switch {
		case installed != "":
			// use as-is
		case st.DLLInstalled:
			installed = "installed (version unknown)"
		default:
			installed = "(not installed)"
		}
		a.classicAPIInstalledLbl.SetText(installed)

		latest := st.LatestVersion
		if latest == "" {
			latest = "(not checked)"
		}
		a.classicAPILatestLbl.SetText(latest)

		switch {
		case st.LatestVersion == "":
			a.classicAPIStatusLbl.SetText("Not checked")
			a.classicAPIStatusLbl.SetTextColor(themeText)
			if st.DLLInstalled {
				a.classicAPIBtn.SetText("Update")
			} else {
				a.classicAPIBtn.SetText("Install")
			}
		case !st.DLLInstalled:
			a.classicAPIStatusLbl.SetText("Not installed")
			a.classicAPIStatusLbl.SetTextColor(themeRed)
			a.classicAPIBtn.SetText("Install")
		case st.InstalledVersion != "" &&
			compareVersions(normalizeVersion(st.LatestVersion), normalizeVersion(st.InstalledVersion)) > 0:
			a.classicAPIStatusLbl.SetText("Update available")
			a.classicAPIStatusLbl.SetTextColor(themeGold)
			a.classicAPIBtn.SetText("Update")
		case !st.DLLsTxtOK:
			a.classicAPIStatusLbl.SetText("dlls.txt not configured")
			a.classicAPIStatusLbl.SetTextColor(themeGold)
			a.classicAPIBtn.SetText("Fix dlls.txt")
		default:
			a.classicAPIStatusLbl.SetText("Up to date")
			a.classicAPIStatusLbl.SetTextColor(themeGreen)
			a.classicAPIBtn.SetText("Reinstall")
		}
		a.classicAPIBtn.SetEnabled(true)
	})
}

// setBusy disables all action buttons while an operation is in flight, and
// restores their correct enabled state (from lastStatuses) once it's done -
// covering both the success path (caller already called applyStatuses with
// fresh data before this) and the failure path (nothing changed, so the
// last known statuses are still accurate).
func (a *appState) setBusy(busy bool, statusText string) {
	a.mw.Synchronize(func() {
		a.checkBtn.SetEnabled(!busy)
		if statusText != "" {
			a.statusLbl.SetText(statusText)
		}
	})
	if busy {
		a.mw.Synchronize(func() {
			a.updateAllBtn.SetEnabled(false)
			a.classicAPIBtn.SetEnabled(false)
			for _, p := range a.panels {
				p.updateBtn.SetEnabled(false)
			}
		})
	} else {
		a.applyStatuses(a.lastStatuses)
		a.applyClassicAPIStatus()
	}
}

// --- event handlers ---

func (a *appState) onBrowse() {
	dlg := new(walk.FileDialog)
	dlg.Title = "Select your Interface\\AddOns folder"
	if ok, err := dlg.ShowBrowseFolder(a.mw); err == nil && ok {
		a.pathEdit.SetText(dlg.FilePath)
	}
}

func (a *appState) onSaveAndCheck() {
	path := a.pathEdit.Text()
	if !isValidAddonsDir(path) {
		walk.MsgBox(a.mw, "AshenBannerUpdater", "That folder doesn't exist:\n"+path, walk.MsgBoxIconWarning)
		return
	}
	a.cfg.AddonsPath = path
	if err := saveConfig(a.exeDir, a.cfg); err != nil {
		walk.MsgBox(a.mw, "AshenBannerUpdater", "Could not save config:\n"+err.Error(), walk.MsgBoxIconError)
		return
	}
	a.applyStatuses(buildAddonStatuses(nil, a.cfg.AddonsPath))
	a.classicAPISt = computeClassicAPIStatus(a.cfg)
	a.applyClassicAPIStatus()
	go a.check()
}

func (a *appState) onCheck() {
	go a.check()
}

func (a *appState) check() {
	if !isValidAddonsDir(a.cfg.AddonsPath) {
		a.setBusy(false, "Enter your Interface\\AddOns folder path above and click \"Save & Check\".")
		return
	}

	a.setBusy(true, "Downloading main branch from GitHub...")

	data, zr, err := downloadRepoZip()
	if err != nil {
		a.setBusy(false, "Download failed: "+err.Error())
		return
	}
	a.zipData = data

	a.applyStatuses(buildAddonStatuses(zr, a.cfg.AddonsPath))
	a.refreshClassicAPI()
	a.setBusy(false, "Checked just now.")
}

// refreshClassicAPI recomputes local file status and (if the WoW root is
// known) fetches the latest release tag from GitHub. A failed GitHub
// fetch just leaves LatestVersion at whatever it was before - the local
// status still applies.
func (a *appState) refreshClassicAPI() {
	st := computeClassicAPIStatus(a.cfg)
	if st.RootValid {
		st.LatestVersion = a.classicAPISt.LatestVersion
		if latest, err := fetchLatestClassicAPIVersion(); err == nil {
			st.LatestVersion = latest
		}
	}
	a.classicAPISt = st
	a.applyClassicAPIStatus()
}

func (a *appState) onFixClassicAPI() {
	go a.fixClassicAPI()
}

func (a *appState) fixClassicAPI() {
	if !a.classicAPISt.RootValid {
		return
	}
	a.setBusy(true, "Installing ClassicAPI...")

	version, err := installOrFixClassicAPI(a.classicAPISt.WoWRoot)
	if err != nil {
		a.setBusy(false, "ClassicAPI install failed: "+err.Error())
		return
	}

	a.cfg.ClassicAPIVersion = version
	saveConfig(a.exeDir, a.cfg)
	a.refreshClassicAPI()
	a.setBusy(false, "ClassicAPI "+version+" installed.")
}

func (a *appState) onUpdateAll() {
	go a.updateAll()
}

func (a *appState) updateAll() {
	for _, s := range a.lastStatuses {
		if !s.NeedsUpdate {
			continue
		}
		for _, p := range a.panels {
			if p.name == s.Name {
				a.performUpdate(p)
			}
		}
	}
	a.setBusy(false, "All done.")
}

func (a *appState) updateOne(p *addonPanel) {
	a.performUpdate(p)
	a.setBusy(false, p.name+" updated.")
}

func (a *appState) performUpdate(p *addonPanel) {
	a.setBusy(true, "Updating "+p.name+"...")

	zr, err := a.ensureZip()
	if err != nil {
		a.setBusy(false, "Download failed: "+err.Error())
		return
	}

	remotePrefix := zipPrefix + p.name + "/"
	localDir := filepath.Join(a.cfg.AddonsPath, p.name)
	if err := extractAddon(zr, remotePrefix, localDir); err != nil {
		a.setBusy(false, fmt.Sprintf("Update failed for %s: %v", p.name, err))
		return
	}

	a.applyStatuses(buildAddonStatuses(zr, a.cfg.AddonsPath))
}

func (a *appState) ensureZip() (*zip.Reader, error) {
	if a.zipData != nil {
		return zipReaderFromBytes(a.zipData)
	}
	data, zr, err := downloadRepoZip()
	if err != nil {
		return nil, err
	}
	a.zipData = data
	return zr, nil
}
