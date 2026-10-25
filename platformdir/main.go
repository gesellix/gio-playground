// The playground built like the fork, but with the gogio of -platformdir
// (see go.mod): the scripts pass complete platform files instead of the
// manifest flags.
package main

import (
	"image/color"

	"gioui.org/app"
	"gioui.org/io/clipboard"
	"gioui.org/widget"
	"gioui.org/x/explorer"

	playground "github.com/gesellix/gio-playground"
)

func main() {
	playground.Run(playground.Features{
		Name:          "platformdir",
		MarkSensitive: func(c *clipboard.WriteCmd) { c.Sensitive = true },
		Hidden:        func(c app.Config) bool { return c.Hidden },
		DecorationColors: func(bg, fg color.NRGBA) app.Option {
			return app.DecorationColors(bg, fg)
		},
		Wipe: (*widget.Editor).Wipe,
		SaveFilePath: func(x *explorer.Explorer, name string) (string, error) {
			return x.SaveFilePath(name)
		},
	})
}
