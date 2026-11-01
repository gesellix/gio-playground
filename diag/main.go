// The fork's program with a trace of the iOS driver and a switch to draw in the
// background (see go.mod and the Gio branch diag-background-state). Test only.
package main

import (
	"image/color"

	"gioui.org/app"
	"gioui.org/io/clipboard"
	"gioui.org/io/event"
	"gioui.org/widget"
	"gioui.org/x/explorer"

	playground "github.com/gesellix/gio-playground"
)

func main() {
	playground.Run(playground.Features{
		Name:          "diag",
		MarkSensitive: func(c *clipboard.WriteCmd) { c.Sensitive = true },
		Background: func(e event.Event) (bool, bool) {
			switch e.(type) {
			case app.BackgroundEvent:
				return true, true
			case app.ForegroundEvent:
				return false, true
			}
			return false, false
		},
		DecorationColors: func(bg, fg color.NRGBA) app.Option {
			return app.DecorationColors(bg, fg)
		},
		Wipe: (*widget.Editor).Wipe,
		SaveFilePath: func(x *explorer.Explorer, name string) (string, error) {
			return x.SaveFilePath(name)
		},
		BackgroundDraw: app.DiagDrawInBackground.Store,
		Trace:          app.DiagSetTrace,
	})
}
