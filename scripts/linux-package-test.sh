#!/usr/bin/env bash
# Installs a Linux package in a clean container and checks that the program
# shows its first frame there:
#
#   scripts/linux-package-test.sh deb|rpm|appimage|flatpak
#
# deb and appimage run in ubuntu:24.04, rpm in fedora:42, flatpak in
# ubuntu:24.04 with --privileged (bubblewrap, the sandbox of flatpak, needs
# it in a container). The package is built first if build/ does not have it
# (scripts/deb.sh, rpm.sh, appimage.sh, flatpak.sh build).
#
# apt or dnf installs only the package, so that its declared dependencies are
# what makes it run; the test lists what came with it. No Mesa driver is added:
# the dependencies pull Mesa's EGL with its software renderer (Ubuntu:
# libegl-mesa0, mesa-libgallium; Fedora: mesa-libEGL, mesa-dri-drivers), which
# is what Gio draws with under Xvfb. Xvfb comes after the list; on Ubuntu it
# brings libgl1-mesa-dri for itself, which the program does not need (it
# shows its frame with that package removed, too). Then
# packaging/linux/xvfb-test.sh starts the program with PLAYGROUND_LOG, waits up
# to $TIMEOUT seconds (60) for a FrameEvent in the log, fails on a panic,
# without a frame or when the program ends after it (it does when OpenGL ES
# is missing), and prints the log and the graphics libraries it loaded.
#
# The AppImage declares no dependencies: the test installs the libraries it
# links (and libgles2, which Gio loads with dlopen), as a desktop has them,
# without Recommends, and runs it with --appimage-extract-and-run (no FUSE in
# a container). The flatpak test gets the runtime from Flathub and runs the
# app with dbus-run-session and a system bus, which flatpak run asks for.
#
# Every test prints PASS or FAIL last and exits 0 only on PASS.
. "$(dirname "$0")/linux-lib.sh"

kind=${1:-}
timeout=${TIMEOUT:-60}

# The setup lines that every test container runs first: a list of the
# installed packages before and after the package, to show what came with it.
listpkgs="dpkg-query -W -f '\${Package}\n' | sort"
apt='export DEBIAN_FRONTEND=noninteractive; apt-get update -qq'

case $kind in
deb)
	[ -f "$deb" ] || "$root/scripts/deb.sh"
	file=$(basename "$deb")
	img=ubuntu:24.04
	setup="$apt
		$listpkgs >/tmp/before
		apt-get install -y -qq /pkgs/$file >/dev/null
		$listpkgs >/tmp/after
		echo \"installed with $file: \$(comm -13 /tmp/before /tmp/after | tr '\n' ' ')\"
		apt-get install -y -qq --no-install-recommends xvfb >/dev/null"
	run="LOG=/tmp/playground.log PLAYGROUND_LOG=/tmp/playground.log /tests/xvfb-test.sh $pkg"
	;;
rpm)
	[ -f "$rpm" ] || "$root/scripts/rpm.sh"
	file=$(basename "$rpm")
	img=fedora:42
	listpkgs='rpm -qa --qf "%{NAME}\n" | sort'
	setup="$listpkgs >/tmp/before
		dnf install -y -q /pkgs/$file >/dev/null
		$listpkgs >/tmp/after
		echo \"installed with $file: \$(comm -13 /tmp/before /tmp/after | tr '\n' ' ')\"
		dnf install -y -q --setopt=install_weak_deps=False xorg-x11-server-Xvfb >/dev/null"
	run="LOG=/tmp/playground.log PLAYGROUND_LOG=/tmp/playground.log /tests/xvfb-test.sh $pkg"
	;;
appimage)
	[ -f "$appimage" ] || "$root/scripts/appimage.sh"
	file=$(basename "$appimage")
	img=ubuntu:24.04
	# The libraries the program links (readelf -d, NEEDED) and libgles2.
	libs='libegl1 libgles2 libwayland-client0 libwayland-cursor0 libwayland-egl1 libx11-6 libx11-xcb1 libxcursor1 libxfixes3 libxkbcommon0 libxkbcommon-x11-0'
	setup="$apt
		$listpkgs >/tmp/before
		apt-get install -y -qq --no-install-recommends $libs >/dev/null
		$listpkgs >/tmp/after
		echo \"installed for $file: \$(comm -13 /tmp/before /tmp/after | tr '\n' ' ')\"
		apt-get install -y -qq --no-install-recommends xvfb >/dev/null
		cp /pkgs/$file /tmp/ && chmod 755 /tmp/$file
		cd /tmp && ./$file --appimage-extract >/dev/null
		if ldd squashfs-root/usr/bin/$pkg | grep 'not found'; then exit 1; fi
		echo 'ldd: all libraries found'"
	run="LOG=/tmp/playground.log PLAYGROUND_LOG=/tmp/playground.log /tests/xvfb-test.sh /tmp/$file --appimage-extract-and-run"
	;;
flatpak)
	[ -f "$root/build/gioplayground.flatpak" ] || "$root/scripts/flatpak.sh" build
	file=gioplayground.flatpak
	img=ubuntu:24.04
	# The app id of flatpak/, and a log in the app's own directory, which
	# the sandbox can write.
	app=org.example.gioplayground
	log=/root/.var/app/$app/playground.log
	setup="$apt
		apt-get install -y -qq --no-install-recommends ca-certificates flatpak dbus-daemon xvfb >/dev/null
		flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
		flatpak install --user -y --noninteractive --bundle /pkgs/$file >/dev/null
		echo \"installed: \$(flatpak list --user --columns=application,branch | tr '\n' ' ')\"
		# flatpak run asks the system bus too, which a container lacks.
		mkdir -p /run/dbus && dbus-daemon --system --fork"
	run="LOG=$log /tests/xvfb-test.sh dbus-run-session -- flatpak run --env=PLAYGROUND_LOG=$log $app"
	;;
*)
	sed -n '2,31p' "$0" >&2
	exit 2
	;;
esac

flags=()
[ "$kind" = flatpak ] && flags+=(--privileged)
echo "testing $file in $img"
docker run --rm ${flags[@]+"${flags[@]}"} -e TIMEOUT="$timeout" \
	-v "$root/build:/pkgs:ro" -v "$root/packaging/linux/xvfb-test.sh:/tests/xvfb-test.sh:ro" \
	"$img" bash -euo pipefail -c "$setup
		$run"
