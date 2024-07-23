#!/bin/sh
#
# for manually working with fuzzers.
# it compiles a single fuzzer in a variety of flavours and let them
# all run cooperatively. that lets fast versions (uninstrumented and optimized)
# cover ground quickly, while the more thorough ones (sanitized and less optimized)
# can benefit from possibly interesting cases.
# this is what I call fast+slow.

set -eu

SCRIPTDIR=$(dirname "$0")

#target=json_generic
target=json_minify
#target=json_prettify
#target=json_reflection
#target=json_roundtrip_floating
#target=json_roundtrip_int
#target=json_roundtrip_string
#target=json_with_comments

builddir=build-multifuzz-$target

mkdir -p $builddir

COMMON="-std=c++2b -I $SCRIPTDIR/../include -fsanitize=fuzzer -g"

CXX="ccache clang++-18"

if true; then
    for o in s g 0 1 2 3; do
	$CXX $COMMON -O$o $target.cpp -o $builddir/O$o &
    done

    for o in s g 0 1 2 3; do
	$CXX $COMMON -O$o -march=native $target.cpp -o $builddir/O$o-native &
    done

    for o in s g 0 1 2 3; do
	$CXX $COMMON -O$o $target.cpp -o $builddir/O$o-asan -fsanitize=address &
    done

    for o in s g 0 1 2 3; do
	$CXX $COMMON -O$o $target.cpp -o $builddir/O$o-usan -fsanitize=undefined &
    done

    for o in s g 0 1 2 3; do
	$CXX $COMMON -O$o $target.cpp -o $builddir/O$o-asan-usan -fsanitize=address,undefined &
    done

    wait
fi

session=multifuzz

echo "do this manually: tmux new-session -A -s multifuzz"

win=0
for f in $builddir/O* ; do
    name=$(basename $f)
    tmux new-window -t $session -c $(pwd) -n $name
    tmux send-keys -t $session:$name "echo hello $name" C-m
    tmux send-keys -t $session:$name "export UBSAN_OPTIONS=abort_on_error=1" C-m
    tmux send-keys -t $session:$name "mkdir -p out;$f -rss_limit_mb=4000 out" C-m
done
