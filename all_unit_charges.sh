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
	./unit_charge "$file" --silent --nounrolljam 
done
