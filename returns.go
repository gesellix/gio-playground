package playground

import (
	"sync"
	"time"
)

// returns records the last trip to the background and back, for the
// Background page: everything from the BackgroundEvent until returnWindow
// after the ForegroundEvent, with the frames and the driver's trace. Those
// stay out of the event log, where a blinking caret alone would push out
// everything else. Later frames don't count, so a tap to read the result
// doesn't change it.
var returns returnTrace

const (
	returnWindow   = 3 * time.Second
	maxReturnLines = 60
)

type returnTrace struct {
	mu       sync.Mutex
	active   bool
	deadline time.Time // zero while in the background
	lines    []string
}

// left starts a new trip. switches says how the test is set up.
func (t *returnTrace) left(switches string) {
	t.mu.Lock()
	defer t.mu.Unlock()
	t.active = true
	t.deadline = time.Time{}
	t.lines = []string{switches}
}

// back starts the time that is left of the trip.
func (t *returnTrace) back(now time.Time) {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.active {
		t.deadline = now.Add(returnWindow)
	}
}

func (t *returnTrace) add(now time.Time, s string) {
	t.mu.Lock()
	defer t.mu.Unlock()
	if !t.active {
		return
	}
	if !t.deadline.IsZero() && now.After(t.deadline) {
		t.active = false
		t.lines = append(t.lines, "(end: 3 s after ForegroundEvent)")
		return
	}
	if len(t.lines) == maxReturnLines {
		t.lines = append(t.lines, "(cut: too many entries)")
	}
	if len(t.lines) > maxReturnLines {
		return
	}
	t.lines = append(t.lines, now.Format("15:04:05.000")+" "+s)
}

// text returns the entries, the oldest first.
func (t *returnTrace) text() []string {
	t.mu.Lock()
	defer t.mu.Unlock()
	return append([]string(nil), t.lines...)
}
