// The playground built with upstream Gio, gio-x and gogio, to show the
// behaviour without the patches that upstream does not have yet: their
// pages say "not in this build".
package main

import (
	"gioui.org/io/clipboard"

	playground "github.com/gesellix/gio-playground"
)

func main() {
	playground.Run(playground.Features{
		Name:          "upstream",
		MarkSensitive: func(c *clipboard.WriteCmd) { c.Sensitive = true },
	})
}
