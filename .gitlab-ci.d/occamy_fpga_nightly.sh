#!/bin/bash
# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# Configure a VCU128 board and check if it can boot linux

############
# SETTINGS #
############

# vcu=01
vcu=02

#############
# FUNCTIONS #
#############
function _cleanup {
  echo "Cleanup"
  _release_lock
  rm -f serlog.py start_ser.sh
}

# Simple file-based lock on remote server
function _obtain_lock {
  success=0
  for i in {1..10}; do 
    ssh -qo "StrictHostKeyChecking no" -t vcu128-$vcu@bordcomputer.ee.ethz.ch \
     "mkdir .occamy_ci.lock" && { success=1; break; } || { sleep 10; };
  done
}
function _release_lock {
  ssh -qo "StrictHostKeyChecking no" -t vcu128-$vcu@bordcomputer.ee.ethz.ch "rmdir .occamy_ci.lock"
}

# Generate linux image and upload to TFTP server
function _prep_linux {
  make -C hw/system/occamy/fpga linux-image upload-linux-image
}

function _prep_fpga {
  # Write SPI flash with OpenSBI and u-boot SPL, Program bitstream and bootrom, boot process starts
  make -C hw/system/occamy/fpga VCU=$vcu flashrun
}

# Spawn a python script that logs UART output to a file
function _start_serial_logger {
  cat <<\EOF > serlog.py
import sys, serial

if len(sys.argv) != 3+1:
  print(f'Usage: {sys.argv[0]} port baud file')
  exit(-1)
port, baud, file = sys.argv[1], int(sys.argv[2]), sys.argv[3]
print(f'Port: {port} baud: {baud} logfile: {file}')
ser = serial.Serial(port, baud)
while True:
  try:
    line = ser.readline().decode('utf-8')
    print(line.strip())
    with open(file, "a") as f:
        f.write(line)
  except UnicodeDecodeError as e:
    print('Ignoring decode error')
    pass
  except Exception as e:
    print(e)
    break
ser.close()
EOF

  cat <<\EOF > start_ser.sh
pkill -f "python3 serlog.py" ||:
_tty=$(find /dev/serial/by-id -name "*$(cat fpga_id)*-if01*")
_screenlog=$(mktemp -p .)
echo "[remote]: Logging $_tty to $_screenlog"
nohup python3 serlog.py $_tty 115200 $_screenlog > serlog.log 2>&1 &
_pid=$!
sleep 1
echo $_pid > serlog.pid
echo $_screenlog > serlog.file
EOF
  ssh -qo "StrictHostKeyChecking no" -t vcu128-$vcu@bordcomputer.ee.ethz.ch "mkdir -p occamy_ci; echo $fpga_id > occamy_ci/fpga_id"
  scp -qo "StrictHostKeyChecking no" serlog.py start_ser.sh vcu128-$vcu@bordcomputer.ee.ethz.ch:occamy_ci
  ssh -qo "StrictHostKeyChecking no" -t vcu128-$vcu@bordcomputer.ee.ethz.ch "cd occamy_ci && bash start_ser.sh"
}

# Stop the serial logger
function _stop_serial_logger {
  ssh -qo "StrictHostKeyChecking no" -t vcu128-$vcu@bordcomputer.ee.ethz.ch 'kill $(cat occamy_ci/serlog.pid)'
}

# Polls the serial console for the "Welcome to Buildroot" prompt that confirms successful boot
function _wait_shell {

  function __dump {
    echo "/---------------------------------------------------------\\"
    tail -n5 $1
    echo "\\---------------------------------------------------------/"
  }

  wait_shell_success=0

  # prompt="Loading U-Boot"
  prompt="Welcome to Buildroot"

  _screenlog_lcl=$(mktemp -p .)
  _screenlog=$(ssh -qo "StrictHostKeyChecking no" -t vcu128-$vcu@bordcomputer.ee.ethz.ch "cat occamy_ci/serlog.file" | tr -d '\r')

  _mismatch_cnt=0
  _wc_old=0
  while [ $_mismatch_cnt -lt 30 ]; do 
    scp -qo "StrictHostKeyChecking no" vcu128-$vcu@bordcomputer.ee.ethz.ch:occamy_ci/$_screenlog $_screenlog_lcl
    if grep -q "$prompt" $_screenlog_lcl; then
      echo "MATCH"
      wait_shell_success=1
      echo "/---------------------------------------------------------\\"
      grep "$prompt" $_screenlog_lcl -A2 -B2
      echo "\\---------------------------------------------------------/"
      break
    fi

    # check lines of log output, increment _mismatch_cnt on match and reset on mismatch
    _wc_new=$(wc -l $_screenlog_lcl | cut -d' ' -f1)
    [[ $_wc_new -eq $_wc_old ]] && ((_mismatch_cnt=_mismatch_cnt+1)) || _mismatch_cnt=0
    # [[ $_qc_old -eq $_wc_new ]] && { echo a; ((_mismatch_cnt++)); false; } || { echo b; _mismatch_cnt=0; }
    _wc_old=$_wc_new

    echo ""
    echo "Pattern '$prompt' not found (cnt = $_mismatch_cnt). Last lines of UART log:"
    __dump $_screenlog_lcl
    sleep 2

  done

  cp $_screenlog_lcl console.log
  rm $_screenlog_lcl
}

#########
## MAIN
#########

# FPGA ID by VCU ID. IMPORTANT: Without the trailing "A"
case $vcu in
  01)
    fpga_id=091847100576
    ;;
  02)
    fpga_id=091847100638
    ;;
esac

trap _cleanup EXIT

echo "Obtaining lock..."
_obtain_lock
if [ ! $success -eq 1 ]; then
  echo "Could not obtain lock"
  exit 1
fi
echo "Remote lock obtained"

echo "Uploading Kernel to TFTP..."
_prep_linux

echo "Starting UART logger..."
_start_serial_logger

echo "Programming flash and bitstream..."
_prep_fpga

echo "Polling UART output..."
_wait_shell

echo "Stopping UART logger..."
_stop_serial_logger

# _release_lock as part of _cleanup
trap - EXIT
_cleanup

if [ $wait_shell_success -eq 1 ]; then
  echo "test succeeded!"
  exit 0
else
  echo "test FAILED!"
  exit 1
fi
