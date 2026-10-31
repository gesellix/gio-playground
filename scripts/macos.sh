#!/usr/bin/env bash
# Builds the macOS app bundle and opens it:
#
#   scripts/macos.sh [build|run|log]
#
# run (the default) builds and opens the app; macOS registers its URL
# scheme then, so open gioplayground://hello reaches it. log follows the
# output of the app opened last by run. scripts/desktop.sh runs the
# program without a bundle, which has no URL scheme.
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
	if [ "$GIO" = platformdir ]; then
		# The complete Info.plist sets the version, the scheme and the
		# name of the executable.
		flags+=(-platformdir "$(platformdir)")
		gogio "${flags[@]}" -ldflags "$(ldflags platformdir)" -o "$app" .
	else
		gogio "${flags[@]}" -schemes "$URL_SCHEME" -ldflags "$(ldflags schemes)" -o "$app" .
	fi
	echo "built $app"
}

case ${1:-run} in
build) build ;;
run)
	build
	open --stdout "$out" --stderr "$out" "$app"
	echo "opened $app, its output goes to $out"
	;;
log) tail -f "$out" ;;
*)
	sed -n '2,10p' "$0" >&2
	exit 2
	;;
esac
