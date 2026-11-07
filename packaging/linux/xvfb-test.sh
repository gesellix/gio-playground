#!/usr/bin/env bash
# Runs in the test containers of scripts/linux-package-test.sh: starts Xvfb,
# runs the command (the arguments) on it and waits for the program's first
# frame in its log file $LOG (the program writes it with PLAYGROUND_LOG).
# Fails when no frame comes within $TIMEOUT seconds (60 by default), when the
# program stops before that or within 2 seconds after it (a FrameEvent comes
# before the frame is drawn; when drawing fails, Gio ends the window), or
# when the log or the output has a panic.
set -euo pipefail

: "${LOG:?LOG is the log file of the program}"
timeout=${TIMEOUT:-60}
out=/tmp/program-output.txt

Xvfb :99 -screen 0 1024x768x24 -nolisten tcp >/tmp/xvfb.txt 2>&1 &
for _ in $(seq 50); do
	[ -S /tmp/.X11-unix/X99 ] && break
	sleep 0.1
done
if [ ! -S /tmp/.X11-unix/X99 ]; then
	echo "Xvfb did not start:" >&2
	cat /tmp/xvfb.txt >&2
	exit 1
fi
export DISPLAY=:99

"$@" >"$out" 2>&1 &
pid=$!
ok=false
for _ in $(seq $((timeout * 2))); do
	if grep -q FrameEvent "$LOG" 2>/dev/null; then
		ok=true
		break
	fi
	kill -0 "$pid" 2>/dev/null || break
	sleep 0.5
done
# A moment more for a failure right after the first frame.
running=false
if $ok; then
	sleep 2
	kill -0 "$pid" 2>/dev/null && running=true
fi
# Which of the graphics libraries that Gio loads with dlopen (Vulkan, OpenGL
# ES) and which drivers of Mesa are in a process now: the program's, or with
# flatpak its sandboxed child.
gfx=$(cat /proc/[0-9]*/maps 2>/dev/null | grep -o -E '[^/ ]*(libvulkan|libGLESv2|libEGL_mesa|libgallium|_dri\.so|lvp)[^/ ]*$' | sort -u | tr '\n' ' ' || true)
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true

echo "--- log ($LOG)"
cat "$LOG" 2>/dev/null || echo "(no log)"
echo "--- output"
cat "$out"
echo "--- graphics libraries loaded: ${gfx:-none}"
if grep -q panic "$LOG" "$out" 2>/dev/null; then
	echo "FAIL: panic" >&2
	exit 1
fi
if ! $ok; then
	echo "FAIL: no FrameEvent within ${timeout}s" >&2
	exit 1
fi
if ! $running; then
	echo "FAIL: the program stopped after its first FrameEvent" >&2
	exit 1
fi
echo "PASS: $(grep -m1 FrameEvent "$LOG")"
