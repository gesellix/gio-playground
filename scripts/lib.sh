# shellcheck shell=bash
# Shared by the scripts (sourced, not run): loads .env and picks the build.
#
# Variables from the environment win over .env, so a single run can change
# one, for example: GIO=upstream scripts/ios.sh

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# .env has KEY=VALUE lines; # starts a comment line, empty values are
# skipped, a leading ~ is the home directory.
if [ -f "$root/.env" ]; then
	while IFS= read -r line || [ -n "$line" ]; do
		case $line in '' | '#'*) continue ;; esac
		key=${line%%=*}
		val=${line#*=}
		val=${val%\"}
		val=${val#\"}
		val=${val/#\~/$HOME}
		if [ -n "$val" ] && [ -z "${!key+x}" ]; then
			export "$key=$val"
		fi
	done <"$root/.env"
fi

: "${GIO:=fork}"
: "${APP_ID:=org.example.gioplayground}"
: "${APP_NAME:=GioPlayground}"
: "${URL_SCHEME:=gioplayground}"

case $GIO in
fork | upstream | diag) ;;
*)
	echo "GIO is fork, upstream or diag, not $GIO" >&2
	exit 2
	;;
esac

# The module of the build: fork (with the patches), upstream, or diag (the
# fork with a trace of the iOS driver, see scripts/ios-background-test.sh).
moddir=$root/$GIO
mkdir -p "$root/build"

# gogio runs as a tool of the module, so each build gets its own gogio:
# upstream's, or for fork and diag the fork's with -platformdir.
gogio() { (cd "$moddir" && go tool gogio "$@"); }

# completefiles reports whether the build passes gogio the complete platform
# files of platform/ (fork and diag) instead of letting it generate them.
completefiles() { [ "$GIO" != upstream ]; }

# platformdir writes the complete platform files of platform/ to
# build/platform/, with the values of .env, and prints the directory to
# pass to gogio -platformdir. gogio picks the files of its target by their
# names (Info_ios.plist, AndroidManifest.xml, ...).
platformdir() {
	local dir=$root/build/platform
	rm -rf "${dir:?}"
	mkdir -p "$dir"
	local f
	for f in "$root/platform"/*; do
		sed -e "s|@APP_ID@|$APP_ID|g" -e "s|@APP_NAME@|$APP_NAME|g" -e "s|@URL_SCHEME@|$URL_SCHEME|g" "$f" >"$dir/$(basename "$f")"
	done
	echo "$dir"
}

# ldflags passes the gogio flags of the build (a comma separated list) and
# the URL scheme to the program, which shows them.
ldflags() {
	local p=github.com/gesellix/gio-playground
	echo "-X $p.buildFlags=$1 -X $p.urlScheme=$URL_SCHEME"
}

# indocker runs scripts/$1 in a Debian container with Go, Gio's build
# packages and the tools of the Linux checks (Xvfb, xclip, Mutter), for a
# host that is not Linux. The image gioplayground-linux-check is built on
# the first run; the Go caches stay in volumes.
indocker() {
	local image=gioplayground-linux-check gover
	if ! docker image inspect "$image" >/dev/null 2>&1; then
		gover=$(sed -n 's/^go //p' "$root/go.mod")
		docker build -q -t "$image" - >/dev/null <<-EOF
			FROM golang:$gover-bookworm
			RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \\
				pkg-config libwayland-dev libx11-dev libx11-xcb-dev libxkbcommon-x11-dev \\
				libgles2-mesa-dev libegl1-mesa-dev libffi-dev libxcursor-dev libvulkan-dev \\
				libgl1-mesa-dri xvfb xauth xclip mutter dbus >/dev/null \\
				&& rm -rf /var/lib/apt/lists/*
		EOF
	fi
	exec docker run --rm -e GIO -e IN_DOCKER=0 -v "$root:/src" -w /src \
		-v gioplayground-linux-check-gomod:/go/pkg/mod \
		-v gioplayground-linux-check-gocache:/root/.cache/go-build \
		"$image" "scripts/$1"
}
