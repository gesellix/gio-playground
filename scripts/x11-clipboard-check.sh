#!/usr/bin/env bash
# Checks how the program answers other X11 clients that read its clipboard,
# under Xvfb with xclip, for a sensitive and a plain copy:
#
#   GIO=fork scripts/x11-clipboard-check.sh
#
# The fork's Gio refuses a request for a type it does not offer at once, as
# ICCCM 2.2 asks (the X11 clipboard refusal, gio-patches 72360); upstream
# sends no answer, so xclip waits until its timeout. Both offer
# x-kde-passwordManagerHint ("secret") for a sensitive copy only. A check of
# upstream that fails means that upstream changed: see whether it applied
# the refusal.
#
# Linux with Xvfb, xclip and Gio's build packages runs it directly (the CI
# runner). Elsewhere it runs itself in Docker (indocker in lib.sh).
set -euo pipefail

. "$(dirname "$0")/lib.sh"

if [ "$(uname -s)" != Linux ] || [ "${IN_DOCKER:-}" = 1 ]; then
	indocker x11-clipboard-check.sh
fi

bin=$root/build/x11-$GIO
(cd "$moddir" && go build -o "$bin" .)

display=:${X11_DISPLAY:-99}
Xvfb "$display" -screen 0 1024x768x24 >/dev/null 2>&1 &
xvfb=$!
export DISPLAY=$display
unset WAYLAND_DISPLAY
pid=
cleanup() {
	[ -z "$pid" ] || kill "$pid" 2>/dev/null || true
	kill "$xvfb" 2>/dev/null || true
}
trap cleanup EXIT
sleep 1

fail=0
check() { # description, ok (yes/no), detail
	if [ "$2" = yes ]; then echo "[PASS] $1 ($3)"; else echo "[FAIL] $1 ($3)"; fail=1; fi
}

# get TARGET: sets out, rc and secs; xclip gives up after 3 s.
get() {
	local start end
	start=$(date +%s%N)
	out=$(timeout 3 xclip -selection clipboard -t "$1" -o 2>&1) && rc=0 || rc=$?
	end=$(date +%s%N)
	secs=$(awk -v a="$start" -v b="$end" 'BEGIN { printf "%.1f", (b - a) / 1e9 }')
}
refused() { [ "$rc" = 1 ] && [[ $out == *"not available"* ]] && echo yes || echo no; }
silent() { [ "$rc" = 124 ] && echo yes || echo no; }

for mode in sensitive plain; do
	log=$root/build/x11-$GIO-$mode.log
	rm -f "$log"
	PLAYGROUND_LOG=$log PLAYGROUND_COPY=$mode "$bin" >/dev/null 2>&1 &
	pid=$!
	CHECK_TIMEOUT=30 "$root/scripts/check-log.sh" "$log" "$GIO" "copied " >/dev/null || {
		cat "$log" 2>/dev/null || true
		echo "FAIL: $GIO did not start or copy" >&2
		exit 1
	}
	text=PLAIN-text-456
	[ $mode = sensitive ] && text=SENSITIVE-secret-123
	echo "== $GIO, $mode copy"

	get TARGETS
	targets=$(tr '\n' ' ' <<<"$out")
	check "TARGETS answers" "$([ "$rc" = 0 ] && [[ $targets == *UTF8_STRING* ]] && echo yes || echo no)" "$targets"
	get UTF8_STRING
	check "UTF8_STRING is the copied text" "$([ "$rc" = 0 ] && [ "$out" = "$text" ] && echo yes || echo no)" "rc=$rc"
	if [ $mode = sensitive ]; then
		check "the hint is offered" "$([[ $targets == *x-kde-passwordManagerHint* ]] && echo yes || echo no)" "in TARGETS"
		get x-kde-passwordManagerHint
		check "the hint is 'secret'" "$([ "$rc" = 0 ] && [ "$out" = secret ] && echo yes || echo no)" "rc=$rc: $out"
	else
		check "no hint offered" "$([[ $targets != *x-kde-passwordManagerHint* ]] && echo yes || echo no)" "not in TARGETS"
	fi

	# The types it does not offer: image/png, and the hint on a plain copy.
	unoffered=(image/png)
	[ $mode = plain ] && unoffered+=(x-kde-passwordManagerHint)
	for t in "${unoffered[@]}"; do
		get "$t"
		if [ "$GIO" != upstream ]; then # the fork's Gio: fork and diag
			check "$t refused at once" "$(refused)" "rc=$rc after ${secs}s: $out"
		else
			check "$t gets no answer (upstream, before the refusal)" "$(silent)" "rc=$rc after ${secs}s"
		fi
	done
	kill "$pid" 2>/dev/null || true
	wait "$pid" 2>/dev/null || true
	pid=
done
exit $fail
