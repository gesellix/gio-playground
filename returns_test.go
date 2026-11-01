package playground

import (
	"strings"
	"testing"
	"time"
)

func TestReturnTraceKeepsOneTrip(t *testing.T) {
	var r returnTrace
	now := time.Date(2026, 11, 1, 12, 0, 0, 0, time.UTC)

	r.add(now, "before the first trip")
	if got := r.text(); len(got) != 0 {
		t.Fatalf("recorded without a trip: %q", got)
	}

	r.left("switches")
	r.add(now, "BackgroundEvent")
	r.add(now.Add(time.Hour), "dropped draw, long in the background")
	r.back(now.Add(time.Hour))
	r.add(now.Add(time.Hour+returnWindow), "last frame")
	r.add(now.Add(time.Hour+returnWindow+time.Millisecond), "the tap to read it")
	r.add(now.Add(time.Hour+returnWindow+time.Second), "another tap")

	got := strings.Join(r.text(), "\n")
	for _, want := range []string{"switches", "BackgroundEvent", "dropped draw", "last frame", "(end:"} {
		if !strings.Contains(got, want) {
			t.Errorf("no %q in:\n%s", want, got)
		}
	}
	for _, not := range []string{"tap", "before the first"} {
		if strings.Contains(got, not) {
			t.Errorf("%q in:\n%s", not, got)
		}
	}

	r.left("next")
	if got := r.text(); len(got) != 1 || got[0] != "next" {
		t.Errorf("a new trip keeps the old one: %q", got)
	}
}

func TestReturnTraceIsCut(t *testing.T) {
	var r returnTrace
	now := time.Date(2026, 11, 1, 12, 0, 0, 0, time.UTC)
	r.left("switches")
	for range 2 * maxReturnLines {
		r.add(now, "frame")
	}
	got := r.text()
	if len(got) != maxReturnLines+1 || !strings.Contains(got[maxReturnLines], "cut") {
		t.Errorf("%d lines, the last %q", len(got), got[len(got)-1])
	}
}
