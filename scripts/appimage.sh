#!/usr/bin/env bash
# Packages the Linux program as an AppImage, in Docker:
#
#   scripts/appimage.sh [build]
#
# Writes build/gioplayground-<version>-<arch>.AppImage (x86_64 or aarch64) and
# builds the program with scripts/linux.sh first if build/ does not have it.
# appimagetool and the AppImage runtime are pinned releases, checked by sha256
# and kept in build/linux-tools/; appimagetool itself runs without network.
#
# No libraries are bundled: the AppImage relies on the system for all of them,
# like the program does. Of the libraries it links, the AppImage exclude list
# (libraries assumed on every system, which linuxdeploy never bundles) has
# libc, libX11, libX11-xcb, libwayland-client and libEGL; the rest
# (libwayland-egl, libwayland-cursor, libxkbcommon, libxkbcommon-x11,
# libXcursor, libXfixes) belong to the same X11 and Wayland stacks and are on
# every desktop that has those. Bundling them would mix their versions with
# the system's libwayland-client and libX11. OpenGL ES and Vulkan, which Gio
# loads with dlopen, come with the graphics driver and are never bundled. So
# the AppImage needs glibc 2.34 or later and a desktop; the test
# (scripts/linux-package-test.sh appimage) installs just these libraries.
. "$(dirname "$0")/linux-lib.sh"

# https://github.com/AppImage/appimagetool/releases/tag/1.9.1
appimagetool_version=1.9.1
# https://github.com/AppImage/type2-runtime/releases/tag/20251108, passed with
# --runtime-file: without it, appimagetool downloads the latest one.
runtime_version=20251108
case $rpmarch in
x86_64)
	appimagetool_sha256=ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
	runtime_sha256=2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d
	;;
aarch64)
	appimagetool_sha256=f0837e7448a0c1e4e650a93bb3e85802546e60654ef287576f46c71c126a9158
	runtime_sha256=00cbdfcf917cc6c0ff6d3347d59e0ca1f7f45a6df1a428a0d6d8a78664d87444
	;;
esac

build() {
	needbin
	stage "$root/build/linux-stage"
	local tools=linux-tools
	local tool=$tools/appimagetool-$appimagetool_version-$rpmarch.AppImage
	local runtime=$tools/runtime-$runtime_version-$rpmarch
	# download fetches URL $2 to /out/$1, unless it is there, and checks
	# its sha256 $3.
	indocker "
		download() {
			if [ ! -f /out/\$1 ]; then
				curl -fsSL -o /out/\$1.part \"\$2\"
				mv /out/\$1.part /out/\$1
			fi
			echo \"\$3  /out/\$1\" | sha256sum -c -
		}
		mkdir -p /out/$tools
		download $tool https://github.com/AppImage/appimagetool/releases/download/$appimagetool_version/appimagetool-$rpmarch.AppImage $appimagetool_sha256
		download $runtime https://github.com/AppImage/type2-runtime/releases/download/$runtime_version/runtime-$rpmarch $runtime_sha256
		chown -R \"\$OWNER\" /out/$tools"
	indocker --network none "
		d=/tmp/AppDir
		install -D -m 755 /out/linux-stage/$pkg \$d/usr/bin/$pkg
		install -D -m 644 /out/linux-stage/\$APP_ID.desktop \$d/usr/share/applications/\$APP_ID.desktop
		install -D -m 644 /out/linux-stage/\$APP_ID.png \$d/usr/share/icons/hicolor/256x256/apps/\$APP_ID.png
		cp /out/linux-stage/\$APP_ID.desktop /out/linux-stage/\$APP_ID.png \$d/
		ln -s usr/bin/$pkg \$d/AppRun
		cp /out/$tool /tmp/appimagetool && chmod 755 /tmp/appimagetool
		# No FUSE in a container: appimagetool, an AppImage itself, unpacks
		# itself to run.
		ARCH=$rpmarch /tmp/appimagetool --appimage-extract-and-run --no-appstream \
			--runtime-file /out/$runtime \$d /out/$(basename "$appimage")
		chown \"\$OWNER\" /out/$(basename "$appimage")"
	echo "built $appimage"
}

case ${1:-build} in
build) build ;;
*)
	sed -n '2,21p' "$0" >&2
	exit 2
	;;
esac
