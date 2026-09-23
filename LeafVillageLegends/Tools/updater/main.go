// AshenBannerUpdater is a portable, dependency-free desktop updater for the
// LeafVillageLegends and LeafVillageAchievements WoW addons. It downloads
// the current `main` branch of https://github.com/Tracer1996/Legends as a
// zip archive, compares each addon's .toc Version against what's installed,
// and lets the user update either addon from a small native window.
//
// It is built as a single static Windows executable (see build.sh) using
// github.com/lxn/walk for a real Win32 GUI - no CGO, no browser, no
// console window. No git, no Go, no installer required on the machine it
// runs on.
package main

import (
	"archive/zip"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

const (
	repoZipURL = "https://github.com/Tracer1996/Legends/archive/refs/heads/main.zip"
	zipPrefix  = "Legends-main/"
	configFile = "updater-config.json"
)

// addons lists every addon this tool manages. FolderName must match both
// the top-level folder in the repo and the folder name required under
// Interface/AddOns (the .toc file must share the same name).
var addons = []string{
	"LeafVillageLegends",
	"LeafVillageAchievements",
}

var tocVersionRe = regexp.MustCompile(`(?m)^\s*##\s*Version\s*:\s*(.+?)\s*$`)

type config struct {
	AddonsPath        string `json:"addonsPath"`
	MusicVolume       int    `json:"musicVolume"` // 0-100
	MusicMuted        bool   `json:"musicMuted"`
	ClassicAPIVersion string `json:"classicApiVersion"` // release tag we last successfully installed
}

const defaultMusicVolume = 30

type addonStatus struct {
	Name             string
	InstalledVersion string // "" if not installed
	RemoteVersion    string // "" if not yet checked
	NeedsUpdate      bool
}

func main() {
	runGUI()
}

func exeDirectory() (string, error) {
	exePath, err := os.Executable()
	if err != nil {
		return "", err
	}
	resolved, err := filepath.EvalSymlinks(exePath)
	if err != nil {
		resolved = exePath
	}
	return filepath.Dir(resolved), nil
}

// --- config ---

func configPath(exeDir string) string {
	return filepath.Join(exeDir, configFile)
}

func loadConfig(exeDir string) config {
	// Pre-set the default so it survives untouched if the saved file
	// predates the music fields entirely - json.Unmarshal only overwrites
	// fields whose keys are actually present, it doesn't zero the rest.
	cfg := config{MusicVolume: defaultMusicVolume}
	data, err := os.ReadFile(configPath(exeDir))
	if err != nil {
		return cfg
	}
	json.Unmarshal(data, &cfg)
	if !isValidAddonsDir(cfg.AddonsPath) {
		cfg.AddonsPath = ""
	}
	return cfg
}

func saveConfig(exeDir string, cfg config) error {
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(configPath(exeDir), data, 0644)
}

func isValidAddonsDir(path string) bool {
	if path == "" {
		return false
	}
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

// --- version / zip logic ---

func downloadRepoZip() ([]byte, *zip.Reader, error) {
	client := &http.Client{Timeout: 2 * time.Minute}
	resp, err := client.Get(repoZipURL)
	if err != nil {
		return nil, nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, nil, fmt.Errorf("unexpected HTTP status %s", resp.Status)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, nil, err
	}

	zr, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
	if err != nil {
		return nil, nil, err
	}
	return data, zr, nil
}

func zipReaderFromBytes(data []byte) (*zip.Reader, error) {
	return zip.NewReader(bytes.NewReader(data), int64(len(data)))
}

func buildAddonStatuses(zr *zip.Reader, addonsPath string) []addonStatus {
	statuses := make([]addonStatus, 0, len(addons))
	for _, name := range addons {
		s := addonStatus{Name: name}

		localTocPath := filepath.Join(addonsPath, name, name+".toc")
		if data, err := os.ReadFile(localTocPath); err == nil {
			s.InstalledVersion, _ = parseTocVersion(string(data))
		}

		if zr != nil {
			remoteTocName := zipPrefix + name + "/" + name + ".toc"
			if remoteToc, err := readZipFile(zr, remoteTocName); err == nil {
				s.RemoteVersion, _ = parseTocVersion(remoteToc)
			}
		}

		if s.RemoteVersion != "" {
			s.NeedsUpdate = s.InstalledVersion == "" || compareVersions(s.RemoteVersion, s.InstalledVersion) > 0
		}
		statuses = append(statuses, s)
	}
	return statuses
}

func readZipFile(zr *zip.Reader, name string) (string, error) {
	for _, f := range zr.File {
		if f.Name == name {
			rc, err := f.Open()
			if err != nil {
				return "", err
			}
			defer rc.Close()
			data, err := io.ReadAll(rc)
			if err != nil {
				return "", err
			}
			return string(data), nil
		}
	}
	return "", os.ErrNotExist
}

func parseTocVersion(tocContent string) (string, bool) {
	m := tocVersionRe.FindStringSubmatch(tocContent)
	if m == nil {
		return "", false
	}
	return m[1], true
}

// compareVersions compares two dot-separated numeric version strings
// (e.g. "19.1.0" vs "18.9.3"). Returns >0 if a > b, <0 if a < b, 0 if equal.
// Non-numeric segments compare as 0 rather than failing the whole update.
func compareVersions(a, b string) int {
	as := strings.Split(a, ".")
	bs := strings.Split(b, ".")
	n := len(as)
	if len(bs) > n {
		n = len(bs)
	}
	for i := 0; i < n; i++ {
		var av, bv int
		if i < len(as) {
			av, _ = strconv.Atoi(strings.TrimSpace(as[i]))
		}
		if i < len(bs) {
			bv, _ = strconv.Atoi(strings.TrimSpace(bs[i]))
		}
		if av != bv {
			return av - bv
		}
	}
	return 0
}

// extractAddon replaces localDir with the contents of the zip entries under
// remotePrefix. The existing folder is removed first so files deleted
// upstream don't linger locally.
func extractAddon(zr *zip.Reader, remotePrefix, localDir string) error {
	if err := os.RemoveAll(localDir); err != nil {
		return fmt.Errorf("could not remove old copy: %w", err)
	}
	if err := os.MkdirAll(localDir, 0755); err != nil {
		return err
	}

	found := false
	for _, f := range zr.File {
		if !strings.HasPrefix(f.Name, remotePrefix) {
			continue
		}
		found = true
		rel := strings.TrimPrefix(f.Name, remotePrefix)
		if rel == "" {
			continue
		}
		destPath := filepath.Join(localDir, filepath.FromSlash(rel))

		if f.FileInfo().IsDir() {
			if err := os.MkdirAll(destPath, 0755); err != nil {
				return err
			}
			continue
		}

		if err := os.MkdirAll(filepath.Dir(destPath), 0755); err != nil {
			return err
		}

		if err := extractZipEntry(f, destPath); err != nil {
			return fmt.Errorf("writing %s: %w", rel, err)
		}
	}
	if !found {
		return fmt.Errorf("addon not found in downloaded archive (%s)", remotePrefix)
	}
	return nil
}

func extractZipEntry(f *zip.File, destPath string) error {
	rc, err := f.Open()
	if err != nil {
		return err
	}
	defer rc.Close()

	out, err := os.OpenFile(destPath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, rc)
	return err
}
