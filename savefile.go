package playground

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// saveReplacing writes content to a temporary file next to path and renames it
// over path, step by step as pwdmgr's atomicfile does it, and logs each step:
// a sandbox may refuse any of them. An existing file stays intact until the
// rename.
func saveReplacing(path, content string, logf func(string)) error {
	logf(fmt.Sprintf("target before: %s", describeFile(path)))
	perm := os.FileMode(0o600)
	if fi, err := os.Stat(path); err == nil {
		perm = fi.Mode().Perm()
	}
	dir, base := filepath.Split(path)
	tmp, err := os.CreateTemp(dir, "."+base+".tmp-*")
	if err != nil {
		return fmt.Errorf("create the temporary file: %w", err)
	}
	name := tmp.Name()
	done := false
	defer func() {
		if !done {
			_ = tmp.Close()
			_ = os.Remove(name)
		}
	}()
	logf("temporary file: " + name)
	if _, err := tmp.WriteString(content); err != nil {
		return fmt.Errorf("write: %w", err)
	}
	if err := tmp.Sync(); err != nil {
		return fmt.Errorf("sync: %w", err)
	}
	if err := tmp.Close(); err != nil {
		return fmt.Errorf("close: %w", err)
	}
	if err := os.Chmod(name, perm); err != nil {
		return fmt.Errorf("chmod: %w", err)
	}
	logf(fmt.Sprintf("target before the rename: %s", describeFile(path)))
	if err := os.Rename(name, path); err != nil {
		return fmt.Errorf("rename: %w", err)
	}
	done = true
	if d, err := os.Open(dir); err != nil {
		logf(fmt.Sprintf("sync of the folder, best effort: %v", err))
	} else {
		if err := d.Sync(); err != nil {
			logf(fmt.Sprintf("sync of the folder, best effort: %v", err))
		}
		d.Close()
	}
	logf(fmt.Sprintf("target after: %s", describeFile(path)))
	return nil
}

// describeFile is what a log says about a file: its content, or why not.
func describeFile(path string) string {
	b, err := os.ReadFile(path)
	if err != nil {
		return err.Error()
	}
	return fmt.Sprintf("%q", b)
}

// listFolder is what the program can see in the folder of path.
func listFolder(path string) string {
	es, err := os.ReadDir(filepath.Dir(path))
	if err != nil {
		return err.Error()
	}
	names := make([]string, len(es))
	for i, e := range es {
		names[i] = e.Name()
	}
	return strings.Join(names, ", ")
}

// rememberedPathFile keeps the chosen path across restarts, as pwdmgr does.
func rememberedPathFile() (string, error) {
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "gioplayground", "last-save-path"), nil
}

func rememberPath(path string) error {
	f, err := rememberedPathFile()
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(f), 0o700); err != nil {
		return err
	}
	return os.WriteFile(f, []byte(path), 0o600)
}

func rememberedPath() (string, error) {
	f, err := rememberedPathFile()
	if err != nil {
		return "", err
	}
	b, err := os.ReadFile(f)
	return string(b), err
}
