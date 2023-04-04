#!/usr/bin/env bash
# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

python_version=3.9.10

set -ex

if [ -z "$1" ]
then
    echo "\$1 is empty. Specify root directory as argument"
    exit -1
fi

root=$1
old_pwd=$(pwd)

tmp=$(mktemp -d -p .)
cd ${tmp}
curl https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz | tar -xz --strip-components=1
mkdir -p $root/install/python
./configure --prefix=$root/install/python --enable-ipv6
make -j$(nproc)
make install
cd ${old_pwd}
rm -rf ${tmp}
