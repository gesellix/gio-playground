module github.com/gesellix/gio-playground/upstream

go 1.27.3

// Upstream Gio, gio-x and gogio, without the patches upstream does not
// have yet.
require (
	gioui.org v0.10.4-0.20261026070653-20998f2d0b4a
	github.com/gesellix/gio-playground v0.0.0
)

require (
	gioui.org/cmd v0.10.4-0.20261026065032-c57ee406638b // indirect
	gioui.org/shader v1.0.9 // indirect
	gioui.org/x v0.10.3 // indirect
	git.wow.st/gmp/jni v0.0.0-20260821030830-2b2c1e0034f1 // indirect
	github.com/akavel/rsrc v0.10.2 // indirect
	github.com/go-ole/go-ole v1.3.0 // indirect
	github.com/go-text/typesetting v0.3.5 // indirect
	github.com/godbus/dbus/v5 v5.2.4 // indirect
	golang.org/x/exp/shiny v0.0.0-20261014143641-f0251eb4aa3e // indirect
	golang.org/x/image v0.47.0 // indirect
	golang.org/x/mod v0.42.0 // indirect
	golang.org/x/net v0.61.0 // indirect
	golang.org/x/sync v0.24.0 // indirect
	golang.org/x/sys v0.49.0 // indirect
	golang.org/x/text v0.43.0 // indirect
	golang.org/x/tools v0.52.0 // indirect
)

replace github.com/gesellix/gio-playground => ../

tool gioui.org/cmd/gogio
