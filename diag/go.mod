module github.com/gesellix/gio-playground/diag

go 1.27.3

require (
	gioui.org v0.10.4-0.20261109081438-327752e960e3
	gioui.org/x v0.10.3
	github.com/gesellix/gio-playground v0.0.0
)

require (
	gioui.org/cmd v0.10.4-0.20261026065032-c57ee406638b // indirect
	gioui.org/shader v1.0.9 // indirect
	git.wow.st/gmp/jni v0.0.0-20260821030830-2b2c1e0034f1 // indirect
	github.com/akavel/rsrc v0.10.2 // indirect
	github.com/cpuguy83/go-md2man/v2 v2.0.7 // indirect
	github.com/go-ole/go-ole v1.3.0 // indirect
	github.com/go-text/typesetting v0.3.5 // indirect
	github.com/godbus/dbus/v5 v5.2.4 // indirect
	github.com/nfnt/resize v0.0.0-20180221191011-83c6a9932646 // indirect
	github.com/russross/blackfriday/v2 v2.1.0 // indirect
	github.com/tc-hib/go-winres v0.3.3 // indirect
	github.com/tc-hib/winres v0.3.1 // indirect
	github.com/urfave/cli/v2 v2.27.7 // indirect
	github.com/xrash/smetrics v0.0.0-20261013231157-39c47d93efba // indirect
	golang.org/x/exp/shiny v0.0.0-20261106192419-47ce03d25ef0 // indirect
	golang.org/x/image v0.47.0 // indirect
	golang.org/x/mod v0.42.0 // indirect
	golang.org/x/net v0.62.0 // indirect
	golang.org/x/sync v0.24.0 // indirect
	golang.org/x/sys v0.49.0 // indirect
	golang.org/x/text v0.43.0 // indirect
	golang.org/x/tools v0.52.0 // indirect
)

replace github.com/gesellix/gio-playground => ../

// gioui.org: upstream main 327752e9 (2026-11-09), which has iOS 13, the UIScene
// life cycle, clipboard Sensitive, the macOS/iOS wakeup on the main queue and
// app.BackgroundEvent and ForegroundEvent and the X11 clipboard refusal
// (gio-patches 72360), plus DecorationColors (dropped from the series) and
// Editor.Wipe, the fork's branch pwdmgr-327752e9 (github.com/gesellix/gio-forked), with the
// branch diag-background-state-327752e9 on top of it: test only, never sent
// upstream.
replace gioui.org => github.com/gesellix/gio-forked v0.10.4-0.20261109092624-dfac3f8748b9

// gioui.org/x upstream main, which has our two Android patches, plus
// explorer.SaveFilePath, the rest of what was sent upstream (gio-patches 72104).
replace gioui.org/x => github.com/gesellix/gio-x v0.0.0-20261102213852-91215c32f22b

// gioui.org/cmd (gogio) upstream c57ee40 plus the -platformdir prototype,
// the fork's branch platform-dir-v4 (github.com/gesellix/gio-cmd).
replace gioui.org/cmd => github.com/gesellix/gio-cmd v0.0.0-20261031084054-8127c457deba

tool (
	gioui.org/cmd/gogio
	github.com/tc-hib/go-winres
)
