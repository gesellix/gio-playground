package playground

import (
	"errors"
	"fmt"
	"image/color"
	"io"
	"os"
	"slices"
	"strings"
	"time"

	"gioui.org/layout"
	"gioui.org/widget"
	"gioui.org/widget/material"
	"gioui.org/x/explorer"
)

type clipboardPage struct {
	sensitive, plain widget.Clickable
}

func (*clipboardPage) title() string { return "Clipboard: sensitive content" }
func (*clipboardPage) about() string {
	return "Gio: clipboard.WriteCmd.Sensitive (Gio series v2 1/4)"
}

func (p *clipboardPage) layout(u *ui, gtx layout.Context) []layout.Widget {
	if p.sensitive.Clicked(gtx) {
		gtx.Execute(u.f.clipboardWrite("SENSITIVE-secret-123", true))
		events.add("copied SENSITIVE-secret-123 with Sensitive: true")
	}
	if p.plain.Clicked(gtx) {
		gtx.Execute(u.f.clipboardWrite("PLAIN-text-456", false))
		events.add("copied PLAIN-text-456 with Sensitive: false")
	}
	rows := []layout.Widget{
		u.button(&p.sensitive, "Copy sensitive"),
		u.button(&p.plain, "Copy plain"),
		u.text("Both paste normally. Where to see the difference:"),
		u.text("• Android 13 and later: the clipboard preview shows dots for the sensitive copy."),
		u.text("• iOS: the sensitive copy does not reach a Mac through Universal Clipboard."),
		u.text("• Windows: the sensitive copy is not in the Win+V history."),
		u.text("• KDE (X11, Wayland): Klipper keeps no entry for it."),
		u.text("• macOS: clipboard managers that follow nspasteboard.org skip it."),
	}
	if u.f.MarkSensitive == nil {
		rows = append(rows, u.text("This build has no Sensitive field: both copies are plain."))
	}
	return rows
}

type lifecyclePage struct{}

func (*lifecyclePage) title() string { return "Background: Config.Hidden" }
func (*lifecyclePage) about() string {
	return "Gio: Config.Hidden on Android and iOS (Gio series v2 2/4)"
}

func (*lifecyclePage) layout(u *ui, gtx layout.Context) []layout.Widget {
	hidden := "not in this build"
	if h, ok := u.f.hidden(u.cfg); ok {
		hidden = fmt.Sprint(h)
	}
	return []layout.Widget{
		u.mono(fmt.Sprintf("Focused=%v Hidden=%s Mode=%v", u.cfg.Focused, hidden, u.cfg.Mode)),
		u.text("Leave the app (home, app switcher, screen off) and come back: the log shows Hidden=true, then Hidden=false."),
		u.text("Open the notification shade, the Control Center or a system dialog: only Focused changes."),
		u.text("On the desktop Hidden stays false."),
	}
}

type scenePage struct {
	disconnect widget.Clickable
}

func (*scenePage) title() string { return "URLs and iOS scenes" }
func (*scenePage) about() string {
	return "Gio: the UIScene life cycle on iOS (Gio series v2 4/4); gogio adds the scene manifest"
}

func (p *scenePage) layout(u *ui, gtx layout.Context) []layout.Widget {
	if p.disconnect.Clicked(gtx) {
		events.add("disconnecting the scene")
		disconnectScene()
	}
	rows := []layout.Widget{
		u.text(fmt.Sprintf("Open %s://hello in Safari or Notes, once while the app runs and once after closing it in the app switcher (a cold start). The log shows a URLEvent each time.", urlScheme)),
	}
	if !registersScheme() {
		rows = append(rows, u.text(fmt.Sprintf("This build registers no URL scheme: a program started with go run or scripts/desktop.sh is no app bundle, so the system knows no app for %s:// URLs. Build an app with scripts/macos.sh, scripts/android.sh or scripts/ios.sh.", urlScheme)))
	}
	if canDisconnectScene {
		rows = append(rows,
			u.button(&p.disconnect, "Disconnect the scene"),
			u.text("Then open the app from its icon. If the older log entries are still there, the process and its window survived and moved to the new scene; after a fresh start the log begins with \"process started\"."),
		)
	} else {
		rows = append(rows, u.text("Disconnecting a scene is only available on iOS."))
	}
	return rows
}

type titleBarPage struct {
	dark, light, accent, reset widget.Clickable
}

func (*titleBarPage) title() string { return "Title bar colors" }
func (*titleBarPage) about() string {
	return "Gio: app.DecorationColors (fork only, dropped from the Gio series)"
}

func (p *titleBarPage) layout(u *ui, gtx layout.Context) []layout.Widget {
	set := func(name string, bg, fg color.NRGBA) {
		if u.f.DecorationColors == nil {
			events.add("DecorationColors: not in this build")
			return
		}
		u.w.Option(u.f.DecorationColors(bg, fg))
		events.add("DecorationColors: " + name)
	}
	if p.dark.Clicked(gtx) {
		set("dark", color.NRGBA{R: 0x20, G: 0x21, B: 0x24, A: 0xff}, color.NRGBA{R: 0xe8, G: 0xea, B: 0xed, A: 0xff})
	}
	if p.light.Clicked(gtx) {
		set("light", color.NRGBA{R: 0xf1, G: 0xf3, B: 0xf4, A: 0xff}, color.NRGBA{R: 0x20, G: 0x21, B: 0x24, A: 0xff})
	}
	if p.accent.Clicked(gtx) {
		set("accent", color.NRGBA{R: 0x67, G: 0x50, B: 0xa4, A: 0xff}, color.NRGBA{R: 0xff, G: 0xff, B: 0xff, A: 0xff})
	}
	if p.reset.Clicked(gtx) {
		set("default (zero colors)", color.NRGBA{}, color.NRGBA{})
	}
	return []layout.Widget{
		u.text("Gio draws its own title bar only where the window manager provides none, such as Wayland under GNOME (the log shows Decorated=false there). Elsewhere the buttons change nothing visible."),
		u.button(&p.dark, "Dark"),
		u.button(&p.light, "Light"),
		u.button(&p.accent, "Accent"),
		u.button(&p.reset, "Default"),
	}
}

type wipePage struct {
	editor        widget.Editor
	wipe, setText widget.Clickable
	init          bool
}

func (*wipePage) title() string { return "Editor.Wipe" }
func (*wipePage) about() string {
	return "Gio: widget.Editor.Wipe (separate patch, not sent yet)"
}

func (p *wipePage) layout(u *ui, gtx layout.Context) []layout.Widget {
	if !p.init {
		p.init = true
		p.editor.SingleLine = true
		p.editor.Mask = '•'
	}
	if p.wipe.Clicked(gtx) {
		n := p.editor.Len()
		if u.f.Wipe != nil {
			u.f.Wipe(&p.editor)
			events.add(fmt.Sprintf("Wipe: Len() %d -> %d", n, p.editor.Len()))
		} else {
			events.add("Wipe: not in this build")
		}
	}
	if p.setText.Clicked(gtx) {
		p.editor.SetText("")
		events.add(fmt.Sprintf("SetText(\"\"): Len()=%d", p.editor.Len()))
	}
	return []layout.Widget{
		u.text("Type a secret, then empty the editor with either button. Wipe also overwrites the editor's own copies; the editor stays usable."),
		material.Editor(u.th, &p.editor, "secret").Layout,
		u.button(&p.wipe, "Wipe"),
		u.button(&p.setText, "SetText(\"\")"),
	}
}

type filesPage struct {
	exportUnknown, exportText, savePath widget.Clickable
}

func (*filesPage) title() string { return "Files: export and save" }
func (*filesPage) about() string {
	return "gio-x: explorer fixes on Android and SaveFilePath (gio-patches 72104)"
}

func (p *filesPage) layout(u *ui, gtx layout.Context) []layout.Widget {
	if p.exportUnknown.Clicked(gtx) {
		go createFile(u.expl, "playground.gioplay")
	}
	if p.exportText.Clicked(gtx) {
		go createFile(u.expl, "playground.txt")
	}
	if p.savePath.Clicked(gtx) {
		go saveViaPath(u, "playground.txt")
	}
	return []layout.Widget{
		u.button(&p.exportUnknown, "CreateFile: unknown extension"),
		u.text("An extension that Android's MimeTypeMap does not know. Without the fix, no app matches the intent and the result is ErrUserDecline as if cancelled."),
		u.button(&p.exportText, "CreateFile: .txt"),
		u.text("On Android the log shows the URI and name of the created file."),
		u.button(&p.savePath, "SaveFilePath"),
		u.text("Desktop only: the dialog returns a path, the file is written to a temporary file and renamed. An existing file stays intact until then, also on cancel."),
	}
}

func fileContent() string {
	return "written by gio-playground at " + time.Now().Format(time.RFC3339) + "\n"
}

func createFile(x *explorer.Explorer, name string) {
	w, err := x.CreateFile(name)
	if err != nil {
		events.add(fmt.Sprintf("CreateFile(%q): %v", name, err))
		return
	}
	_, err = io.WriteString(w, fileContent())
	if cerr := w.Close(); err == nil {
		err = cerr
	}
	info := fmt.Sprintf("%T", w)
	if f, ok := w.(*explorer.File); ok {
		info += fmt.Sprintf(" name=%q uri=%q", f.Name(), f.URI())
	} else if f, ok := w.(*os.File); ok {
		info += fmt.Sprintf(" path=%q", f.Name())
	}
	events.add(fmt.Sprintf("CreateFile(%q): %s, write: %v", name, info, err))
}

func saveViaPath(u *ui, name string) {
	if u.f.SaveFilePath == nil {
		events.add("SaveFilePath: not in this build")
		return
	}
	path, err := u.f.SaveFilePath(u.expl, name)
	if err != nil {
		if errors.Is(err, explorer.ErrUserDecline) {
			events.add("SaveFilePath: cancelled")
		} else {
			events.add(fmt.Sprintf("SaveFilePath(%q): %v", name, err))
		}
		return
	}
	tmp := path + ".tmp"
	err = os.WriteFile(tmp, []byte(fileContent()), 0o644)
	if err == nil {
		err = os.Rename(tmp, path)
	}
	events.add(fmt.Sprintf("SaveFilePath: %q, write and rename: %v", path, err))
}

type logPage struct {
	copyLog, clear widget.Clickable
}

func (*logPage) title() string { return "Event log" }
func (*logPage) about() string {
	return "Everything the pages and the platform reported, newest first"
}

func (p *logPage) layout(u *ui, gtx layout.Context) []layout.Widget {
	if p.copyLog.Clicked(gtx) {
		gtx.Execute(u.f.clipboardWrite(events.text(), false))
		events.add("log copied to the clipboard")
	}
	if p.clear.Clicked(gtx) {
		events.clear()
	}
	rows := []layout.Widget{
		u.button(&p.copyLog, "Copy the log"),
		u.button(&p.clear, "Clear the log"),
	}
	for _, e := range events.last(-1) {
		rows = append(rows, u.mono(e))
	}
	return rows
}

// registersScheme reports whether the build registered urlScheme (gogio
// -schemes, or the complete platform files of -platformdir), which the
// scripts note in buildFlags.
func registersScheme() bool {
	flags := strings.Split(buildFlags, ",")
	return slices.Contains(flags, "schemes") || slices.Contains(flags, "platformdir")
}
