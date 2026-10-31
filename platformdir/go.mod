module github.com/gesellix/gio-playground/platformdir

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
	github.com/cpuguy83/go-md2man/v2 v2.0.2 // indirect
	github.com/go-ole/go-ole v1.3.0 // indirect
	github.com/go-text/typesetting v0.3.5 // indirect
	github.com/godbus/dbus/v5 v5.2.4 // indirect
	github.com/nfnt/resize v0.0.0-20180221191011-83c6a9932646 // indirect
	github.com/russross/blackfriday/v2 v2.1.0 // indirect
	github.com/tc-hib/go-winres v0.3.3 // indirect
	github.com/tc-hib/winres v0.2.1 // indirect
	github.com/urfave/cli/v2 v2.25.7 // indirect
	github.com/xrash/smetrics v0.0.0-20201216005158-039620a65673 // indirect
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

tool (
	gioui.org/cmd/gogio
	github.com/tc-hib/go-winres
)

// gioui.org/cmd (gogio) upstream c57ee40 plus the -platformdir prototype,
// the fork's branch platform-dir-v4 (github.com/gesellix/gio-cmd).
replace gioui.org/cmd => github.com/gesellix/gio-cmd v0.0.0-20261031084054-8127c457deba
