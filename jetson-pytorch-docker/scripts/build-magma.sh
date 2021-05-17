
set -euo pipefail

cd $PACKAGE_DIR

export CFLAGS="${BASE_CFLAGS} -O3"
export LDFLAGS="${BASE_LDFLAGS}"
export CUDADIR=/usr/loca/cuda
export OPENBLASDIR=$PROD_DIR/openblas/$OPENBLAS_VERSION

http://icl.utk.edu/projectsfiles/magma/downloads/magma-2.5.4.tar.gz

tar -xvf magma-2.5.4.tar.gz
cd magma-2.5.4
make install prefix=$PROD_DIR/magma
