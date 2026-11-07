#!/usr/bin/env bash
# Starts the program on Wayland under Mutter, GNOME's compositor, headless,
# and checks that it gets its Wayland view, a configuration and a frame:
#
#   GIO=fork scripts/wayland-check.sh
#
# Mutter has no xdg-decoration, so Gio draws the title bar itself, as under
# GNOME (DecorationColors colours it in the fork's build). The check sees the
# start, not the pixels of the title bar.
#
# Linux with Mutter, dbus and Gio's build packages runs it directly (the CI
# runner). Elsewhere it runs itself in Docker (indocker in lib.sh).
set -euo pipefail

. "$(dirname "$0")/lib.sh"

if [ "$(uname -s)" != Linux ] || [ "${IN_DOCKER:-}" = 1 ]; then
	indocker wayland-check.sh
fi

bin=$root/build/wayland-$GIO
(cd "$moddir" && go build -o "$bin" .)
log=$root/build/wayland-$GIO.log
rm -f "$log"

runtime=$(mktemp -d)
chmod 700 "$runtime"
export XDG_RUNTIME_DIR=$runtime
unset DISPLAY

# One session bus for Mutter and the program; the inner script starts the
# compositor, waits for its socket and runs the program until the check
# ends.
export bin log root GIO
dbus-run-session -- bash -c '
	set -euo pipefail
	mutter --wayland --headless --no-x11 --virtual-monitor 1024x768 \
		--wayland-display=wayland-check >"$root/build/wayland-mutter.log" 2>&1 &
	mutter=$!
	for _ in $(seq 1 30); do
		[ -S "$XDG_RUNTIME_DIR/wayland-check" ] && break
		sleep 1
	done
	WAYLAND_DISPLAY=wayland-check PLAYGROUND_LOG=$log "$bin" >/dev/null 2>&1 &
	pid=$!
	ok=0
	"$root/scripts/check-log.sh" "$log" "$GIO" "WaylandViewEvent valid=true" "ConfigEvent " || ok=$?
	kill "$pid" "$mutter" 2>/dev/null || true
	exit $ok
'
