package playground

import (
	"fmt"
	"runtime"
	"strings"

	"gioui.org/app"
	"gioui.org/font/gofont"
	"gioui.org/io/key"
	"gioui.org/layout"
	"gioui.org/op"
	"gioui.org/op/paint"
	"gioui.org/text"
	"gioui.org/unit"
	"gioui.org/widget"
	"gioui.org/widget/material"
	"gioui.org/x/explorer"
)

// A page exercises one patch.
type page interface {
	// title is the menu entry and the heading of the page.
	title() string
	// about names the patch and where it was sent.
	about() string
	// layout returns the rows of the page, below its heading.
	layout(u *ui, gtx layout.Context) []layout.Widget
}

type menuEntry struct {
	page page
	open widget.Clickable
}

type ui struct {
	w    *app.Window
	f    Features
	th   *material.Theme
	expl *explorer.Explorer
	ops  op.Ops

	menu []*menuEntry
	cur  *menuEntry // nil shows the menu
	back widget.Clickable
	list widget.List

	cfg    app.Config
	gotCfg bool
}

func newUI(w *app.Window, f Features) *ui {
	th := material.NewTheme()
	th.Shaper = text.NewShaper(text.NoSystemFonts(), text.WithCollection(gofont.Collection()))
	u := &ui{w: w, f: f, th: th, expl: explorer.NewExplorer(w)}
	u.list.Axis = layout.Vertical
	for _, p := range []page{
		new(clipboardPage),
		new(lifecyclePage),
		new(scenePage),
		new(titleBarPage),
		new(wipePage),
		new(filesPage),
		new(logPage),
	} {
		u.menu = append(u.menu, &menuEntry{page: p})
	}
	return u
}

func (u *ui) run() error {
	events.setChanged(u.w.Invalidate)
	events.add("window event loop started")
	for {
		e := u.w.Event()
		u.expl.ListenEvents(e)
		switch e := e.(type) {
		case app.DestroyEvent:
			events.add(fmt.Sprintf("DestroyEvent err=%v", e.Err))
			return e.Err
		case app.ConfigEvent:
			u.config(e.Config)
		case app.ViewEvent:
			events.add(fmt.Sprintf("%T valid=%v", e, e.Valid()))
		case app.FrameEvent:
			gtx := app.NewContext(&u.ops, e)
			u.layout(gtx)
			e.Frame(gtx.Ops)
		}
	}
}

// config logs the changes of the fields that the pages are about.
func (u *ui) config(c app.Config) {
	prev, first := u.cfg, !u.gotCfg
	u.cfg, u.gotCfg = c, true
	var changes []string
	if first || c.Focused != prev.Focused {
		changes = append(changes, fmt.Sprintf("Focused=%v", c.Focused))
	}
	if h, ok := u.f.hidden(c); ok {
		if ph, _ := u.f.hidden(prev); first || h != ph {
			changes = append(changes, fmt.Sprintf("Hidden=%v", h))
		}
	}
	if first || c.Mode != prev.Mode {
		changes = append(changes, fmt.Sprintf("Mode=%v", c.Mode))
	}
	if first || c.Decorated != prev.Decorated {
		changes = append(changes, fmt.Sprintf("Decorated=%v", c.Decorated))
	}
	if len(changes) > 0 {
		events.add("ConfigEvent " + strings.Join(changes, " "))
	}
}

func (u *ui) layout(gtx layout.Context) {
	paint.Fill(gtx.Ops, u.th.Bg)
	if u.cur != nil {
		// Back (Android's back gesture, Escape elsewhere) returns to the
		// menu; on the menu it is left to the system.
		for {
			ev, ok := gtx.Event(key.Filter{Name: key.NameBack}, key.Filter{Name: key.NameEscape})
			if !ok {
				break
			}
			if e, ok := ev.(key.Event); ok && e.State == key.Press {
				u.cur = nil
			}
		}
		if u.back.Clicked(gtx) {
			u.cur = nil
		}
	}
	for _, m := range u.menu {
		if m.open.Clicked(gtx) {
			u.cur = m
			u.list.Position = layout.Position{}
		}
	}
	var rows []layout.Widget
	if u.cur == nil {
		rows = u.menuRows()
	} else {
		rows = u.pageRows(gtx, u.cur.page)
	}
	material.List(u.th, &u.list).Layout(gtx, len(rows), func(gtx layout.Context, i int) layout.Dimensions {
		return layout.Inset{Top: unit.Dp(6), Bottom: unit.Dp(6), Left: unit.Dp(16), Right: unit.Dp(16)}.Layout(gtx, rows[i])
	})
}

func (u *ui) menuRows() []layout.Widget {
	rows := []layout.Widget{
		material.H5(u.th, "Gio playground").Layout,
		u.caption(fmt.Sprintf("Gio: %s build · gogio flags: %s · %s/%s", u.f.Name, buildFlags, runtime.GOOS, runtime.GOARCH)),
	}
	for _, m := range u.menu {
		rows = append(rows, func(gtx layout.Context) layout.Dimensions {
			return layout.Flex{Axis: layout.Vertical}.Layout(gtx,
				layout.Rigid(func(gtx layout.Context) layout.Dimensions {
					gtx.Constraints.Min.X = gtx.Constraints.Max.X
					return material.Button(u.th, &m.open, m.page.title()).Layout(gtx)
				}),
				layout.Rigid(u.caption(m.page.about())),
			)
		})
	}
	return rows
}

func (u *ui) pageRows(gtx layout.Context, p page) []layout.Widget {
	rows := []layout.Widget{
		func(gtx layout.Context) layout.Dimensions {
			return layout.Flex{Alignment: layout.Middle}.Layout(gtx,
				layout.Rigid(material.Button(u.th, &u.back, "Back").Layout),
				layout.Rigid(layout.Spacer{Width: unit.Dp(16)}.Layout),
				layout.Flexed(1, material.H6(u.th, p.title()).Layout),
			)
		},
		u.caption(p.about()),
	}
	rows = append(rows, p.layout(u, gtx)...)
	if _, ok := p.(*logPage); !ok {
		rows = append(rows, material.Subtitle2(u.th, "Recent events").Layout)
		for _, e := range events.last(10) {
			rows = append(rows, u.mono(e))
		}
	}
	return rows
}

func (u *ui) text(s string) layout.Widget { return material.Body1(u.th, s).Layout }

func (u *ui) caption(s string) layout.Widget { return material.Caption(u.th, s).Layout }

func (u *ui) mono(s string) layout.Widget {
	l := material.Caption(u.th, s)
	l.Font.Typeface = "Go Mono"
	return l.Layout
}

// button returns a button that takes the whole width.
func (u *ui) button(c *widget.Clickable, label string) layout.Widget {
	return func(gtx layout.Context) layout.Dimensions {
		gtx.Constraints.Min.X = gtx.Constraints.Max.X
		return material.Button(u.th, c, label).Layout(gtx)
	}
}
