#!/bin/sh

TESTS="linear-algebra/blas/gemm/gemm.c \
linear-algebra/blas/gemver/gemver.c \
linear-algebra/blas/gesummv/gesummv.c \
linear-algebra/blas/syr2k/syr2k.c \
linear-algebra/blas/syrk/syrk.c \
linear-algebra/blas/trmm/trmm.c \
linear-algebra/kernels/2mm/2mm.c \
linear-algebra/kernels/3mm/3mm.c \
linear-algebra/kernels/atax/atax.c \
linear-algebra/kernels/bicg/bicg.c \
linear-algebra/kernels/mvt/mvt.c \
datamining/correlation/correlation.c \
datamining/covariance/covariance.c"

# [Clan] Error: syntax error at line 81, column 39.
# stencils/adi/adi.c \

for file in $TESTS; do
	printf "%s\n" "$file"
    #on garde seuelement le nom du fichier sans le .c
    file=$(echo $file | cut -d'.' -f1 |rev | cut -d'/' -f1 | rev)
    echo "$file" >> flags.txt
    echo "STATIC" >> flags.txt
    python3 get_best.py $file static >> flags.txt
    echo "" >> flags.txt

    echo "DYNAMIC" >> flags.txt
    python3 get_best.py $file dynamic >> flags.txt
    echo "" >> flags.txt

    echo "ALGEBRAIC" >> flags.txt
    python3 get_best.py $file algebraic >> flags.txt
    echo "" >> flags.txt
    echo "" >> flags.txt
done
