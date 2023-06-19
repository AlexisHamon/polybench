#!/bin/sh

TESTS="linear-algebra/blas/gemm/gemm.c \
linear-algebra/blas/gemver/gemver.c \
linear-algebra/blas/gesummv/gesummv.c \
linear-algebra/blas/symm/symm.c \
linear-algebra/blas/syr2k/syr2k.c \
linear-algebra/blas/syrk/syrk.c \
linear-algebra/blas/trmm/trmm.c \
linear-algebra/kernels/2mm/2mm.c \
linear-algebra/kernels/3mm/3mm.c \
linear-algebra/kernels/atax/atax.c \
linear-algebra/kernels/bicg/bicg.c \
linear-algebra/kernels/doitgen/doitgen.c \
linear-algebra/kernels/mvt/mvt.c \
linear-algebra/solvers/durbin/durbin.c \
linear-algebra/solvers/gramschmidt/gramschmidt.c \
linear-algebra/solvers/lu/lu.c \
linear-algebra/solvers/ludcmp/ludcmp.c \
linear-algebra/solvers/trisolv/trisolv.c \
medley/deriche/deriche.c \
medley/floyd-warshall/floyd-warshall.c \
medley/nussinov/nussinov.c \
stencils/adi/adi.c \
stencils/fdtd-2d/fdtd-2d.c \
stencils/heat-3d/heat-3d.c \
stencils/jacobi-1d/jacobi-1d.c \
stencils/jacobi-2d/jacobi-2d.c \
stencils/seidel-2d/seidel-2d.c"

for file in $TESTS; do
	printf "%s" "$file"
	./unit_test "$file"
done
