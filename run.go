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
	"fmt"
	"image/color"
	"io"
	"log"
	"os"
	"strings"
	"sync/atomic"
	"time"

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
	// Background reports whether e is an app.BackgroundEvent (in the background) or an
	// app.ForegroundEvent (in the foreground).
	Background func(e event.Event) (background, ok bool)
	// DecorationColors returns the app.DecorationColors option.
	DecorationColors func(bg, fg color.NRGBA) app.Option
	// Wipe calls widget.Editor.Wipe.
	Wipe func(*widget.Editor)
	// SaveFilePath calls explorer.Explorer.SaveFilePath.
	SaveFilePath func(x *explorer.Explorer, name string) (string, error)
	// BackgroundDraw turns drawing in the background on or off (iOS, the diag
	// build only).
	BackgroundDraw func(on bool)
	// Trace sets the function that gets what the driver does (iOS, the diag
	// build only). Lines that start with "raw:" also go to the event log.
	Trace func(f func(string))
}

// The scripts set these with -ldflags "-X ...".
var (
	// buildFlags lists the gogio flags of the build.
	buildFlags = "none"
	// urlScheme is the URL scheme the build registers (gogio -schemes).
	urlScheme = "gioplayground"
)

// Run runs the program; it must be called from main and never returns.
//
// For tests without a person at the screen (the CI workflow), two variables
// of the environment:
//
//	PLAYGROUND_LOG   the event log also goes to this file; "1" picks
//	                 Documents/playground.log in the home directory, which
//	                 is the app's own on iOS
//	PLAYGROUND_COPY  "sensitive" or "plain": the first frame copies what the
//	                 buttons of the Clipboard page copy
func Run(f Features) {
	if v := os.Getenv("PLAYGROUND_LOG"); v != "" {
		if v == "1" {
			v = ""
		}
		openLogFile(v)
	}
	events.add("process started (Gio: " + f.Name + ", gogio flags: " + buildFlags + ")")
	if !registersScheme() {
		events.add("no URL scheme registered: started without an app bundle (go run), see the page URLs and iOS scenes")
	}
	initPlatform()
	if f.Trace != nil {
		// The diag build is for the test that needs the quiet log.
		quiet.Store(true)
		openLogFile("")
		f.Trace(func(s string) {
			if strings.HasPrefix(s, "raw:") {
				events.add("gio " + s)
				return
			}
			detail("gio: " + s)
		})
	}
	go func() {
		w := new(app.Window)
		mainWindow.Store(w)
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
			if u.URL.Host == "diag" && f.Trace != nil {
				f.diagCommand(u.URL.Query())
			}
		}
		if f.Background != nil {
			if s, ok := f.Background(e); ok {
				if s {
					returns.left(f.switches())
				} else {
					returns.back(time.Now())
				}
				background.Store(int32(backgroundOf(s)))
				invalidateInHandler()
				if !s {
					foregrounds.Add(1)
				}
				if s {
					events.add("BackgroundEvent")
				} else {
					events.add("ForegroundEvent")
				}
			}
		}
		return true
	})
}

// switches says how the test of the Background page is set up.
func (f Features) switches() string {
	s := fmt.Sprintf("quiet log: %v, Invalidate in the handler: %v", quiet.Load(), invalidateSync.Load())
	if f.BackgroundDraw != nil {
		s += fmt.Sprintf(", draw in the background: %v", backgroundDrawOn.Load())
	}
	return s
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

// background is the state of the last BackgroundEvent or ForegroundEvent: it comes
// from app.Events, and the window shows it.
var background atomic.Int32

// mainWindow is the program's window, for invalidateInHandler.
var mainWindow atomic.Pointer[app.Window]

// invalidateSync is the switch of the Background page: invalidate the
// window right in the BackgroundEvent and ForegroundEvent handler, on the
// main thread, as a program would that asks for a redraw when it leaves.
var invalidateSync atomic.Bool

// invalidateInHandler calls Window.Invalidate in the app.Events handler when
// the switch is on. Without the Gio patch that posts the macOS/iOS wakeup to
// the main queue also from the main thread, that hangs on iOS: the wakeup
// runs the event loop inline, the main thread waits for a mutex that
// Window.Invalidate holds itself, and the watchdog kills the app in the
// background. The log line after the call shows that it returned.
func invalidateInHandler() {
	w := mainWindow.Load()
	if !invalidateSync.Load() || w == nil {
		return
	}
	events.add("calling Window.Invalidate in the handler (main thread)")
	w.Invalidate()
	events.add("Window.Invalidate returned")
}

// backgroundDrawOn is the switch of the Background page in the diag build.
var backgroundDrawOn atomic.Bool

// foregrounds counts the ForegroundEvents, so that the window can tell its
// first frame after one.
var foregrounds atomic.Int32

const (
	backgroundNone = iota // no BackgroundEvent or ForegroundEvent yet
	inForeground
	inBackground
)

func backgroundOf(bg bool) int {
	if bg {
		return inBackground
	}
	return inForeground
}
