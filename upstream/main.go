// The playground built with upstream Gio, gio-x and gogio, to show the
// behaviour before the patches: their pages say "not in this build".
package main

import playground "github.com/gesellix/gio-playground"

func main() {
	playground.Run(playground.Features{Name: "upstream"})
}
