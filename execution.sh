#!/bin/bash
#faire export OMP_NUM_THREADS=nombre de thread avant l'execution

file=$1
dirname=$(dirname "$file")
r_basename=$(basename "$file")
basename=$(basename "$file" .c)

dir="tmp/" 

exe_pluto_dynamic="$dir"bench_pluto_dynamic
exe_pluto_static="$dir"bench_pluto_static
exe_pluto_a="$dir"bench_pluto_a



#on met des valeurs par défaut si les paramètres ne sont pas trouvés
# if [ -z "$DIV1static" ]
# then
#     DIV0static=8
#     DIV1static=32
#     DIV2static=64
#     FLAGSstatic="-lm"
# fi
# if [ -z "$DIV1dynamic" ]
# then
#     DIV0dynamic=8
#     DIV1dynamic=32
#     DIV2dynamic=64
#     FLAGSdynamic="-lm"
# fi
# if [ -z "$DIV1a" ]
# then
#     DIV0a=8
#     DIV1a=32
#     DIV2a=64
#     FLAGSa="-lm"
# fi

# export DIV0="$DIV0"
# export DIV1="$DIV1"
# export DIV2="$DIV2"

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

