# AshenBannerUpdater

A portable, single-file Windows desktop app for updating **LeafVillageLegends**
and **LeafVillageAchievements**. It downloads the current `main` branch of
this repo from GitHub, shows installed vs. latest version for each addon
side by side in a native window, and lets you update either one
individually (or both at once) — no git, no Go, no installer needed on the
guild member's machine. It also checks and can install **ClassicAPI**, the
client-side DLL LeafVillageAchievements needs (see the top-level README's
"Required: ClassicAPI" section).

## For guild members (using it)

1. Grab `AshenBannerUpdater.exe` (ask whoever maintains the repo for a copy —
   it isn't checked into git, see below).
2. Put it anywhere convenient — Desktop, a tools folder, wherever.
3. Double-click it. It opens directly as a window — no console, no browser.
4. First run: enter (or **Browse...** to) the path to your `Interface\AddOns`
   folder, e.g.
   ```
   C:\Games\World of Warcraft\Interface\AddOns
   ```
   and click **Save & Check**. It remembers this in `updater-config.json`,
   saved right next to the exe.
5. Each addon gets its own box showing the installed version, the latest
   version on `main`, and a status (Up to date / Update available / Not
   installed). Click **Update** on either one, or **Update All Out of Date**
   to do both at once.
6. A third box shows **ClassicAPI** status — Installed / Latest (GitHub) /
   Status — and its own button (**Install** / **Update** / **Fix dlls.txt**
   / **Reinstall** depending on what's missing). Clicking it downloads the
   latest `ClassicAPI.dll` from its GitHub releases straight into your WoW
   folder and makes sure `dlls.txt` references it. This only works when
   your AddOns path follows the standard `.../Interface/AddOns` layout
   (needed to find the WoW root two levels up) — otherwise it shows "Can't
   locate WoW folder" and the button stays disabled. It does **not** install
   [VanillaFixes](https://github.com/hannesmann/vanillafixes) itself, which
   ClassicAPI needs to actually load — see the top-level README.
7. There's a looping tavern-ambiance track playing quietly in the
   background (30% volume by default) — drag the slider or tick **Mute** to
   change that; it's remembered for next time.
8. Click **Close** when you're done.
9. Restart WoW (or `/reload` if it's already running).

Run it again any time to check for new updates. If it ever has the wrong
AddOns path saved, click **Browse...** and pick the right one, then
**Save & Check** again.

## For maintainers (building it)

Source is nine Go files:
- `main.go` — config, version comparison, download/extract logic
- `gui.go` — the window itself (built with [github.com/lxn/walk](https://github.com/lxn/walk), a native Win32 GUI binding)
- `button.go` — `texturedButton`, a `CustomWidget`-based button skinned with the addon's own art (see Art below) instead of the stock Win32 button face
- `banner.go` — `titledBanner`, the same `CustomWidget` technique used to draw "The Ashen Banner" as real, crisp system text on top of the header art
- `classicapi.go` / `classicapi_version.go` — checks/installs [ClassicAPI](https://github.com/brues-code/ClassicAPI) (see below)
- `assets.go` — embeds the banner/icon/button PNGs and `assets/tavern.wav` into the binary
- `audio.go` — a minimal `winmm.dll` `waveOut*` binding (WAV parsing + looped playback + per-stream volume/mute)
- `updater.manifest` / `rsrc.syso` — an embedded manifest (modern visual
  styles + DPI awareness) and app icon (`assets/icon.ico`), baked into the
  exe as a Windows resource

To rebuild after changing anything:

- From Linux/macOS: `./build.sh` (cross-compiles to Windows)
- From Windows (with Go installed): `build.bat`

Both need only the Go toolchain (1.21+) — `github.com/lxn/walk` talks to
Win32 directly via `golang.org/x/sys/windows` syscalls, no CGO and no C
cross-compiler required. If you change `updater.manifest` or
`assets/icon.ico`, install [rsrc](https://github.com/akavel/rsrc) once
(`go install github.com/akavel/rsrc@latest`) so the build scripts can
regenerate `rsrc.syso` from them; otherwise the committed `rsrc.syso` is
used as-is.

### Art (`assets/`)

The banner and icon are reskinned from the LeafVillageLegends addon's own
`Textures/` folder, not generic/stock art:
- `assets/banner.png` — from `ashen_header_banner.tga`, tinted gold
  (`#D8A24A`, the addon's own accent color) since the source art is painted
  near-white/grayscale for in-game vertex-color tinting and looks washed out
  shown as-is.
- `assets/icon.png` / `assets/icon.ico` — from `ashen_rank_1.tga` (already
  fully colored in the source file, no tint needed).
- `assets/button_normal.png` / `_hover.png` / `_pressed.png` — from
  `ab_btn.tga`. The addon's own `ab_btn_h.tga`/`ab_btn_d.tga` turned out to
  be byte-identical to `ab_btn.tga` (`md5sum` confirms it) — the addon
  actually reuses one texture for every state and differentiates them at
  runtime via `SetBlendMode("ADD")` on a hover overlay (see
  `ApplyAshenUniversalButtonTexture` in `Core.lua`), not distinct art. The
  three PNGs here reproduce that effect ahead of time via a `-brightness`
  flag on the same conversion tool (`+45` for hover, `-30` for pressed)
  instead of doing an additive blend at paint time.

Both were produced with `assets/gen`, a small one-off conversion tool (its
own Go module, since it pulls in `golang.org/x/image` for resizing — kept
out of the main updater's dependencies) that decodes the addon's
uncompressed-truecolor `.tga` files, optionally tints and resizes them, and
writes `.png`/`.ico`. To swap in a different texture or retint:

```
cd assets/gen
go run . -in ../../../../Textures/<file>.tga -out ../banner.png -w 480 -tint D8A24A
go run . -in ../../../../Textures/<file>.tga -out ../icon.png  -w 128
go run . -in ../../../../Textures/<file>.tga -out ../icon.ico -ico -sizes 16,32,48,64,128
```

It only supports the specific TGA variant (uncompressed truecolor, 24/32bpp)
that this addon's textures use — that's every file in `Textures/` as of
this writing, but not a general-purpose TGA decoder.

- `assets/tavern.wav` — from the addon's `Sounds/magic_tavern.wav`, trimmed
  to 60s and downsampled to mono/22050Hz. The original is 68MB of
  uncompressed 44.1kHz stereo (6.5 minutes) — embedding that whole thing
  would have made this exe ~78MB for a background loop, so it's cut down
  with a short fade in/out at the trim point so the loop doesn't click:

  ```
  ffmpeg -i LeafVillageLegends/Sounds/magic_tavern.wav -t 60 -ac 1 -ar 22050 -sample_fmt s16 \
    -af "afade=t=in:st=0:d=0.3,afade=t=out:st=59.5:d=0.5" \
    LeafVillageLegends/Tools/updater/assets/tavern.wav
  ```

### Background music (`audio.go`)

The tavern loop plays via a small hand-written `winmm.dll` `waveOut*`
binding rather than the simpler `PlaySound` API, specifically so the volume
slider/mute checkbox can control *this app's* stream without touching
system-wide or other-app volume: `waveOutOpen` gets its own device handle,
and `waveOutSetVolume` is scoped to that handle. Looping is manual (winmm
has no infinite-loop flag that's reliably honored by real devices) — a
`CALLBACK_EVENT` fires when the one prepared buffer finishes, and the
handler just resubmits the same buffer. Volume/mute are saved to
`updater-config.json` alongside the AddOns path.

The build passes `-H=windowsgui` so the compiled exe has no console window.
`AshenBannerUpdater.exe` itself is gitignored — this repo isn't meant to
carry compiled binaries in history. Rebuild and hand out the `.exe` directly
(Discord, a shared drive, wherever the guild already shares files) whenever
you cut a new addon version worth pushing to everyone.

### Why `lxn/walk` instead of \[toolkit x\]

This was built from a Linux sandbox with no Windows-targeting C
cross-compiler available, which rules out most Go GUI toolkits (Fyne, Gio,
webview) — they render via OpenGL/ANGLE/WebView2 and need CGO to bind to
those on Windows. `lxn/walk` instead wraps native Win32 common controls
directly through `golang.org/x/sys/windows` syscalls, so it cross-compiles
to a real native window with zero CGO and zero runtime dependencies beyond
what Windows itself ships. The tradeoff is that `walk` is old and
lightly-maintained (last real release 2021) and only does Win32 — fine here
since the target is Windows-only anyway.

This is built and cross-compiled from Linux (no Windows box or Wine in the
build environment), verified with `go vet`/a clean build and manual tracing
of the logic, then confirmed working from real screenshots on an actual
Windows machine as the UI evolved.

## How it decides what to update

For each addon, it compares the `## Version:` line in the downloaded copy's
`.toc` against the installed copy's `.toc`:

- Not installed locally → shown as "Not installed", button reads "Install".
- Downloaded version is numerically newer → shown as "Update available".
- Otherwise → shown as "Up to date" (button reads "Reinstall" — clicking it
  still force-reinstalls from `main` if you want to be sure).

## ClassicAPI (`classicapi.go`)

ClassicAPI isn't in this repo or on `main` — it's a separate GitHub project
(`brues-code/ClassicAPI`) distributing a compiled `.dll`, so this works
differently from the two addons above:

- **Finding the WoW root.** ClassicAPI.dll and `dlls.txt` both live next to
  the game exe, not in `Interface/AddOns`. `wowRootFromAddonsPath` requires
  the AddOns path to end in exactly `.../Interface/AddOns` and walks up two
  levels; anything else (a symlinked or nonstandard layout) is reported as
  "can't locate WoW folder" rather than guessed at, since writing
  `dlls.txt` to the wrong place would be silently useless at best.
- **Version check.** `GET api.github.com/repos/brues-code/ClassicAPI/releases/latest`
  for the current tag (needs a `User-Agent` header or GitHub's API rejects
  the request). The installed version comes straight from the DLL's own
  embedded `VS_VERSIONINFO` resource (`classicapi_version.go`, via
  `version.dll`'s `GetFileVersionInfoW`/`VerQueryValueW` — the same value
  Explorer's Properties → Details tab shows), so a copy placed there
  manually or by an older run of this tool is detected correctly without
  needing our own install to have recorded it first. That resource reports
  four dot-separated numbers (`1.15.7.0`) rather than GitHub's `v1.15.7`
  tag, so both get their `v` stripped and are compared as plain numbers
  (`compareVersions`, the same logic the two addon panels use) rather than
  a naive string comparison that would treat matching versions as
  different forever. Only if the resource can't be read at all (rare —
  every real release build has had one so far) does it fall back to
  whatever version this tool itself last installed
  (`updater-config.json`), or "installed (version unknown)" if that's
  empty too.
- **Download.** GitHub's `.../releases/latest/download/ClassicAPI.dll` URL
  always redirects to the current release's asset of that name, so
  fetching it doesn't need the tag from the API call at all — only the
  displayed version and `updater-config.json` bookkeeping do.
- **`dlls.txt`.** Parsed the same way VanillaFixes itself does (confirmed
  against its source, `src/textfile.c`/`loader.c`): plain UTF-8, one path
  per line, blank lines and `#` comments skipped, each line trimmed. A
  bare `ClassicAPI.dll` line — what gets appended if missing — resolves
  fine since VanillaFixes normalizes relative entries against the game
  directory. Existing lines are never touched, only appended to.

This does **not** install [VanillaFixes](https://github.com/hannesmann/vanillafixes)
itself (the launcher that actually reads `dlls.txt` and loads ClassicAPI) —
that's still a manual one-time step per the top-level README.

Versions are compared as dot-separated numbers (`19.1.0` vs `18.9.3`), so
version strings in the `.toc` files need to stay in that plain `x.y.z` form
for the comparison to work.
