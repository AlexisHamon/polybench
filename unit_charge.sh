#!/bin/bash

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

exe_pluto="$dir"bench_pluto
exe_pluto_a="$dir"bench_pluto_a
#on execute l'executable polycc dans PLUTO_PATH  la commande : 

(cd "$dir" &&  "$PLUTO_PATH/polycc" "${@:2}" bench.c -o bench_pluto.c)
(cd "$dir" &&  "$PLUTO_PATH/polycc" "${@:2}" --atile bench.c -o bench_pluto_a.c)
cp "rtclock.h" $dir
./calcEqCharge.sh "$dir"bench_pluto.c
./calcEqCharge.sh "$dir"bench_pluto_a.c
gcc -O3 -lmpc -I utilities -fopenmp -I "$dirname" "$dir"bench_pluto.c utilities/polybench.c -DDIV0=8 -DDIV1=32 -DDIV2=64 -lm -o "$exe_pluto"
gcc -O3 -lmpc -I utilities -fopenmp -I "$dirname" "$dir"bench_pluto_a.c utilities/polybench.c -DDIV0=8 -DDIV1=32 -DDIV2=64 -lm -o "$exe_pluto_a"

cat /dev/null > "$exe_pluto".out
#on écrit à la suite du fichier result.csv
#On écrit le nom d fichier 
echo "#$r_basename" >> result.csv
#On écrit le nom de la fonction
echo "##TILE " >> result.csv
$exe_pluto >> result.csv
echo "" >> result.csv

echo "##ALGEBRIC TILE " >> result.csv
$exe_pluto_a >> result.csv
#on saute ue ligne
echo "" >> result.csv
echo "" >> result.csv
echo "" >> result.csv
echo "" 

