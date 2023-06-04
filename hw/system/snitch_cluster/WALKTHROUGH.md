# Walkthrough

## Fast setup at IIS

### Scratch folder

First, create yourself a folder to work in on the scratch disk. Your home directory is mounted from the network, and has tighter size and access speed constraints than the scratch disks in your machine. You can sometimes select between multiple scratch disks, such as `/scratch`, `/scratch2`, `/scratch3`.

```bash
# Look how much free space there is in the scratch folders
df -h | grep scratch
# Pick one and create your folder in there, for example:
mkdir /scratch/[your username]
# Note, contrary to your home folder, the scratch folder is local to your machine, but you can access it on any other machine like so
cd /usr/scratch/[your machine]/[your username]
# You can find the name of a machine by running
hostname
# (Note, keep only the name before .ee.ethz.ch)
```

### Dependencies

At IIS the default version of some tools (`gcc`, `cmake`, ...) might be too old for certain projects. You will need to setup your own default binary for these tools:

```bash
# Create your own bin folder in your home directory
mkdir ~/bin && cd ~/bin
# There you can change the default binaries for your user
ln -s /usr/pack/gcc-9.2.0-af/linux-x64/bin/gcc gcc
ln -s /usr/pack/gcc-9.2.0-af/linux-x64/bin/g++ g++
ln -s /usr/sepp/bin/cmake-3.18.1 cmake
ln -s /home/colluca/bin/spike-dasm spike-dasm
# Now you need to add this folder to your PATH:
# Open ~/.profile and add the lines
export PATH=~/bin:$PATH
export PATH=/usr/scratch/dachstein/colluca/opt/verible/bin:$PATH
```

Create a Python virtual environment:

```
python3.9 -m venv ~/.venvs/snitch
```

Activate your environment, e.g. in a bash shell:
```
source ~/.venvs/snitch/bin/activate
```

Note that the default shell for IIS users is `tcsh`, hence you may need to adapt the previous command accordingly.

Add the last line to your shell startup file (e.g. `~/.bashrc` if you use bash as the default shell) if you want the virtual environment to be activated by default when you open a new terminal.

To compile your code to a RISC-V executable you will need a compiler toolchain for RISC-V. There are plenty of pre-compiled RISC-V toolchains at IIS, for Snitch you can use the following LLVM toolchain.

```bash
# You can add this to your shell startup file such that you do not have to run this command every time you open a new terminal
export PATH=/usr/scratch2/rapanui/lbertaccini/snitch_occamy_vsum_test/riscv32-pulp-llvm-centos7-131/bin/:$PATH
```

## Cloning Snitch

First, clone this repository on your scratch folder. We suggest you first make a private fork of the repo.

```bash
git clone https://github.com/pulp-platform/snitch.git
cd snitch
```

Now install the required Python dependencies. Make sure you have activated your virtual environment before doing so.

```
pip install -r python-requirements.txt
```

## Compiling the Snitch hardware for simulation

Go to the `snitch_cluster` folder, where most of your efforts will take place:

```
cd hw/system/snitch_cluster
```

___Note:__ from now on, assume all paths to be relative to `hw/system/snitch_cluster`._

The Snitch cluster RTL sources are partly automatically generated from a configuration file provided in `.hjson` format. Several RTL files are templated and use the `.hjson` configuration file to fill the template entries. An example is `hw/ip/snitch_cluster/src/snitch_cluster_wrapper.sv.tpl`.
Under the `cfg` folder different configurations are provided. The `cluster.hjson` configuration instantiates 8 compute cores + 1 DMA core in the cluster. The `core.hjson` configuration instantiates a cluster with a single compute core. If you need a specific configuration you can create your own configuration file. To override the default configuration, define the following variable when you invoke Make:

```bash
# Compile the RTL for Questasim
make CFG_OVERRIDE=cfg/cluster.hjson bin/snitch_cluster.vsim
```

The previous command generates the templated RTL sources from the configuration file and compiles the RTL for Questasim simulation.

The RTL simulation model is compiled in `./work-vsim` and the [frontend server (fesvr)](https://github.com/riscv-software-src/riscv-isa-sim) and other C++ sources used throughout the testbench are compiled into `./work`. A script named `bin/snitch_cluster.vsim` was also generated (_you can have a look inside the file_) as a wrapper for the command that you would invoke to simulate your hardware with Questasim. The script takes an executable compiled for Snitch as input, and feeds it as an argument to the simulator. The testbench relies on the `fesvr` utilities to load your executable into the simulated DRAM memory.

Note the `CFG_OVERRIDE` variable need only be defined for those targets which make use of the configuration file, e.g. RTL generation.

Note that the RTL is not the only source which is generated from the configuration file. The software stack also depends on the configuration file. Make sure you always build the software with the same configuration of the hardware you are going to run it on. By default, if you compile the software after you have compiled the hardware, this is ensured automatically for you. Whenever you override the configuration file on the Make command-line, the configuration will be stored in the `cfg/lru.hjson` file. Successive invocations of Make may omit the `CFG_OVERRIDE` flag and the least-recently used configuration saved in `cfg/lru.hjson` will be picked up automatically.

___Note:__ When you have time, have a look at the `Makefile` and the commands that are executed by the `sw`, `rtl` and `bin/snitch_cluster.vsim` targets. Note that the Makefile includes the Makefrag in `util/Makefrag` at the root of this repository where plenty of things are defined._

## Building the Snitch software

To build all of the software for the Snitch cluster, run the following Make command:

```bash
make DEBUG=ON sw
```

The `sw` target first generates some C header files which depend on the hardware configuration. Hence, the need to generate the software for the same configuration as your hardware. Afterwards, it recursively invokes the `make` target in the `sw` subdirectory to build the apps/kernels which have been developed in that directory.

The `DEBUG=ON` flag is used to tell the compiler to produce debugging symbols. It is necessary for the `annotate` target, showcased in the Debugging section of this guide, to work.

## Creating your first Snitch app

### Writing the C code

Create a directory for your AXPY kernel under `sw/`:

```bash
mkdir sw/apps/axpy
```

And a `src` subdirectory to host your source code:

```bash
mkdir sw/apps/axpy/src
```

Here, create a new file named `axpy.c` with the following contents:

```C
#include "snrt.h"
#include "data.h"

// Define your kernel
void axpy(uint32_t l, double a, double *x, double *y, double *z) {
    for (uint32_t i = 0; i < l ; i++) {
        z[i] = a * x[i] + y[i];
    }
    snrt_fpu_fence();
}

int main() {
    // Read the mcycle CSR (this is our way to mark/delimit a specific code region for benchmarking)
    uint32_t start_cycle = mcycle();

    // DM core does not participate in the computation
    if(snrt_is_compute_core())
        axpy(L, a, x, y, z);

    // Read the mcycle CSR
    uint32_t end_cycle = mcycle();
}

```

The `snrt.h` file implements the snRuntime API, a library of convenience functions to program Snitch cluster based systems. These sources are located under `sw/runtime/rtl` and are automatically referenced by our compilation scripts.

___Note:__ When you have time, have a look at the files inside `sw/snRuntime` in the root of this repository to see what kind of functionality the snRuntime API defines. Note this is only an API, with some base implementations. The Snitch cluster implementation of the snRuntime for RTL simulation can be found under `sw/runtime/rtl`. It is automatically built and linked with user applications thanks to our compilation scripts._

We will have to instead create the `data.h` file ourselves. Create a `data` folder to host the data for your kernel to operate on:

```bash
mkdir sw/apps/axpy/data
```

Here, create a C file named `data.h` with the following contents:

```C
uint32_t L = 16;

double a = 2;

double x[16] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};

double y[16] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  1,  1,  1,  1,  1,  1};

double z[16];

```

In this file we hardcode the data to be used by the kernel. This data will be loaded in memory together with your application code. In general, to verify your code you may want to randomly generate the above data. Or you may want to test your kernel on different problem sizes, e.g. varying the length of the vectors, without having to manually rewrite the file. This can be achieved by generating the data header file with a Python script. You may have a look at the `sw/blas/axpy/datagen` folder in the root of this repository as an example. You may reuse several of the functions defined in `sw/blas/axpy/datagen/datagen.py`. Eventually, we will promote these functions to a dedicated Python module which can be easily reused.

### Compiling the C code

In your `axpy` folder, create a new file named `Makefile` with the following contents:

```make
APP     = axpy
SRCS    = src/axpy.c
INCDIRS = data

include ../common.mk
```

This Makefile will be invoked recursively by the top-level Makefile, compiling your source code into an executable with the name provided in the `APP` variable.

In order for the top-level Makefile to find your application, add the following line to `sw/apps.list`:

```
apps/axpy
```

Now you can recompile all software, including your newly added AXPY application, with the following command (in the `snitch_cluster` folder):

```bash
make DEBUG=ON sw
```

Note, only the targets depending on the sources you have added/modified will be recompiled.

In the `sw/apps/axpy/build` directory, you will now find your `axpy.elf` executable and some other files which were automatically generated to aid debugging. Open `axpy.dump` and search for `<x>`, `<y>` and `<z>`. You will see the addresses where the respective vectors defined in `data.h` have been allocated by the compiler. This file can also be very useful to see what assembly instructions your source code was compiled to, and correlate the traces (we will later see) with the source code.

If you want to dig deeper into how our build system works and how these files were generated you can follow the recursive Makefile invocations starting from the `sw` target in `snitch_cluster/Makefile`.

### Running your application

Run the executable on your Snitch cluster hardware in simulation:

```bash
# If it's the first time you run this the logs/ folder won't exist and you will have to create it
mkdir logs
# Run the simulation in the current terminal
bin/snitch_cluster.vsim sw/apps/axpy/build/axpy.elf
# Run the simulation in the QuestaSim GUI
bin/snitch_cluster.vsim.gui sw/apps/axpy/build/axpy.elf
```

### Debugging and benchmarking

When you run the simulation, every core will log all the instructions it executes (along with additional information, such as the value of the registers before/after the instruction) in a trace file, located in the `./logs` directory. The traces are identified by their hart ID, that is a unique ID for every hardware thread (hart) in a RISC-V system (and since all our cores have a single thread that is a unique ID per core)

The simulation logs the traces in a non-human readable format with `.dasm` extension. To convert these to a human-readable form run:

```bash
make -j traces
```

In addition to generating readable traces (`.txt` format), the above command also computes several performance metrics from the trace and appends them at the end of the trace. These can be collected into a single CSV file with the following target:

```bash
make logs/perf.csv
# View the CSV file
libreoffice logs/perf.csv
```

In this file you can find the `X_tstart` and `X_tend` metrics. These are the cycles in which a particular code region `X` starts and ends, and can hence be used to profile your code. Code regions are defined by calls to `mcycle()`. Every call to this function defines two code regions:
- the code preceding the call, up to the previous `mcycle()` call or the start of the source file
- the code following the call, up to the next `mcycle()` call or the end of the source file

The CSV file can be useful to automate collection and post-processing of benchmarking data.

Finally, debugging your program from the trace alone can be quite tedious and time-consuming. You would have to manually understand which instructions in the trace correspond to which lines in your source code. Surely, you can help yourself with the disassembly.

Alternatively, you can automatically annotate the traces with that information. With the following commands you can view the trace instructions side-by-side with the corresponding source code lines they were compiled from:

```bash
make -j annotate
kompare -o logs/trace_hart_00000.diff
```

If you prefer to view this information in a regular text editor (e.g. for search), you can open the `logs/trace_hart_xxxxx.s` files. Here, the annotations are interleaved with the trace rather than being presented side-by-side.

___Note:__ the `annotate` target uses the `addr2line` binutil behind the scenes, which needs debugging symbols to correlate instruction addresses with originating source code lines. The `DEBUG=ON` flag you specified when building the software is used to tell the compiler to produce debugging symbols when compiling your code._

The traces contain a lot of information which we might not be interested at first. To simply visualize the runtime of the compute region in our code, first create a file named `layout.csv` in `sw/apps/axpy` with the following contents:

```
            , compute
"range(0,9)",       1
9           ,

```

Then run the following commands:

```bash
# Similar to logs/perf.csv but filters all but tstart and tend metrics
make logs/event.csv
# Labels, filters and reorders the event regions as specified by an application-specific layout file
../../../util/trace/layout_events.py logs/event.csv sw/apps/axpy/layout.csv -o logs/trace.csv
# Creates a trace file which can be visualized with Chrome's TraceViewer
../../../util/trace/eventvis.py -o logs/trace.json logs/trace.csv
```

Open a Chrome browser and go to `chrome://tracing`. Here you can load the `logs/trace.json` file and graphically view the runtime of the compute region in your code. To learn more about the layout file syntax and what the Python scripts do you can have a look at the description comment at the start of the scripts themselves.

__Great, but, have you noticed a problem?__

Look into `sw/apps/axpy/build/axpy.dump` and search for the address of the output variable `<z>` :

```
Disassembly of section .bss:

80000960 <z>:
	...
```

Now grep this address in your traces:

```bash
grep 80000960 logs/*.txt
...
```

It appears in every trace! All the cores issue a `fsd` (float store double) to this address. You are not parallelizing your kernel but executing it 8 times!

Modify `sw/apps/axpy/src/axpy.c` to truly parallelize your kernel:

```C
#include "snrt.h"
#include "data.h"

// Define your kernel
void axpy(uint32_t l, double a, double *x, double *y, double *z) {
    int core_idx = snrt_cluster_core_idx();
    int offset = core_idx * l;

    for (int i = 0; i < l; i++) {
        z[offset] = a * x[offset] + y[offset];
        offset++;
    }
    snrt_fpu_fence();
}

int main() {
    // Read the mcycle CSR (this is our way to mark/delimit a specific code region for benchmarking)
    uint32_t start_cycle = mcycle();

    // DM core does not participate in the computation
    if(snrt_is_compute_core())
        axpy(L / snrt_cluster_compute_core_num(), a, x, y, z);

    // Read the mcycle CSR
    uint32_t end_cycle = mcycle();
}
```

Now re-run your kernel and compare the execution time of the compute region with the previous version.

## Code reuse

As you may have noticed, there is a good deal of code which is independent of the hardware platform we execute our AXPY kernel on. This is true for the `data.h` file and possible data generation scripts. The Snitch AXPY kernel itself is not specific to the Snitch cluster, but can be ported to any platform which provides an implementation of the snRuntime API. An example is Occamy, with its own testbench and SW development environment.

It is thus preferable to develop the data generation scripts and Snitch kernels in a shared location, from which multiple platforms can take and include the code. The `sw` directory in the root of this repository was created with this goal in mind. For the AXPY example, shared sources are hosted under the `sw/blas/axpy` directory. As an example of how these shared sources are used to build an AXPY application for a specific platform (in this case the standalone Snitch cluster) you can have a look at the `hw/system/snitch_cluster/sw/apps/blas/axpy`.

We recommend that you follow this approach also in your own developments for as much of the code which can be reused.
