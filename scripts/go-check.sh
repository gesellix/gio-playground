#!/usr/bin/env bash
# Runs go vet for every module and the tests, for this system or for a
# mobile target:
#
#   scripts/go-check.sh            vet and test for this system
#   scripts/go-check.sh android    vet for android/arm64, with the NDK's clang
#   scripts/go-check.sh ios        vet for ios/arm64, with Xcode's clang
#
# Gio needs cgo on Linux, Android and iOS, so go vet needs the C compiler
# of the target: for android the newest NDK below ANDROID_HOME/ndk (or
# ANDROID_NDK_LATEST_HOME, which the CI runner sets), for ios the iPhone SDK
# of Xcode. The tests only run for this system.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
target=${1:-}

case $target in
'') ;;
android)
	ndk=${ANDROID_NDK_LATEST_HOME:-}
	if [ -z "$ndk" ]; then
		ndk=$(find "${ANDROID_HOME:?ANDROID_HOME is not set}/ndk" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)
	fi
	cc=$(find "$ndk/toolchains/llvm/prebuilt" -name aarch64-linux-android24-clang | head -n 1)
	[ -n "$cc" ] || { echo "no aarch64-linux-android24-clang in $ndk" >&2; exit 2; }
	export CGO_ENABLED=1 GOOS=android GOARCH=arm64 CC=$cc
	;;
ios)
	sdk=$(xcrun --sdk iphoneos --show-sdk-path)
	export CGO_ENABLED=1 GOOS=ios GOARCH=arm64
	clang=$(xcrun --sdk iphoneos --find clang)
	export CC="$clang -isysroot $sdk -arch arm64 -miphoneos-version-min=13.0"
	;;
*)
	sed -n '2,13p' "$0" >&2
	exit 2
	;;
esac

for m in . fork diag upstream; do
	echo "== go vet $m ${GOOS:-}"
	(cd "$root/$m" && go vet ./...)
done
if [ -z "$target" ]; then
	(cd "$root" && go test ./...)
fi
