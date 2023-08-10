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
echo "$DIV0dynamic" > "$dir"/tile.sizes
echo "$DIV1dynamic" >> "$dir"/tile.sizes
echo "$DIV2dynamic" >> "$dir"/tile.sizes
(cd "$dir" &&  "$PLUTO_PATH/polycc" "${@:2}" bench.c -o bench_pluto_dynamic.c)
echo "$DIV0static" > "$dir"/tile.sizes
echo "$DIV1static" >> "$dir"/tile.sizes
echo "$DIV2static" >> "$dir"/tile.sizes
(cd "$dir" &&  "$PLUTO_PATH/polycc" "${@:2}" bench.c -o bench_pluto_static.c)

(cd "$dir" &&  "$PLUTO_PATH/polycc" "${@:2}" --atile bench.c -o bench_pluto_a.c)

#on crée bench_pluto_static.c
cp "rtclock.h" $dir
./transformation.sh -d "$dir"bench_pluto_dynamic.c
./transformation.sh -s "$dir"bench_pluto_static.c
./transformation.sh -s "$dir"bench_pluto_a.c
#on cree le dossier all-charges s'il n'existe pas
mkdir -p all-charges
#on copie les trois fichiers dans all-charges
# cp "$dir"bench_pluto_dynamic.c all-charges/"$basename"_dynamic.c
# cp "$dir"bench_pluto_static.c all-charges/"$basename"_static.c
# cp "$dir"bench_pluto_a.c all-charges/"$basename"_algebraic.c


echo "DIV0 = $DIV0dynamic"
echo "DIV1 = $DIV1a"
echo "DIV2 = $DIV2a"
echo "FLAGS = $FLAGSa"
echo "EXTRA = $EXTRAa"

gcc -O3 -lmpc -I utilities -fopenmp -I "$dirname" "$dir"bench_pluto_dynamic.c utilities/polybench.c -DDIV0="$DIV0dynamic" -DDIV1="$DIV1dynamic" -DDIV2="$DIV2dynamic" $FLAGSdynamic $EXTRAdynamic -DPOLYBENCH_TIME -march=native -O3 -o "$exe_pluto_dynamic"

gcc -O3 -lmpc -I utilities -fopenmp -I "$dirname" "$dir"bench_pluto_static.c utilities/polybench.c -DDIV0="$DIV0static" -DDIV1="$DIV1static" -DDIV2="$DIV2static" $FLAGSstatic $EXTRAstatic -DPOLYBENCH_TIME -march=native -O3 -o "$exe_pluto_static"

gcc -O3 -lmpc -I utilities -fopenmp -I "$dirname" "$dir"bench_pluto_a.c utilities/polybench.c -DDIV0="$DIV0a" -DDIV1="$DIV1a" -DDIV2="$DIV2a" $FLAGSa $EXTRAa -DPOLYBENCH_TIME -march=native -O3 -o "$exe_pluto_a"
#on copie les trois exécutables sur la machine pernias@trahrhe.icube.unistra.fr

mot_de_passe_ssh="" #MOT DE PASSE A ENTRER
sshpass -p "$mot_de_passe_ssh" scp "$exe_pluto_static" pernias@trahrhe.icube.unistra.fr:eqCharge/polybench/tmp
sshpass -p "$mot_de_passe_ssh" scp "$exe_pluto_a" pernias@trahrhe.icube.unistra.fr:eqCharge/polybench/tmp
sshpass -p "$mot_de_passe_ssh" scp "$exe_pluto_dynamic" pernias@trahrhe.icube.unistra.fr:eqCharge/polybench/tmp
#on exécute le script execution.sh sur la machine pernias@trahrhe
sshpass -p "$mot_de_passe_ssh" ssh pernias@trahrhe.icube.unistra.fr "export DATASET_SIZE="DOOM_DATASET" && export OMP_PROC_BIND=true && export OMP_NUM_THREADS=64 && cd eqCharge/polybench && ./execution.sh $file"





