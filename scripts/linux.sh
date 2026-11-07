#!/usr/bin/env bash
# Builds the Linux program in Docker, for the architecture of the Docker host:
#
#   scripts/linux.sh [build]
#
# The program goes to build/gioplayground-linux-<arch> (amd64 or arm64), built
# from the module of GIO (fork by default). The image is Debian 12 with the Go
# of the module's go line (packaging/linux/Dockerfile), so the program needs
# glibc 2.34 or later and runs on Ubuntu 24.04 and Fedora 42. The packages of
# deb.sh, rpm.sh and appimage.sh take this file.
. "$(dirname "$0")/linux-lib.sh"

build() {
	indocker "cd /src/$GIO && go build -trimpath -buildvcs=false -ldflags '$(ldflags none)' -o /out/$(basename "$bin") .
		chown \"\$OWNER\" /out/$(basename "$bin")
		echo needs:; readelf -d /out/$(basename "$bin") | sed -n 's/.*(NEEDED).*\[\(.*\)\]/  \1/p'
		echo newest glibc symbol: \$(objdump -T /out/$(basename "$bin") | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1)"
	echo "built $bin"
}

case ${1:-build} in
build) build ;;
*)
	sed -n '2,10p' "$0" >&2
	exit 2
	;;
esac
