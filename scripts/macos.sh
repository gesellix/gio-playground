#!/usr/bin/env bash
# Builds the macOS app bundle and opens it:
#
#   scripts/macos.sh [build|run|log|smoke]
#
# run (the default) builds and opens the app; macOS registers its URL
# scheme then, so open gioplayground://hello reaches it. log follows the
# output of the app opened last by run. scripts/desktop.sh runs the
# program without a bundle, which has no URL scheme. smoke is for CI: it
# builds, checks the bundle (scripts/check-build.sh), opens the app with
# PLAYGROUND_LOG, opens a URL, checks the log and quits the app.
. "$(dirname "$0")/lib.sh"

app=$root/build/$APP_NAME-$GIO.app
out=$root/build/$APP_NAME-$GIO.log

build() {
	local arch
	case $(uname -m) in
	arm64) arch=arm64 ;;
	*) arch=amd64 ;;
	esac
	rm -rf "$app"
	local flags=(-target macos -arch "$arch" -appid "$APP_ID" -name "$APP_NAME")
	if completefiles; then
		# The complete Info.plist sets the version, the scheme and the
		# name of the executable.
		flags+=(-platformdir "$(platformdir)")
		gogio "${flags[@]}" -ldflags "$(ldflags platformdir)" -o "$app" .
	else
		gogio "${flags[@]}" -schemes "$URL_SCHEME" -ldflags "$(ldflags schemes)" -o "$app" .
	fi
	echo "built $app"
}

smoke() {
	build
	"$root/scripts/check-build.sh" "$app" "$GIO"
	local log=$root/build/$APP_NAME-$GIO-smoke.log
	rm -f "$log"
	open -n --env "PLAYGROUND_LOG=$log" "$app"
	# The URL goes to this bundle: every build has the same app id, and
	# for a plain open of the URL macOS picks any bundle that has it.
	local ok=0
	"$root/scripts/check-log.sh" "$log" "$GIO" "window event loop started" &&
		open -a "$app" "$URL_SCHEME://hello" &&
		"$root/scripts/check-log.sh" "$log" "$GIO" "URLEvent $URL_SCHEME://hello" || ok=$?
	pkill -f "$app/Contents/MacOS/" || true
	return $ok
}

case ${1:-run} in
build) build ;;
smoke) smoke ;;
run)
	build
	open --stdout "$out" --stderr "$out" "$app"
	echo "opened $app, its output goes to $out"
	;;
log) tail -f "$out" ;;
*)
	sed -n '2,12p' "$0" >&2
	exit 2
	;;
esac
