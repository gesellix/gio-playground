module github.com/gesellix/gio-playground/platformdir

go 1.27.3

require (
	gioui.org v0.10.4-0.20261022163903-c2a339fad4aa
	gioui.org/x v0.10.3
	github.com/gesellix/gio-playground v0.0.0
)

require (
	gioui.org/cmd v0.10.4-0.20261023054843-e2ff547b93d0 // indirect
	gioui.org/shader v1.0.9 // indirect
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

// gioui.org: upstream main c2a339fa (2026-10-22) plus v2 of the Gio series
// (gio-patches 72110, v2 after the review: iOS 13, UIScene unconditional)
// and Editor.Wipe on top, the fork's branch pwdmgr
// (github.com/gesellix/gio-forked).
replace gioui.org => github.com/gesellix/gio-forked v0.10.4-0.20261025130827-4d4f4b34f79b

// gioui.org/x v0.10.3 plus the explorer patches, as sent upstream
// (gio-patches 72104).
replace gioui.org/x => github.com/gesellix/gio-x v0.0.0-20261024101701-d143eccbdf2c

tool gioui.org/cmd/gogio

replace gioui.org/cmd => github.com/gesellix/gio-cmd v0.0.0-20261025183133-abc6d01c9a6e
