# shellcheck shell=bash
# Shared by the Linux package scripts (sourced, not run): linux.sh, deb.sh,
# rpm.sh, appimage.sh and linux-package-test.sh. Everything runs in Docker,
# for the architecture of the Docker host (amd64 or arm64).
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# The version of the packages, the one of the platform files (2.0.0, 7).
version=2.0.0
# The name of the program and of the packages.
pkg=gioplayground

if ! docker info >/dev/null 2>&1; then
	echo "Docker is not running" >&2
	exit 1
fi
case $(docker info --format '{{.Architecture}}') in
x86_64 | amd64) arch=amd64 rpmarch=x86_64 ;;
aarch64 | arm64) arch=arm64 rpmarch=aarch64 ;;
*)
	echo "Docker host architecture $(docker info --format '{{.Architecture}}') is not supported (amd64 or arm64)" >&2
	exit 1
	;;
esac

# The program and the packages, in build/.
bin=$root/build/$pkg-linux-$arch
# shellcheck disable=SC2034 # used by the scripts that source this
deb=$root/build/${pkg}_${version}_$arch.deb
# shellcheck disable=SC2034
rpm=$root/build/$pkg-$version-1.$rpmarch.rpm
# shellcheck disable=SC2034
appimage=$root/build/$pkg-$version-$rpmarch.AppImage

# The build image has the Go of the module's go line.
goversion=$(sed -n 's/^go //p' "$moddir/go.mod")
image=gioplayground-linux:go$goversion

# indocker runs the bash commands (the last argument) in the build image, with
# the repository at /src (read only) and build/ at /out; arguments before it go
# to docker run. The volumes keep Go's module and build caches for the next
# run. Files in /out belong to $OWNER (uid:gid) when the commands chown them.
indocker() {
	local cmd=${*: -1}
	docker build -t "$image" --build-arg GO_VERSION="$goversion" "$root/packaging/linux" >&2
	docker run --rm "${@:1:$#-1}" \
		-v "$root:/src:ro" -v "$root/build:/out" \
		-v gioplayground-linux-gomod:/go/pkg/mod -v gioplayground-linux-cache:/root/.cache \
		-e OWNER="$(id -u):$(id -g)" -e APP_ID="$APP_ID" \
		"$image" bash -euo pipefail -c "$cmd"
}

# needbin builds the program unless build/ has it already.
needbin() {
	if [ ! -f "$bin" ]; then
		"$root/scripts/linux.sh"
	fi
}

# stage writes to dir $1 the files the packages install, named as the
# package scripts expect them: the program (gioplayground), the desktop file
# (<APP_ID>.desktop) and the icon (<APP_ID>.png).
stage() {
	local dir=$1
	rm -rf "${dir:?}"
	mkdir -p "$dir"
	cp "$bin" "$dir/$pkg"
	chmod 755 "$dir/$pkg"
	sed -e "s|@APP_ID@|$APP_ID|g" "$root/packaging/linux/app.desktop" >"$dir/$APP_ID.desktop"
	cp "$root/packaging/linux/icon.png" "$dir/$APP_ID.png"
}
