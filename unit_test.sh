#!/bin/bash

PLUTO_PATH=$(realpath "../pluto")
POLYBENCH_PATH=$PWD
export PATH="$PLUTO_PATH:$PATH"

file=$1
dirname=$(dirname "$file")
r_basename=$(basename "$file")
basename=$(basename "$file" .c)

dir="tmp/"

cp "$file" "$dir"bench.c 

exe_ref="$dir"bench_ref
exe_pluto="$dir"bench_pluto

(cd "$dir" &&  polycc "${@:2}" bench.c -o bench_pluto.c)


gcc -O3 -fopenmp -I utilities -I "$dirname" utilities/polybench.c "$dir"bench_pluto.c -DPOLYBENCH_DUMP_ARRAYS -DDIV0=8 -DDIV1=32 -DDIV2=64  -lm -o "$exe_pluto" 
gcc -O0 -fopenmp -I utilities -I "$dirname" utilities/polybench.c "$dir"bench.c -DPOLYBENCH_DUMP_ARRAYS  -lm -o "$exe_ref"

cat /dev/null > "$exe_ref".out
cat /dev/null > "$exe_pluto".out
$exe_ref 2> "$exe_ref".out
$exe_pluto 2> "$exe_pluto".out


if ! cmp "$exe_ref".out "$exe_pluto".out; then
    printf " [\e[31mFailed\e[0m] %s\n" "$file"!
    exit 1
else
    printf " [\e[32mPassed\e[0m]\n"
    exit 0
fi
