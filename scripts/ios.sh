#!/usr/bin/env bash
# Builds the iOS app and installs it on a device with devicectl (Xcode):
#
#   scripts/ios.sh [build|install|run|uninstall|devices|profiles]
#
# install (the default) builds, installs and starts the app; run only
# starts it. IOS_DEVICE names the device (devices lists them). IOS_SIGNKEY
# may name the provisioning profile (profiles lists them, with their app
# ids); without it the build takes the valid profile for APP_ID that
# expires last, as Xcode replaces the profile (and its file name) when it
# renews it.
. "$(dirname "$0")/lib.sh"

ipa=$root/build/$APP_NAME-$GIO.ipa

need() {
	if [ -z "${!1:-}" ]; then
		echo "$1 is not set (.env, see .env-example): $2" >&2
		exit 2
	fi
}

# each_profile calls $1 with the file, name, app id and expiration date
# (ISO 8601, UTC) of each provisioning profile. Xcode keeps them in one of
# two folders, depending on its version; gogio only looks in the first one
# without -signkey.
each_profile() {
	local tmp dir f
	tmp=$(mktemp)
	for dir in "$HOME/Library/MobileDevice/Provisioning Profiles" "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"; do
		for f in "$dir"/*.mobileprovision; do
			[ -e "$f" ] || continue
			security cms -D -i "$f" -o "$tmp" 2>/dev/null || continue
			"$1" "$f" \
				"$(plutil -extract Name raw -o - "$tmp" 2>/dev/null)" \
				"$(plutil -extract Entitlements.application-identifier raw -o - "$tmp" 2>/dev/null)" \
				"$(plutil -extract ExpirationDate raw -o - "$tmp" 2>/dev/null)"
		done
	done
	rm -f "$tmp"
}

# signkey prints IOS_SIGNKEY if its file exists, else the profile for
# APP_ID (team prefix plus the app id, or a wildcard) that is still valid
# and expires last.
signkey() {
	if [ -n "${IOS_SIGNKEY:-}" ]; then
		if [ -f "$IOS_SIGNKEY" ]; then
			echo "$IOS_SIGNKEY"
			return
		fi
		echo "IOS_SIGNKEY $IOS_SIGNKEY does not exist, looking for a profile for $APP_ID" >&2
	fi
	local now best="" bestexp=""
	now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
	pick() {
		case $3 in *".$APP_ID" | *".*") ;; *) return ;; esac
		[[ $4 > $now ]] || return 0
		if [[ $4 > $bestexp ]]; then
			best=$1
			bestexp=$4
		fi
	}
	each_profile pick
	if [ -z "$best" ]; then
		echo "no valid provisioning profile for $APP_ID, see scripts/ios.sh profiles" >&2
		exit 2
	fi
	echo "using $best (expires $bestexp)" >&2
	echo "$best"
}

build() {
	local key
	key=$(signkey)
	local flags=(-target ios -appid "$APP_ID" -name "$APP_NAME" -signkey "$key")
	local used
	local minsdk=${IOS_MINSDK:-}
	if [ "$GIO" = platformdir ]; then
		# The complete Info.plist sets the version, the scheme and
		# MinimumOSVersion; -appid only has to match it.
		flags+=(-platformdir "$(platformdir)")
		gogio "${flags[@]}" -ldflags "$(ldflags platformdir)" -o "$ipa" .
		echo "built $ipa"
		return
	fi
	flags+=(-schemes "$URL_SCHEME")
	used=schemes
	# gogio writes the scene manifest itself, and without -minsdk it
	# builds for iOS 13 (upstream since c57ee40).
	if [ "$GIO" = fork ]; then
		flags+=(-privacymanifest "$root/ios/PrivacyInfo.xcprivacy")
		used+=,privacymanifest
	fi
	if [ -n "$minsdk" ]; then
		flags+=(-minsdk "$minsdk")
		used+=,minsdk
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
	show() { printf '%s\n    %s | app id %s | expires %s\n' "$@"; }
	each_profile show
	;;
*)
	sed -n '2,9p' "$0" >&2
	exit 2
	;;
esac
