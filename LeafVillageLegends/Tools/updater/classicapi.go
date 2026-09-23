// ClassicAPI is a client-side DLL (not a normal Interface/AddOns addon)
// that LeafVillageAchievements needs for full functionality - see the
// repo's top-level README ("Required: ClassicAPI"). This file checks
// whether it's installed next to the WoW client and offers a one-click
// install/update that mirrors the README's manual steps: drop
// ClassicAPI.dll into the WoW root and make sure dlls.txt references it
// so VanillaFixes loads it.
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const (
	classicAPIReleaseAPIURL = "https://api.github.com/repos/brues-code/ClassicAPI/releases/latest"
	// GitHub's "latest" release alias always resolves to whatever the
	// current release's same-named asset is, so downloading doesn't need
	// the tag_name from the API call above at all - only display/version
	// bookkeeping does.
	classicAPIDownloadURL = "https://github.com/brues-code/ClassicAPI/releases/latest/download/ClassicAPI.dll"
	classicAPIDLLName     = "ClassicAPI.dll"
	dllsTxtName           = "dlls.txt"
)

type classicAPIStatus struct {
	RootValid        bool
	WoWRoot          string
	DLLInstalled     bool
	DLLsTxtOK        bool
	InstalledVersion string // the DLL's own FileVersion when readable, else our recorded install, else ""
	LatestVersion    string // from GitHub; "" if not checked yet
}

// wowRootFromAddonsPath expects the standard Interface/AddOns layout
// (".../Interface/AddOns") and returns the WoW install root two levels
// up. Anything else (a nonstandard AddOns location) is reported invalid
// rather than guessed at, since ClassicAPI.dll and dlls.txt both need to
// sit next to the actual game exe.
func wowRootFromAddonsPath(addonsPath string) (string, bool) {
	if addonsPath == "" {
		return "", false
	}
	interfaceDir := filepath.Dir(addonsPath)
	if !strings.EqualFold(filepath.Base(addonsPath), "AddOns") {
		return "", false
	}
	if !strings.EqualFold(filepath.Base(interfaceDir), "Interface") {
		return "", false
	}
	root := filepath.Dir(interfaceDir)
	if !isValidAddonsDir(root) {
		return "", false
	}
	return root, true
}

// computeClassicAPIStatus checks only local filesystem state - no
// network - so it's cheap enough to call on every config change.
func computeClassicAPIStatus(cfg config) classicAPIStatus {
	var st classicAPIStatus
	root, ok := wowRootFromAddonsPath(cfg.AddonsPath)
	st.RootValid = ok
	if !ok {
		return st
	}
	st.WoWRoot = root
	dllPath := filepath.Join(root, classicAPIDLLName)
	st.DLLInstalled = fileExists(dllPath)
	st.DLLsTxtOK = dllsTxtHasClassicAPI(root)
	if st.DLLInstalled {
		// Prefer the DLL's own embedded version - catches a copy placed
		// there manually or by an older run of this tool, neither of
		// which updater-config.json would know about. Fall back to our
		// own bookkeeping only if the resource can't be read.
		if ver, err := fileVersion(dllPath); err == nil && ver != "" {
			st.InstalledVersion = ver
		} else {
			st.InstalledVersion = cfg.ClassicAPIVersion
		}
	}
	return st
}

// normalizeVersion strips a leading "v" (GitHub tags look like "v1.15.7";
// a DLL's own FileVersion resource never has one) so the two can be
// compared as plain dot-separated numbers via compareVersions.
func normalizeVersion(v string) string {
	return strings.TrimPrefix(v, "v")
}

// dllsTxtHasClassicAPI mirrors VanillaFixes' own parser (src/textfile.c):
// UTF-8 text, one path per line, '#'-prefixed and empty lines skipped,
// each line trimmed and resolved relative to the game directory - so a
// bare "ClassicAPI.dll" line is exactly what the README's manual steps
// produce and is what we check for/write here.
func dllsTxtHasClassicAPI(wowRoot string) bool {
	data, err := os.ReadFile(filepath.Join(wowRoot, dllsTxtName))
	if err != nil {
		return false
	}
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.EqualFold(filepath.Base(line), classicAPIDLLName) {
			return true
		}
	}
	return false
}

func ensureDLLsTxtEntry(wowRoot string) error {
	if dllsTxtHasClassicAPI(wowRoot) {
		return nil
	}

	path := filepath.Join(wowRoot, dllsTxtName)
	data, err := os.ReadFile(path)
	if err != nil && !os.IsNotExist(err) {
		return err
	}

	content := string(data)
	if len(content) > 0 && !strings.HasSuffix(content, "\n") {
		content += "\r\n"
	}
	content += classicAPIDLLName + "\r\n"

	return os.WriteFile(path, []byte(content), 0644)
}

type githubRelease struct {
	TagName string `json:"tag_name"`
}

func fetchLatestClassicAPIVersion() (string, error) {
	req, err := http.NewRequest(http.MethodGet, classicAPIReleaseAPIURL, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "AshenBannerUpdater")
	req.Header.Set("Accept", "application/vnd.github+json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("GitHub API returned %s", resp.Status)
	}

	var rel githubRelease
	if err := json.NewDecoder(resp.Body).Decode(&rel); err != nil {
		return "", err
	}
	if rel.TagName == "" {
		return "", fmt.Errorf("release response had no tag_name")
	}
	return rel.TagName, nil
}

func downloadClassicAPIDLL(destPath string) error {
	client := &http.Client{Timeout: 2 * time.Minute}
	resp, err := client.Get(classicAPIDownloadURL)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected HTTP status %s", resp.Status)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	if len(data) < 1024 {
		return fmt.Errorf("downloaded file is only %d bytes - doesn't look like a real DLL", len(data))
	}

	return os.WriteFile(destPath, data, 0644)
}

// installOrFixClassicAPI performs every manual step from the README's
// "Required: ClassicAPI" section except installing VanillaFixes itself:
// download the current release's ClassicAPI.dll into the WoW root, and
// make sure dlls.txt references it. Returns the installed version tag.
func installOrFixClassicAPI(wowRoot string) (version string, err error) {
	version, err = fetchLatestClassicAPIVersion()
	if err != nil {
		return "", fmt.Errorf("checking latest release: %w", err)
	}
	if err := downloadClassicAPIDLL(filepath.Join(wowRoot, classicAPIDLLName)); err != nil {
		return "", fmt.Errorf("downloading %s: %w", classicAPIDLLName, err)
	}
	if err := ensureDLLsTxtEntry(wowRoot); err != nil {
		return "", fmt.Errorf("updating %s: %w", dllsTxtName, err)
	}
	return version, nil
}
