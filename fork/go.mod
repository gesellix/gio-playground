module github.com/gesellix/gio-playground/fork

go 1.27.3

require (
	gioui.org v0.10.4-0.20261107133850-2919cda56e42
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

// gioui.org: upstream main 2919cda5 (2026-11-06), which has iOS 13, the UIScene
// life cycle, clipboard Sensitive, the macOS/iOS wakeup on the main queue and
// app.BackgroundEvent and ForegroundEvent, plus DecorationColors (dropped from
// the series), Editor.Wipe and the X11 clipboard refusal (gio-patches 72360),
// the fork's branch pwdmgr-2919cda5 (github.com/gesellix/gio-forked).
replace gioui.org => github.com/gesellix/gio-forked v0.10.4-0.20261107171631-99c9a8c918eb

// gioui.org/x upstream main, which has our two Android patches, plus
// explorer.SaveFilePath, the rest of what was sent upstream (gio-patches 72104).
replace gioui.org/x => github.com/gesellix/gio-x v0.0.0-20261102213852-91215c32f22b

// gioui.org/cmd (gogio, run as 'go tool gogio') upstream c57ee40, which has
// the scene manifest with iOS 13 as the default -minsdk, plus -plist,
// -privacymanifest and -manifest (gio-patches 72106), the fork's branch
// pwdmgr (github.com/gesellix/gio-cmd).
replace gioui.org/cmd => github.com/gesellix/gio-cmd v0.0.0-20261026075116-f147ae0fe09d

tool gioui.org/cmd/gogio
