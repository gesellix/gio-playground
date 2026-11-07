package playground

import (
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"sync/atomic"
	"time"

	"gioui.org/app"
	"gioui.org/op"
)

// The diag build can be driven without touching the phone, for
// scripts/ios-background-test.sh: URLs set its switches and open a second view,
// and everything it sees also goes to a file that devicectl can copy.

// logFile is Documents/playground.log in the diag build, new for each start of
// the process. PLAYGROUND_LOG asks for it in every build (see Run).
var logFile atomic.Pointer[os.File]

// openLogFile creates the log file at path, or at Documents/playground.log in
// the home directory (on iOS and Android the app's) when path is empty. It
// does nothing if a log file is already open.
func openLogFile(path string) {
	if logFile.Load() != nil {
		return
	}
	if path == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			events.add("no log file: " + err.Error())
			return
		}
		path = filepath.Join(home, "Documents", "playground.log")
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		events.add("no log file: " + err.Error())
		return
	}
	f, err := os.Create(path)
	if err != nil {
		events.add("no log file: " + err.Error())
		return
	}
	logFile.Store(f)
}

func writeLogFile(now time.Time, s string) {
	if f := logFile.Load(); f != nil {
		fmt.Fprintf(f, "%s %s\n", now.Format("15:04:05.000"), s)
	}
}

// detail records what is too frequent for the event log: frames and the driver's
// trace.
func detail(s string) {
	now := time.Now()
	returns.add(now, s)
	writeLogFile(now, s)
}

// diagCommand runs a URL like gioplayground://diag?invalidate=on.
func (f Features) diagCommand(q url.Values) {
	events.add("diag command: " + q.Encode())
	if v := q.Get("background-draw"); v != "" && f.BackgroundDraw != nil {
		backgroundDrawOn.Store(v == "on")
		f.BackgroundDraw(v == "on")
	}
	if v := q.Get("invalidate"); v != "" {
		invalidateSync.Store(v == "on")
	}
	if q.Get("second-view") == "open" {
		openSecondView()
	}
	if q.Get("second-view") == "close" {
		closeSecondView()
	}
	if q.Get("disconnect") == "scene" {
		disconnectScene()
	}
}

// openSecondView shows another Gio view with a window of its own, as a program
// that embeds Gio can have them.
func openSecondView() {
	go func() {
		w := new(app.Window)
		var ops op.Ops
		for {
			switch e := w.Event().(type) {
			case app.DestroyEvent:
				events.add(fmt.Sprintf("second view: DestroyEvent err=%v", e.Err))
				return
			case app.FrameEvent:
				detail(fmt.Sprintf("second view: FrameEvent size=%dx%d", e.Size.X, e.Size.Y))
				gtx := app.NewContext(&ops, e)
				e.Frame(gtx.Ops)
			}
		}
	}()
	presentSecondView()
}
