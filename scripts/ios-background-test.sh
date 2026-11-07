#!/usr/bin/env bash
# Answers on the device: how often does UIKit call the background and foreground
# callbacks of GioViewController, also at launch and with two views, and what
# happens when Gio draws in the background? Needs the iPhone connected and
# unlocked, nothing else: Safari in front sends the app to the background.
#
#   scripts/ios-background-test.sh [outdir]
#
# Each test starts a new process and leaves its log in outdir/<test>.log. A
# copy that fails means the process did not get as far as writing its log.
export GIO=diag
. "$(dirname "$0")/lib.sh"

: "${IOS_DEVICE:?IOS_DEVICE is not set, see scripts/ios.sh devices}"
out=${1:-$root/build/background-test}
mkdir -p "$out"
safari=com.apple.mobilesafari

launch() { xcrun devicectl device process launch --device "$IOS_DEVICE" "$@" >>"$out/devicectl.log" 2>&1; }
open_app() { launch "$APP_ID"; sleep 3; }
open_url() { launch --payload-url "$URL_SCHEME://$1" "$APP_ID"; sleep "${2:-3}"; }
restart() { launch --terminate-existing "$@" "$APP_ID"; sleep 3; }
leave() { launch "$safari"; sleep "${1:-3}"; }
save() {
	xcrun devicectl device copy from --device "$IOS_DEVICE" --domain-type appDataContainer \
		--domain-identifier "$APP_ID" --source Documents/playground.log --destination "$out/$1.log" >>"$out/devicectl.log" 2>&1 ||
		echo "$1: no log copied" | tee -a "$out/summary.txt"
	echo "== $1: process running: $(xcrun devicectl device info processes --device "$IOS_DEVICE" 2>/dev/null | grep -c "$APP_NAME")" | tee -a "$out/summary.txt"
}

"$root/scripts/ios.sh" install

# Launch by the icon, then one trip.
restart
save 1-launch
leave
open_app
save 1-launch-and-trip

# Launch by a URL.
restart --payload-url "$URL_SCHEME://hello"
save 2-url-launch

# Two views, one trip.
restart
open_url 'diag?second-view=open'
leave
open_app
save 3-two-views

# The scene goes away and comes back, then one trip.
restart
open_url 'diag?disconnect=scene'
open_app
leave
open_app
save 4-scene-reconnected

# A frame is pending while in the background, draw() stops as it should.
restart
open_url 'diag?invalidate=on'
leave 15
open_app
save 5-background-gate-on

# The same without the check in draw(). This one may end the process.
restart
open_url 'diag?invalidate=on&background-draw=on'
leave 15
open_app
save 6-background-draw

echo "logs in $out"
