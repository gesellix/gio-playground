#!/usr/bin/env bash
# Builds the Windows program (on any system, gogio cross-compiles):
#
#   scripts/windows.sh [build]
#
# Copy build/<APP_NAME>-<GIO>.exe to a Windows computer and run it there.
# Its properties (Details tab) show the version information. WINDOWS_ARCH
# picks the architecture (amd64 by default, or arm64).
. "$(dirname "$0")/lib.sh"

arch=${WINDOWS_ARCH:-amd64}
exe=$root/build/$APP_NAME-$GIO.exe

build() {
	local flags=(-target windows -arch "$arch" -appid "$APP_ID" -name "$APP_NAME")
	if [ "$GIO" = platformdir ]; then
		# The complete file on Windows is a resource object with the
		# application manifest and the version information. Any tool can
		# make it; here go-winres builds rsrc_windows_<arch>.syso from
		# winres.json, next to the other platform files.
		local dir
		dir=$(platformdir)
		(cd "$moddir" && go tool go-winres make --in "$dir/winres.json" --arch "$arch" --out "$dir/rsrc")
		echo "made $dir/rsrc_windows_$arch.syso with go-winres"
		gogio "${flags[@]}" -platformdir "$dir" -schemes "$URL_SCHEME" -ldflags "$(ldflags platformdir,schemes)" -o "$exe" .
	else
		gogio "${flags[@]}" -schemes "$URL_SCHEME" -ldflags "$(ldflags schemes)" -o "$exe" .
	fi
	# gogio leaves its resource object (named after the program) in the
	# package directory, where a later go build would link it a second time.
	rm -f "$moddir/$APP_NAME-${GIO}_windows_$arch.syso"
	echo "built $exe"
}

case ${1:-build} in
build) build ;;
*)
	sed -n '2,8p' "$0" >&2
	exit 2
	;;
esac
