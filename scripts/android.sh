#!/usr/bin/env bash
# Builds the Android app and installs it with adb:
#
#   scripts/android.sh [build|install|run|uninstall|log|smoke]
#
# install (the default) builds, installs (keeping the app's data) and starts
# the app; run only starts it; log follows the app's log. With more than one
# device, ANDROID_SERIAL picks one (adb devices lists them). smoke is for an
# emulator in CI: it installs the APK that build made, starts it, opens a
# URL and checks the log and the backup flag (scripts/check-log.sh).
. "$(dirname "$0")/lib.sh"

apk=$root/build/$APP_NAME-$GIO.apk

build() {
	local flags=(-target android -arch "${ANDROID_ARCH:-arm64}" -appid "$APP_ID" -name "$APP_NAME")
	local used
	if completefiles; then
		# The complete AndroidManifest.xml sets the version, the scheme, the
		# backup and the second activity; -appid only has to match it.
		flags+=(-platformdir "$(platformdir)")
		used=platformdir
	else
		flags+=(-schemes "$URL_SCHEME")
		used=schemes
	fi
	if [ -n "${ANDROID_SIGNKEY:-}" ]; then
		flags+=(-signkey "$ANDROID_SIGNKEY" -signpass "${ANDROID_SIGNPASS:-}")
	fi
	gogio "${flags[@]}" -ldflags "$(ldflags "$used")" -o "$apk" .
	echo "built $apk"
}

start() { adb shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null; }

smoke() {
	local here
	here=$(dirname "$0")
	# -d: upstream's version code (1) is lower than the fork's (7).
	adb install -r -d "$apk"
	adb logcat -c
	start
	# Gio writes the program's log to logcat with the app id as the tag.
	"$here/check-log.sh" "cmd:adb logcat -d -s $APP_ID" "$GIO" "window event loop started"
	adb shell am start -a android.intent.action.VIEW -d "$URL_SCHEME://hello" >/dev/null
	"$here/check-log.sh" "cmd:adb logcat -d -s $APP_ID" "$GIO" "URLEvent $URL_SCHEME://hello"
	local flags
	flags=$(adb shell dumpsys package "$APP_ID" | grep -E '^ +flags=' | head -n 1)
	echo "dumpsys package: $flags"
	if completefiles; then
		# platform/AndroidManifest.xml turns the backup off.
		case $flags in *ALLOW_BACKUP*)
			echo "FAIL: ALLOW_BACKUP is set, platform/AndroidManifest.xml turns it off" >&2
			exit 1
			;;
		esac
	else
		case $flags in *ALLOW_BACKUP*) ;; *)
			echo "FAIL: ALLOW_BACKUP is not set, gogio's manifest allows the backup" >&2
			exit 1
			;;
		esac
	fi
	echo "PASS: backup flag as the manifest says"
}

case ${1:-install} in
build) build ;;
install)
	build
	adb install -r "$apk"
	start
	;;
run) start ;;
smoke) smoke ;;
uninstall) adb uninstall "$APP_ID" ;;
log) adb logcat --pid="$(adb shell pidof "$APP_ID")" ;;
*)
	sed -n '2,11p' "$0" >&2
	exit 2
	;;
esac
