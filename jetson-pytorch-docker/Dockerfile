# *******************************************************************************
# Copyright 2020-2021 Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *******************************************************************************
FROM nvcr.io/nvidia/l4t-base:r32.5.0

# Dev packages
ARG njobs=8

RUN if ! [ "$(arch)" = "aarch64" ] ; then exit 1; fi

#Install core OS packages
RUN apt-get -y update && \
    apt-get -y install software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    apt-get -y install \
      autoconf \
      bc \
      build-essential \
      cmake \
      curl \
      g++-8 \
      gcc-8 \
      gettext-base \
      gfortran-8 \
      git \
      iputils-ping \
      libbz2-dev \
      libc++-dev \
      libcgal-dev \
      libffi-dev \
      libfreetype6-dev \
      libhdf5-dev \
      libjpeg-dev \
      liblzma-dev \
      libncurses5-dev \
      libncursesw5-dev \
      libpng-dev \
      libreadline-dev \
      libssl-dev \
      libsqlite3-dev \
      libxml2-dev \
      libxslt-dev \
      locales \
      moreutils \
      openjdk-8-jdk \
      openssl \
      python-openssl \
      rsync \
      scons \
      ssh \
      sudo \
      time \
      unzip \
      vim \
      wget \
      xz-utils \
      zip \
      zlib1g-dev

# Make gcc 9 the default
# RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 1 --slave /usr/bin/g++ g++ /usr/bin/g++-9 && \
#     update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-9 1

ENV DOCKER_USER="workspace"

# Import profile for bash
COPY bash_profile /home/$DOCKER_USER/.bash_profile

ENV NP_MAKE="${njobs}"

# Key version numbers
ENV PY_VERSION=3.8.5 \
    ACL_VERSION="v21.02" \
    OPENBLAS_VERSION=0.3.10 \
    NINJA_VERSION=1.9.0

# Package build parameters
ENV PROD_DIR=/opt \
    PACKAGE_DIR=/packages

# Make directories to hold package source & build directories (PACKAGE_DIR)
# and install build directories (PROD_DIR).
RUN mkdir -p $PACKAGE_DIR && \
    mkdir -p $PROD_DIR

# Build Arm Optimized Routines from source
# provides optimised maths library fucntions for Aarch64
# see https://github.com/ARM-software/optimized-routines
COPY scripts/build-arm_opt_routines.sh $PACKAGE_DIR/.
COPY patches/config.mk $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-arm_opt_routines.sh

# Common compiler settings for remaining builds
# this ads arm_opt_routined into the LDFLAGS by default.
ENV CC=gcc \
    CXX=g++ \
    BASE_CFLAGS="-mcpu=native" \
    BASE_LDFLAGS="-L$PROD_DIR/arm_opt_routines/lib -lmathlib -lm" \
    LD_LIBRARY_PATH="$PROD_DIR/arm_opt_routines/lib"

COPY scripts/build-cpython.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-cpython.sh

# Build OpenBLAS from source
COPY scripts/build-openblas.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-openblas.sh
ENV OPENBLAS_DIR=$PROD_DIR/openblas/$OPENBLAS_VERSION
ENV LD_LIBRARY_PATH=$OPENBLAS_DIR/lib:$LD_LIBRARY_PATH

# Build Arm Compute Library from source
# Mem overflow on building this need to revisit
#COPY scripts/build-acl.sh $PACKAGE_DIR/.
#RUN $PACKAGE_DIR/build-acl.sh
#ENV ACL_ROOT_DIR=$PROD_DIR/ComputeLibrary

# Build ninja from source
COPY scripts/build-ninja.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-ninja.sh
ENV PATH=$PROD_DIR/ninja/$NINJA_VERSION:$PATH

# Install CUDA libs:
apt-key adv --fetch-key https://repo.download.nvidia.com/jetson/jetson-ota-public.asc
add-apt-repository 'deb [arch=arm64] https://repo.download.nvidia.com/jetson/common r32.5 main'
add-apt-repository 'deb [arch=arm64] https://repo.download.nvidia.com/jetson/t194 r32.5 main'

apt-get install cuda-libraries-dev-10-2
apt-get install libcublas-dev

# Build Magma from source
COPY scripts/build-magma.sh $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-magma.sh
ENV NP_MAKE="${njobs}"

# Key version numbers
ENV NUMPY_VERSION=1.19.5 \
    SCIPY_VERSION=1.5.2 \
    NPY_DISTUTILS_APPEND_FLAGS=1

# Using venv means this can be done in userspace
WORKDIR /home/$DOCKER_USER
USER $DOCKER_USER
ENV PACKAGE_DIR=/home/$DOCKER_USER/$PACKAGE_DIR
RUN mkdir -p $PACKAGE_DIR

# Setup a Python virtual environment
ENV VENV_DIR=/home/$DOCKER_USER/python3-venv
ENV VENV_ACT=$VENV_DIR/bin/activate
RUN python -m venv $VENV_DIR
ENV PATH="$VENV_DIR/bin:$PATH"

# Install some basic python packages needed for NumPy
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir "setuptools>=41.0.0" six mock wheel cython

# Build numpy from source, using OpenBLAS for BLAS calls
COPY scripts/build-numpy.sh $PACKAGE_DIR/.
COPY patches/site.cfg $PACKAGE_DIR/site.cfg
RUN $PACKAGE_DIR/build-numpy.sh

# Install some  basic python packages needed for SciPy
RUN pip install --no-cache-dir pybind11 pyangbind
# Build numpy from source, using OpenBLAS for BLAS calls
COPY scripts/build-scipy.sh $PACKAGE_DIR/.
COPY patches/site.cfg $PACKAGE_DIR/site.cfg
RUN $PACKAGE_DIR/build-scipy.sh

# Install some more essentials.
RUN pip install --no-cache-dir hypothesis pyyaml pytest
RUN pip install --no-cache-dir matplotlib
RUN pip install --no-cache-dir pillow==6.1 lmdb
RUN pip install --no-cache-dir ck==1.55.5 absl-py pycocotools typing_extensions
RUN pip install --no-cache-dir scikit-build

# build PyTorch
ARG njobs=8
ARG onednn_opt
ENV ONEDNN_BUILD="${onednn_opt}" \
    NP_MAKE="${njobs}"

# Key version numbers
ENV TORCH_VERSION=1.8.1
ENV ONEDNN_VERSION="v2.2"
ENV VISION_VERSION="v0.9.1"

# Use a PACKAGE_DIR in userspace
ENV PACKAGE_DIR=/opt/$PACKAGE_DIR
RUN mkdir -p $PACKAGE_DIR

# Copy in the Python virtual environment
ENV VENV_DIR=/home/$DOCKER_USER/python3-venv
ENV PATH="$VENV_DIR/bin:$PATH"

# # Build PyTorch
COPY scripts/build-pytorch.sh $PACKAGE_DIR/.
COPY patches/pytorch_onednn.patch $PACKAGE_DIR/.
RUN $PACKAGE_DIR/build-pytorch.sh
