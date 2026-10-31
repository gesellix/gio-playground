module github.com/gesellix/gio-playground/fork

go 1.27.3

require (
	gioui.org v0.10.4-0.20261026070653-20998f2d0b4a
	gioui.org/x v0.10.3
	github.com/gesellix/gio-playground v0.0.0
)

require (
	gioui.org/cmd v0.10.4-0.20261026065032-c57ee406638b // indirect
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

// gioui.org: upstream main 20998f2d (2026-10-25), which has iOS 13, the
// UIScene life cycle and clipboard Sensitive from v2 of the Gio series
// (gio-patches 72119), plus app.BackgroundEvent and ForegroundEvent (v4 of
// 2/4, which replaces Config.Hidden), DecorationColors (dropped from the
// series) and
// Editor.Wipe, the fork's branch pwdmgr-background-event
// (github.com/gesellix/gio-forked).
replace gioui.org => github.com/gesellix/gio-forked v0.10.4-0.20261031091025-2ab32f100436

// gioui.org/x v0.10.3 plus the explorer patches, as sent upstream
// (gio-patches 72104).
replace gioui.org/x => github.com/gesellix/gio-x v0.0.0-20261024101701-d143eccbdf2c

// gioui.org/cmd (gogio, run as 'go tool gogio') upstream c57ee40, which has
// the scene manifest with iOS 13 as the default -minsdk, plus -plist,
// -privacymanifest and -manifest (gio-patches 72106), the fork's branch
// pwdmgr (github.com/gesellix/gio-cmd).
replace gioui.org/cmd => github.com/gesellix/gio-cmd v0.0.0-20261026075116-f147ae0fe09d

tool gioui.org/cmd/gogio
