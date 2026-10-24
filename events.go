package playground

import (
	"fmt"
	"log"
	"strings"
	"sync"
	"time"
)

// events is the log that all pages share. Entries come from the window's
// event loop, from app.Events and from platform callbacks, so it is safe
// for concurrent use.
var events eventLog

type eventLog struct {
	mu      sync.Mutex
	start   time.Time
	entries []string
	// changed is called after each entry, to redraw the window.
	changed func()
}

const maxEntries = 500

func (l *eventLog) add(s string) {
	l.mu.Lock()
	now := time.Now()
	if l.start.IsZero() {
		l.start = now
	}
	e := fmt.Sprintf("%s +%.1fs %s", now.Format("15:04:05"), now.Sub(l.start).Seconds(), s)
	l.entries = append(l.entries, e)
	if len(l.entries) > maxEntries {
		l.entries = l.entries[len(l.entries)-maxEntries:]
	}
	changed := l.changed
	l.mu.Unlock()
	// Also on stdout: adb logcat, the Xcode console, the terminal.
	log.Print(s)
	if changed != nil {
		// Never from the caller's thread: entries also come from callbacks
		// on the main thread (UIKit notifications, URLs), and there
		// Window.Invalidate wakes the window synchronously, delivering
		// events in the middle of the callback. On iOS that hung the app
		// while UIKit connected the scene.
		go changed()
	}
}

// last returns up to n entries, the newest first.
func (l *eventLog) last(n int) []string {
	l.mu.Lock()
	defer l.mu.Unlock()
	if n > len(l.entries) || n < 0 {
		n = len(l.entries)
	}
	out := make([]string, 0, n)
	for i := len(l.entries) - 1; i >= len(l.entries)-n; i-- {
		out = append(out, l.entries[i])
	}
	return out
}

// text returns the whole log, the oldest entry first.
func (l *eventLog) text() string {
	l.mu.Lock()
	defer l.mu.Unlock()
	return strings.Join(l.entries, "\n") + "\n"
}

func (l *eventLog) setChanged(f func()) {
	l.mu.Lock()
	l.changed = f
	l.mu.Unlock()
}

func (l *eventLog) clear() {
	l.mu.Lock()
	l.entries = nil
	l.mu.Unlock()
	l.add("log cleared")
}
