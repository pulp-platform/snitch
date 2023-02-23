#!/bin/bash
# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

set -e

job_url="https://iis-git.ee.ethz.ch/huettern/snitch/-/jobs"
tmpdir=$(mktemp -d -p .)

echo "Download artifacts from the latest job and place the artifacts.zip in the current working directory"
echo "  pwd: $(pwd)"

while [ ! -f artifacts.zip ]
do
    sleep 1
done

echo "Working directory: $tmpdir"

echo "Extracting artifacts"
unzip -jd $tmpdir artifacts.zip "*.bit" "*.ltx"

bit=$tmpdir/hw/system/occamy/fpga/occamy_vcu128/occamy_vcu128.runs/impl_1/occamy_vcu128_wrapper.bit
ltx=$tmpdir/hw/system/occamy/fpga/occamy_vcu128/occamy_vcu128.runs/impl_1/occamy_vcu128_wrapper.ltx
bootrom=bootrom/bootrom-spl.bin

# cat <<'EOF' > $tmpdir/sourceme.tcl
# set BIT [lindex $argv 0]
# set LTX [lindex $argv 1]
# source occamy_vcu128_procs.tcl
# target_01
# noc_connect
# noc_program_bit $BIT $LTX
# EOF

# echo "Running Vivado"
# vitis-2020.2 vivado -mode batch source $tmpdir/sourceme.tcl -tclargs ${bit} ${ltx}

# target_01
# noc_connect
# noc_program_bit


# rm -rf $tmpdir
