#!/usr/bin/env bash
# Packages the Linux program as a .deb, in Docker:
#
#   scripts/deb.sh [build]
#
# Writes build/gioplayground_<version>_<arch>.deb and builds the program with
# scripts/linux.sh first if build/ does not have it. The dependencies come
# from the program: dpkg-shlibdeps maps each shared library it links to its
# package (of Debian 12, the build image, so the versions are old enough for
# newer systems). Gio loads OpenGL ES and Vulkan with dlopen, which no tool
# sees: libgles2 is a dependency (Gio draws with OpenGL ES when Vulkan is not
# there) and libvulkan1 is recommended.
. "$(dirname "$0")/linux-lib.sh"

build() {
	needbin
	stage "$root/build/linux-stage"
	indocker "
		r=/tmp/src/debian/$pkg
		install -D -m 755 /out/linux-stage/$pkg \$r/usr/bin/$pkg
		install -D -m 644 /out/linux-stage/\$APP_ID.desktop \$r/usr/share/applications/\$APP_ID.desktop
		install -D -m 644 /out/linux-stage/\$APP_ID.png \$r/usr/share/icons/hicolor/256x256/apps/\$APP_ID.png
		# dpkg-shlibdeps wants a source package (debian/control) and finds
		# the root of the package by its DEBIAN directory.
		mkdir -p \$r/DEBIAN /tmp/src/debian && cd /tmp/src && echo 'Source: $pkg' >debian/control
		deps=\$(dpkg-shlibdeps -O -edebian/$pkg/usr/bin/$pkg | sed -n 's/^shlibs:Depends=//p')
		echo \"dpkg-shlibdeps: \$deps\"
		cat >\$r/DEBIAN/control <<CONTROL
Package: $pkg
Version: $version
Architecture: $arch
Maintainer: Tobias Gesellchen <tobias@gesellix.de>
Installed-Size: \$(du -sk --exclude=DEBIAN \$r | cut -f1)
Depends: \$deps, libgles2
Recommends: libvulkan1
Section: devel
Priority: optional
Homepage: https://github.com/gesellix/gio-playground
Description: Tries out patches to Gio, gio-x and gogio
 A small Gio program to try out patches to Gio, gio-x and gogio, and to
 show what they change. An event log records what the program receives.
CONTROL
		dpkg-deb --root-owner-group --build \$r /out/$(basename "$deb")
		chown \"\$OWNER\" /out/$(basename "$deb")
		dpkg-deb --field /out/$(basename "$deb") Depends Recommends"
	echo "built $deb"
}

case ${1:-build} in
build) build ;;
*)
	sed -n '2,13p' "$0" >&2
	exit 2
	;;
esac
