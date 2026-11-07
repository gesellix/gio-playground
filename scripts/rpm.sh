#!/usr/bin/env bash
# Packages the Linux program as an .rpm, in Docker (Fedora 42):
#
#   scripts/rpm.sh [build]
#
# Writes build/gioplayground-<version>-1.<arch>.rpm (x86_64 or aarch64) and
# builds the program with scripts/linux.sh first if build/ does not have it.
# rpmbuild declares the shared libraries the program links as Requires (by
# soname); packaging/linux/gioplayground.spec adds what Gio loads with dlopen,
# which rpmbuild does not see: OpenGL ES (libglvnd-gles) as Requires, Vulkan
# (vulkan-loader) as Recommends.
. "$(dirname "$0")/linux-lib.sh"

rpmimage=gioplayground-rpm:fedora42

build() {
	needbin
	stage "$root/build/linux-stage"
	docker build -t "$rpmimage" -f "$root/packaging/linux/rpm.Dockerfile" "$root/packaging/linux" >&2
	docker run --rm -v "$root:/src:ro" -v "$root/build:/out" -e OWNER="$(id -u):$(id -g)" \
		"$rpmimage" bash -euo pipefail -c "
		rpmbuild -bb --quiet --define '_topdir /tmp/rpm' --define 'pkgversion $version' \
			--define 'appid $APP_ID' --define 'srcdir /out/linux-stage' \
			/src/packaging/linux/gioplayground.spec
		cp /tmp/rpm/RPMS/$rpmarch/$(basename "$rpm") /out/
		chown \"\$OWNER\" /out/$(basename "$rpm")
		echo Requires:; rpm -qp --requires /out/$(basename "$rpm") | sed 's/^/  /'
		echo Recommends:; rpm -qp --recommends /out/$(basename "$rpm") | sed 's/^/  /'"
	echo "built $rpm"
}

case ${1:-build} in
build) build ;;
*)
	sed -n '2,11p' "$0" >&2
	exit 2
	;;
esac
