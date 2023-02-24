# Getting Started at IIS
Below you can find the flow to run

First, be aware of the shell which you are using.
- We recommend using bash:
    ```bash
    bash
    ```

## Scratch folder
Due to the limited size of your home directory, we recomment working in your scratch. You can select between `/scratch`, `/scratch2`, `/scratch3`.

- Create yourself a scratch folder to work in it:
    ```bash
    # get your machine name
    export MACHINE=$(hostname | cut -d . -f 1)
    # Look how much free space there is in the scratch folders
    df -h | grep scratch
    # Pick one and create your folder in there, example :
    mkdir -p /scratch/${USER}
    # Note, contrary to your home folder, the scratch folder is local to your machine, but you can access it on any other machine over the network as follows:
    cd /usr/scratch/${MACHINE}/${USER}
    ```

## Installation
At IIS the default version of some tools (`gcc`, `cmake`, ...) might be too old for certain projects.

- Create a install directory to install the needed tools:
    ```bash
    #deinfe
    export INSTALL_DIR=/usr/scratch/${MACHINE}/${USER}/install-snitch
    mkdir $INSTALL_DIR
    cd $INSTALL_DIR
    ```

- Use the pre-installed LLVM toolchain by adding the following to your path:
    ```bash
    export PATH=/usr/pack/riscv-1.0-kgf/pulp-llvm-0.12.0/bin/:$PATH
    ```

    or download the latest toolchain (andd add the location to your path):
    ```bash
    mkdir -p riscv-llvm
    export LATEST_TAG=`curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/pulp-platform/llvm-project/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
    wget -qO- https://github.com/pulp-platform/llvm-project/releases/download/${LATEST_TAG}/riscv32-pulp-llvm-centos7-${LATEST_TAG}.tar.gz  | tar xvz --strip-components=1 -C riscv-llvm
    # go back to installation directory
    cd ${INSTALL_DIR}
    # add location to path
    export PATH=${INSTALL_DIR}/riscv-llvm/bin/:${PATH}
    # unset temporary variables
    unset LATEST_TAG
    ```

- Install the correct python version:
    ```bash
    export PYTHON_VERSION=3.9.10
    mkdir -p python-${PYTHON_VERSION}
    # download into temporary directory
    mkdir tmp
    cd tmp
    curl https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz | tar -xz --strip-components=1
    # install into location /usr/scratch/${MACHINE}/${USER}/python-${PYTHON_VERSION}
    ./configure --prefix=${INSTALL_DIR}/python-${PYTHON_VERSION} --enable-ipv6
    make -j$(nproc)
    make install
    # go back to installation directory
    cd ${INSTALL_DIR}
    # delete temporary installation directory
    rm -rf tmp
    # add location to path
    export PATH=${PWD}/python-${PYTHON_VERSION}/bin/:$PATH
    # unset temporary variables
    unset PYTHON_VERSION
    ```

- Install the correct verilator version:
    ```bash
    export VERILATOR_VERSION=4.100
    mkdir tmp
    wget -qO- https://github.com/verilator/verilator/archive/refs/tags/v${VERILATOR_VERSION}.tar.gz  | tar xvz --strip-components=1 -C tmp
    mkdir -p verilator-${VERILATOR_VERSION}
    cd tmp
    autoconf
    unset VERILATOR_ROOT
    ./configure --prefix=${INSTALL_DIR}/verilator-${VERILATOR_VERSION}
    make -j$(nproc)
    make install
    # unset temporary variables
    unset VERILATOR_VERSION
    # go back to installation directory
    cd ${INSTALL_DIR}
    # create symbolic link
    export PATH="${INSTALL_DIR}/verilator-${VERILATOR_VERSION}/bin/:$PATH"
    # export INCLUDE_PATH="${INSTALL_DIR}/verilator-${VERILATOR_VERSION}/include/:$INCLUDE_PATH"
    # export INCLUDE_PATH="${INSTALL_DIR}/verilator-${VERILATOR_VERSION}/include/vltstd/:$INCLUDE_PATH"
    ```

For installing the last missing pieces you need to clone the repository.

- Clone the repository:
    ```bash
    cd /usr/scratch/${MACHINE}/${USER}
    git clone git@github.com:pulp-platform/snitch.git
    ```
- Create virtual environment and install the `python-requirements.txt`:
    ```bash
    # create virtual environment with correct and newly installed python version
    python3.9 -m venv ~/.venvs/snitch
    # activate the virtual environment
    source ~/.venvs/snitch/bin/activate
    # enter the cloned snitch directory
    cd snitch
    # install python requirements
    pip install -r python-requirements.txt
    ```

- Create a location for all you binaries in your home directory and create it to your path:
    ```bash
    mkdir -p /home/${USER}/.snitch-bin
    # Add the created binary location to your path
    export PATH=/home/${USER}/.snitch-bin:$PATH
    ```

- Install the correct `spike-dasm` and create a symbolic link to your binary location `/home/${USER}/.snitch-bin`:
    ```bash
    cd sw/vendor/riscv-isa-sim
    mkdir build
    cd build
    ../configure
    make spike-dasm
    # create symbolic link
    ln -s /usr/scratch/${MACHINE}/${USER}/snitch/sw/vendor/riscv-isa-sim/build/spike-dasm /home/${USER}/.snitch-bin/spike-dasm
    ```

- Use a newer `cmake` versions:
    ```bash
    # make sure you are in /home/${USER}/.snitch-bin
    cd /home/${USER}/.snitch-bin
    ln -s /usr/sepp/bin/cmake-3.18.1 cmake
    ```

### Post Installation

If you work next time from a clean bash shell you only have to run the following commands (or you can add them to your `.bashrc`)

```bash
export INSTALL_DIR=/usr/scratch/${MACHINE}/${USER}/install-snitch

# LLVM
# pre-installed
export PATH=/usr/pack/riscv-1.0-kgf/pulp-llvm-0.12.0/bin/:$PATH
# or manually installad
#export PATH=${INSTALL_DIR}/riscv-llvm/bin/:${PATH}

# Correct Python version
export PATH=${PWD}/python-${PYTHON_VERSION}/bin/:$PATH

# Activate the virtual python environment
source ~/.venvs/snitch/bin/activate

# Correct Verilator Version
export PATH="${INSTALL_DIR}/verilator-${VERILATOR_VERSION}/bin/:$PATH"

# Use correct `cmake` and `spike-dasm` version
export PATH=/home/${USER}/.snitch-bin:$PATH
```

### Tool Specific Versions
Unfortunately, depending on which RTL simulator you are using, you need to use a different GCC version. Therefore, you have to set the following variables **in addition** to the above commands.

Let's go to the system `snitch_cluster`:

```bash
cd /usr/scratch/${MACHINE}/${USER}/snitch
cd hw/system/snitch_cluster
```

#### Questasim

First, let's prepare the environment to use Questasim and let's run some tests:

```bash
# Use Questasim's older GCC version for correct DPI compilation
export QUESTA_HOME=/usr/pack/modelsim-10.7b-kgf/questasim/
export CC=$QUESTA_HOME/gcc-5.3.0-linux_x86_64/bin/gcc
export CXX=$QUESTA_HOME/gcc-5.3.0-linux_x86_64/bin/g++
export LD=$QUESTA_HOME/gcc-5.3.0-linux_x86_64/bin/ld

# compile HW for Questasim
make bin/snitch_cluster.vsim

# build and run all snRuntime SW tests on Questasim
make sw.test.vsim

# undo the variables if you change simulator
unset QUESTA_HOME
unset CC
unset CXX
unset LD
```

#### VCS 

Next, let's test prepare the environment for VCS and let's run some tests:

```bash
# set GCC and G++ to version 9.2
export GCC_DIR="/usr/pack/gcc-9.2.0-af"
export GCC_DIR2="${GCC_DIR}/linux-x64"
# use correct CC and CXX
export CC="${GCC_DIR2}/bin/gcc"
export CXX="${GCC_DIR2}/bin/g++"
# set correct libraries
export LD_LIBRARY_PATH="${GCC_DIR2}/lib64"
export LIBRARY_PATH="${GCC_DIR2}/lib64"
# set correct include paths
export C_INCLUDE_PATH="${GCC_DIR}/include"
export CPLUS_INCLUDE_PATH="${GCC_DIR}/include"
# set correct PATH
export PATH="${GCC_DIR2}/linux-x64/bin:${PATH}"

# compile HW for VCS with correct VCS version prefix
vcs-2020.12 make bin/snitch_cluster.vcs

# build and run all snRuntime SW tests on VCS
vcs-2020.12 make sw.test.vcs

# undo the variables if you change simulator
unset CC=gcc-9.2.0
unset CXX=g++-9.2.0
```


### Verilator 

Verilator uses the same GCC compiler as VCS:

```bash
# compile HW for Verilator
make bin/snitch_cluster.vlt

# build and run all snRuntime SW tests on Verilator
make sw.test.vlt
```

## Summary

Next time you start with a fresh terminal, you can execute the following commands to use the correct tools:

```bash
bash
export INSTALL_DIR=/usr/scratch/${MACHINE}/${USER}/install-snitch

# LLVM
# pre-installed
export PATH=/usr/pack/riscv-1.0-kgf/pulp-llvm-0.12.0/bin/:$PATH
# or manually installad
#export PATH=${INSTALL_DIR}/riscv-llvm/bin/:${PATH}

# Correct Python version
export PATH=${PWD}/python-${PYTHON_VERSION}/bin/:$PATH

# Activate the virtual python environment
source ~/.venvs/snitch/bin/activate

# Correct Verilator Version
export PATH="${INSTALL_DIR}/verilator-${VERILATOR_VERSION}/bin/:$PATH"

# Use correct `cmake` and `spike-dasm` version
export PATH=/home/${USER}/.snitch-bin:$PATH
```

If you use **Questasim**, set the following variables:

```bash
export QUESTA_HOME=/usr/pack/modelsim-10.7b-kgf/questasim/
export CC=$QUESTA_HOME/gcc-5.3.0-linux_x86_64/bin/gcc
export CXX=$QUESTA_HOME/gcc-5.3.0-linux_x86_64/bin/g++
export LD=$QUESTA_HOME/gcc-5.3.0-linux_x86_64/bin/ld
```

If you use **VCS** or **Verilator**, set the following variables:

```bash
# set GCC and G++ to version 9.2
export GCC_DIR="/usr/pack/gcc-9.2.0-af"
export GCC_DIR2="${GCC_DIR}/linux-x64"
# use correct CC and CXX
export CC="${GCC_DIR2}/bin/gcc"
export CXX="${GCC_DIR2}/bin/g++"
# set correct libraries
export LD_LIBRARY_PATH="${GCC_DIR2}/lib64"
export LIBRARY_PATH="${GCC_DIR2}/lib64"
# set correct include paths
export C_INCLUDE_PATH="${GCC_DIR}/include"
export CPLUS_INCLUDE_PATH="${GCC_DIR}/include"
# set correct PATH
export PATH="${GCC_DIR2}/linux-x64/bin:${PATH}"
```
