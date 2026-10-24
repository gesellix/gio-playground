#!/usr/bin/env bash
# Builds the iOS app and installs it on a device with devicectl (Xcode):
#
#   scripts/ios.sh [build|install|run|uninstall|devices|profiles]
#
# install (the default) builds, installs and starts the app; run only
# starts it. IOS_DEVICE names the device (devices lists them), IOS_SIGNKEY
# the provisioning profile (profiles lists them, with their app ids).
. "$(dirname "$0")/lib.sh"

ipa=$root/build/$APP_NAME-$GIO.ipa

need() {
	if [ -z "${!1:-}" ]; then
		echo "$1 is not set (.env, see .env-example): $2" >&2
		exit 2
	fi
}

build() {
	need IOS_SIGNKEY "the path of the provisioning profile, see scripts/ios.sh profiles"
	# gogio's default minimum (iOS 10) no longer links with current Xcode
	# versions: their SDKs have no libarclite.
	local flags=(-target ios -minsdk "${IOS_MINSDK:-15}" -appid "$APP_ID" -name "$APP_NAME" -schemes "$URL_SCHEME" -signkey "$IOS_SIGNKEY")
	local used=schemes
	if [ "$GIO" = fork ]; then
		flags+=(-plist "$root/ios/scene.plist" -privacymanifest "$root/ios/PrivacyInfo.xcprivacy")
		used+=,plist,privacymanifest
	else
		echo "note: upstream gogio cannot add the scene manifest; built with the iOS 27 SDK or later, the app closes right after launch (TN3187)" >&2
	fi
	gogio "${flags[@]}" -ldflags "$(ldflags "$used")" -o "$ipa" .
	echo "built $ipa"
}

start() {
	need IOS_DEVICE "the device, see scripts/ios.sh devices"
	xcrun devicectl device process launch --device "$IOS_DEVICE" "$APP_ID"
}

case ${1:-install} in
build) build ;;
install)
	build
	need IOS_DEVICE "the device, see scripts/ios.sh devices"
	xcrun devicectl device install app --device "$IOS_DEVICE" "$ipa"
	start
	;;
run) start ;;
uninstall)
	need IOS_DEVICE "the device, see scripts/ios.sh devices"
	xcrun devicectl device uninstall app --device "$IOS_DEVICE" "$APP_ID"
	;;
devices) xcrun devicectl list devices ;;
profiles)
	# Xcode keeps the profiles in one of two folders, depending on its
	# version; gogio only looks in the first one without -signkey.
	tmp=$(mktemp)
	trap 'rm -f "$tmp"' EXIT
	for dir in "$HOME/Library/MobileDevice/Provisioning Profiles" "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"; do
		for f in "$dir"/*.mobileprovision; do
			[ -e "$f" ] || continue
			security cms -D -i "$f" -o "$tmp" 2>/dev/null || continue
			pb() { /usr/libexec/PlistBuddy -c "Print:$1" "$tmp" 2>/dev/null; }
			echo "$f"
			echo "    $(pb Name) | app id $(pb Entitlements:application-identifier) | expires $(pb ExpirationDate)"
		done
	done
	;;
*)
	sed -n '2,9p' "$0" >&2
	exit 2
	;;
esac
