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

#on récupère les meilleurs paramètres de pluto avec get_best.py
best_static=$(python3 get_best.py "$basename" static)
best_dynamic=$(python3 get_best.py "$basename" dynamic)
best_a=$(python3 get_best.py "$basename" algebraic)

DIV0static=$(echo "$best_static" | sed -n 1p)
DIV1static=$(echo "$best_static" | sed -n 2p)
DIV2static=$(echo "$best_static" | sed -n 3p)
FLAGSstatic=$(echo "$best_static" | sed -n 4p)
EXTRAstatic=$(echo "$best_static" | sed -n 5p)
DIV0dynamic=$(echo "$best_dynamic" | sed -n 1p)
DIV1dynamic=$(echo "$best_dynamic" | sed -n 2p)
DIV2dynamic=$(echo "$best_dynamic" | sed -n 3p)
FLAGSdynamic=$(echo "$best_dynamic" | sed -n 4p)
EXTRAdynamic=$(echo "$best_dynamic" | sed -n 5p)
DIV0a=$(echo "$best_a" | sed -n 1p)
DIV1a=$(echo "$best_a" | sed -n 2p)
DIV2a=$(echo "$best_a" | sed -n 3p)
FLAGSa=$(echo "$best_a" | sed -n 4p)
EXTRAa=$(echo "$best_a" | sed -n 5p)


#on met des valeurs par défaut si les paramètres ne sont pas trouvés
if [ -z "$DIV1static" ]
then
    DIV0static=8
    DIV1static=32
    DIV2static=64
    FLAGSstatic="-lm"
fi
if [ -z "$DIV1dynamic" ]
then
    DIV0dynamic=8
    DIV1dynamic=32
    DIV2dynamic=64
    FLAGSdynamic="-lm"
fi
if [ -z "$DIV1a" ]
then
    DIV0a=8
    DIV1a=32
    DIV2a=64
    FLAGSa="-lm"
fi

#on execute l'executable polycc dans PLUTO_PATH 
(cd "$dir" &&  "$PLUTO_PATH/polycc" "${@:2}" bench.c -o bench_pluto_dynamic.c)
(cd "$dir" &&  "$PLUTO_PATH/polycc" "${@:2}" --atile bench.c -o bench_pluto_a.c)

#on crée bench_pluto_static.c
cp "$dir"bench_pluto_dynamic.c "$dir"bench_pluto_static.c
cp "rtclock.h" $dir
./transformation.sh -d "$dir"bench_pluto_dynamic.c
./transformation.sh -s "$dir"bench_pluto_static.c
./transformation.sh -s "$dir"bench_pluto_a.c
export DIV0="$DIV0"
export DIV1="$DIV1"
export DIV2="$DIV2"
gcc -O3 -lmpc -I utilities -fopenmp -I "$dirname" "$dir"bench_pluto_dynamic.c utilities/polybench.c -DDIV0="$DIV0dynamic" -DDIV1="$DIV1dynamic" -DDIV2="$DIV2dynamic" $FLAGSdynamic $EXTRAdynamic -o "$exe_pluto_dynamic"
gcc -O3 -lmpc -I utilities -fopenmp -I "$dirname" "$dir"bench_pluto_static.c utilities/polybench.c -DDIV0="$DIV0static" -DDIV1="$DIV1static" -DDIV2="$DIV2static" $FLAGSstatic $EXTRAstatic -o "$exe_pluto_static"
gcc -O3 -lmpc -I utilities -fopenmp -I "$dirname" "$dir"bench_pluto_a.c utilities/polybench.c -DDIV0="$DIV0a" -DDIV1="$DIV1a" -DDIV2="$DIV2a" $FLAGSa $EXTRAa -o "$exe_pluto_a"

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

