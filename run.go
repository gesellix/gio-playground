// Package playground is a small Gio program to try out patches to Gio,
// gio-x and gogio on a device. Each page exercises one patch, and an event
// log that all pages share records what the program receives, so a test can
// be shown (or copied) afterwards.
//
// The program itself is in the modules fork (with the patches) and
// upstream (as it is, with the patches upstream applied). This package
// builds against upstream Gio and gio-x; each module passes the APIs of the
// patches it has as Features.
package playground

import (
	"image/color"
	"io"
	"log"
	"os"
	"strings"
	"sync/atomic"

	"gioui.org/app"
	"gioui.org/io/clipboard"
	"gioui.org/io/event"
	"gioui.org/widget"
	"gioui.org/x/explorer"
)

// Features are the calls of the APIs that the patches add. A nil field is
// an API this build doesn't have; its page says so.
type Features struct {
	// Name names the build in the menu and the log, such as "fork".
	Name string
	// MarkSensitive sets clipboard.WriteCmd.Sensitive.
	MarkSensitive func(*clipboard.WriteCmd)
	// Suspend reports whether e is an app.SuspendEvent (suspended) or an
	// app.ResumeEvent (not suspended).
	Suspend func(e event.Event) (suspended, ok bool)
	// DecorationColors returns the app.DecorationColors option.
	DecorationColors func(bg, fg color.NRGBA) app.Option
	// Wipe calls widget.Editor.Wipe.
	Wipe func(*widget.Editor)
	// SaveFilePath calls explorer.Explorer.SaveFilePath.
	SaveFilePath func(x *explorer.Explorer, name string) (string, error)
}

// The scripts set these with -ldflags "-X ...".
var (
	// buildFlags lists the gogio flags of the build.
	buildFlags = "none"
	// urlScheme is the URL scheme the build registers (gogio -schemes).
	urlScheme = "gioplayground"
)

// Run runs the program; it must be called from main and never returns.
func Run(f Features) {
	events.add("process started (Gio: " + f.Name + ", gogio flags: " + buildFlags + ")")
	if !registersScheme() {
		events.add("no URL scheme registered: started without an app bundle (go run), see the page URLs and iOS scenes")
	}
	initPlatform()
	go func() {
		w := new(app.Window)
		w.Option(app.Title("Gio playground"))
		if err := newUI(w, f).run(); err != nil {
			log.Fatal(err)
		}
		os.Exit(0)
	}()
	// app.Events instead of app.Main: it also yields the events that belong
	// to no window, such as the URLs that open the program.
	// It also yields the suspension (Android, iOS), before the platform's
	// callback returns.
	app.Events(func(e event.Event) bool {
		if u, ok := e.(app.URLEvent); ok {
			events.add("URLEvent " + u.URL.String())
		}
		if f.Suspend != nil {
			if s, ok := f.Suspend(e); ok {
				suspend.Store(int32(suspendOf(s)))
				if s {
					events.add("SuspendEvent")
				} else {
					events.add("ResumeEvent")
				}
			}
		}
		return true
	})
}

func (f Features) clipboardWrite(text string, sensitive bool) clipboard.WriteCmd {
	cmd := clipboard.WriteCmd{
		Type: "application/text",
		Data: io.NopCloser(strings.NewReader(text)),
	}
	if sensitive && f.MarkSensitive != nil {
		f.MarkSensitive(&cmd)
	}
	return cmd
}

// suspend is the state of the last SuspendEvent or ResumeEvent: it comes
// from app.Events, and the window shows it.
var suspend atomic.Int32

const (
	suspendNone = iota // no SuspendEvent or ResumeEvent yet
	suspendResumed
	suspendSuspended
)

func suspendOf(suspended bool) int {
	if suspended {
		return suspendSuspended
	}
	return suspendResumed
}
