// Package playground is a small Gio program to try out patches to Gio,
// gio-x and gogio on a device. Each page exercises one patch, and an event
// log that all pages share records what the program receives, so a test can
// be shown (or copied) afterwards.
//
// The program itself is in the modules fork (with the patches) and
// upstream (without them). This package builds against upstream Gio and
// gio-x; the fork passes the APIs that the patches add as Features.
package playground

import (
	"image/color"
	"io"
	"log"
	"os"
	"strings"

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
	// Hidden returns app.Config.Hidden.
	Hidden func(app.Config) bool
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
	app.Events(func(e event.Event) bool {
		if u, ok := e.(app.URLEvent); ok {
			events.add("URLEvent " + u.URL.String())
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

func (f Features) hidden(c app.Config) (hidden, ok bool) {
	if f.Hidden == nil {
		return false, false
	}
	return f.Hidden(c), true
}
