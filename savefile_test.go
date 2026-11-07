package playground

import (
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

func TestSaveReplacingNewFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "a.txt")
	if err := saveReplacing(path, "new", func(string) {}); err != nil {
		t.Fatal(err)
	}
	if got := describeFile(path); got != `"new"` {
		t.Errorf("content %s", got)
	}
	if got := listFolder(path); got != "a.txt" {
		t.Errorf("folder %q, the temporary file should be gone", got)
	}
}

func TestSaveReplacingKeepsTheOldFileUntilTheRename(t *testing.T) {
	path := filepath.Join(t.TempDir(), "a.txt")
	if err := os.WriteFile(path, []byte("old"), 0o640); err != nil {
		t.Fatal(err)
	}
	// The mode as this system has it: Windows has no Unix permissions and
	// reports 0666 for any file that can be written.
	old, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	var log []string
	if err := saveReplacing(path, "new", func(s string) { log = append(log, s) }); err != nil {
		t.Fatal(err)
	}
	if !slices.Contains(log, `target before the rename: "old"`) {
		t.Errorf("log %q", log)
	}
	if got := describeFile(path); got != `"new"` {
		t.Errorf("content %s", got)
	}
	fi, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if fi.Mode().Perm() != old.Mode().Perm() {
		t.Errorf("mode %o, the old file's (%o) should stay", fi.Mode().Perm(), old.Mode().Perm())
	}
}

func TestSaveReplacingLeavesNothingWhenItFails(t *testing.T) {
	err := saveReplacing(filepath.Join(t.TempDir(), "missing", "a.txt"), "new", func(string) {})
	if err == nil || !strings.Contains(err.Error(), "create the temporary file") {
		t.Errorf("err = %v", err)
	}
}

func TestRememberedPath(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(home, "config"))
	t.Setenv("AppData", filepath.Join(home, "AppData"))
	if err := rememberPath("/some/where.txt"); err != nil {
		t.Fatal(err)
	}
	got, err := rememberedPath()
	if err != nil || got != "/some/where.txt" {
		t.Errorf("got %q, %v", got, err)
	}
}
