#!/bin/bash
#faire export OMP_NUM_THREADS=nombre de thread avant l'execution
PLUTO_PATH=$(realpath "../pluto")
POLYBENCH_PATH=$PWD
export PATH="$PLUTO_PATH:$PATH"

file=$1
dirname=$(dirname "$file")
r_basename=$(basename "$file")
basename=$(basename "$file" .c)

dir="tmp/"
echo "pluto =$PLUTO_PATH"
cp "$file" "$dir"bench.c 

exe_pluto_dynamic="$dir"bench_pluto_dynamic
exe_pluto_static="$dir"bench_pluto_static
exe_pluto_a="$dir"bench_pluto_a
#on execute l'executable polycc dans PLUTO_PATH 

(cd "$dir" &&  "$PLUTO_PATH/polycc" "${@:2}" bench.c -o bench_pluto_dynamic.c)
(cd "$dir" &&  "$PLUTO_PATH/polycc" "${@:2}" --atile bench.c -o bench_pluto_a.c)
#on crée bench_pluto_static.c
cp "$dir"bench_pluto_dynamic.c "$dir"bench_pluto_static.c
cp "rtclock.h" $dir
./transformation.sh -d "$dir"bench_pluto_dynamic.c
./transformation.sh -s "$dir"bench_pluto_static.c
./transformation.sh -s "$dir"bench_pluto_a.c

gcc -O3 -lmpc -I utilities -fopenmp -I "$dirname" "$dir"bench_pluto_dynamic.c utilities/polybench.c -DDIV0=8 -DDIV1=32 -DDIV2=64 -lm -o "$exe_pluto_dynamic"
gcc -O3 -lmpc -I utilities -fopenmp -I "$dirname" "$dir"bench_pluto_static.c utilities/polybench.c -DDIV0=8 -DDIV1=32 -DDIV2=64 -lm -o "$exe_pluto_static"
gcc -O3 -lmpc -I utilities -fopenmp -I "$dirname" "$dir"bench_pluto_a.c utilities/polybench.c -DDIV0=8 -DDIV1=32 -DDIV2=64 -lm -o "$exe_pluto_a"

#schedule TODO
cat /dev/null > "$exe_pluto".out
#on écrit à la suite du fichier result.csv

#On écrit le nom du fichier 
echo "#$r_basename" >> result.csv

echo "##TILE static " >> result.csv
$exe_pluto_static >> result.csv
echo "" >> result.csv

echo "##TILE dynamic " >> result.csv
$exe_pluto_dynamic >> result.csv
echo "" >> result.csv
echo "##ALGEBRAIC TILE " >> result.csv
$exe_pluto_a >> result.csv
#on saute 2 lignes
echo "" >> result.csv
echo "" >> result.csv

