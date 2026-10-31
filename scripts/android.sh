#!/usr/bin/env bash
# Builds the Android app and installs it with adb:
#
#   scripts/android.sh [build|install|run|uninstall|log]
#
# install (the default) builds, installs (keeping the app's data) and starts
# the app; run only starts it; log follows the app's log. With more than one
# device, ANDROID_SERIAL picks one (adb devices lists them).
. "$(dirname "$0")/lib.sh"

apk=$root/build/$APP_NAME-$GIO.apk

build() {
	local flags=(-target android -arch "${ANDROID_ARCH:-arm64}" -appid "$APP_ID" -name "$APP_NAME")
	local used
	case $GIO in
	platformdir)
		# The complete AndroidManifest.xml sets the version, the scheme and
		# the backup; -appid only has to match it.
		flags+=(-platformdir "$(platformdir)")
		used=platformdir
		;;
	fork)
		flags+=(-schemes "$URL_SCHEME" -manifest "$root/android/manifest.xml")
		used=schemes,manifest
		;;
	*)
		flags+=(-schemes "$URL_SCHEME")
		used=schemes
		;;
	esac
	if [ -n "${ANDROID_SIGNKEY:-}" ]; then
		flags+=(-signkey "$ANDROID_SIGNKEY" -signpass "${ANDROID_SIGNPASS:-}")
	fi
	gogio "${flags[@]}" -ldflags "$(ldflags "$used")" -o "$apk" .
	echo "built $apk"
}

start() { adb shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null; }

case ${1:-install} in
build) build ;;
install)
	build
	adb install -r "$apk"
	start
	;;
run) start ;;
uninstall) adb uninstall "$APP_ID" ;;
log) adb logcat --pid="$(adb shell pidof "$APP_ID")" ;;
*)
	sed -n '2,9p' "$0" >&2
	exit 2
	;;
esac
