# Walkthrough

## Fast setup at IIS

### Scratch folder

First, create yourself a folder to work in on the scratch disk space. This is due to the limited size of your home directory, you can select between `/scratch`, `/scratch2`, `/scratch3`.

```bash
# Look how much free space there is in the scratch folders
df -h | grep scratch
# Pick one and create your folder in there, example :
mkdir /scratch/[your username]
# Note, contrary to your home folder, the scratch folder is local to your machine, but you can access it on any other machine like so
cd /usr/scratch/[your machine]/[your username]
# You can find the name of the machine by running
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
source ~/.venvs/snitch/bin/activate
```

Add the last line to your `~/.profile` if you want the virtual environment to be activated by default when you open a new terminal.

## Cloning and compiling Occamy

First, clone this repository on your scratch folder. We suggest you first make a private fork of the repo.

```bash
git clone https://github.com/pulp-platform/snitch.git --branch=occamy-sw
```

Now install the required Python dependencies. Make sure you have activated your virtual environment before doing so.

```
pip install -r python-requirements.txt
```

Go to the `occamy` folder, where most of your efforts will take place:

```
cd hw/system/occamy
```

___Note:__ from now on, assume all paths to be relative to `hw/system/occamy`._

To compile your code to a RISC-V executable you will need a compiler toolchain for RISC-V. There are plenty of pre-compiled RISC-V toolchains at IIS, for Snitch you can use the following GCC toolchain.

```bash
# You can add this to your ~/.profile such that you do not have to run this command every time you open a new terminal
export PATH=/home/colluca/workspace/riscv/bin/:$PATH
```

The default configuration of Occamy is too large for a fast RTL simulation. Under the `cfg` folder different configurations are provided. The `full.hjson` configuration describes the full system comprising 6 quadrants and 4 clusters per quadrant which we have taped out in Occamy, which is used by default. The `single-cluster.hjson` configuration describes a system with a single quadrant containing a single cluster. When developing a new application it is beneficial to use the latter configuration, to increase the speed of your debugging iterations. To override the default configuration, define the following variable when you invoke Make:

```bash
make CFG_OVERRIDE=cfg/single-cluster.hjson sw
```

The `sw` target first generates some C header files which depend on the hardware configuration through Solder (we will talk about this later). Hence, the need to specify the hardware configuration to be used explicitly. Afterwards, it recursively invokes the `make` target in the `sw` subdirectory to build the apps/kernels which have been developed in that directory.

It is important, that whenever you compile the software for a specific configuration, you build the hardware with the same configuration. Two steps are required to update the hardware.

Firstly, several RTL files are templated and use the `.hjson` configuration file to fill the template entries. An example is `src/occamy_top.sv.tpl`. To fill out all template files and build the RTL for your system, run the following command:

```bash
make CFG_OVERRIDE=<your_cfg_file_of_choice> update-rtl
```

Once the RTL has been generated, it has to be compiled for simulation. Different targets are provided for different simulators. For Questasim you can run:

```bash
# Compile the RTL for Questasim
make bin/occamy_top.vsim
```

Note the `CFG_OVERRIDE` variable need only be defined for those targets which make use of the template, i.e. software and RTL generation. The last `make` target compiled the previously generated RTL files and thus does not make direct use of the `.hjson` configuration file.

The RTL simulation model is compiled in `./work-vsim` and the [frontend server (fesvr)](https://github.com/riscv-software-src/riscv-isa-sim) and other C++ sources used throughout the testbench are compiled into `./work`. A script was also generated `bin/occamy_top.vsim` (_you can have a look inside the file_) as a wrapper for the command that you would invoke to simulate your hardware with Questasim.
The testbench relies on the `fesvr` utilities to load your ELF program into the simulated DRAM memory.

___Note:__ When you have time, have a look at the `Makefile` and the commands that are executed by the `sw`, `update-rtl` and `bin/occamy_top.vsim` targets. Note that the Makefile includes the Makefrag in `util/Makefrag` at the root of this repository where plenty of things are defined._

## Creating your first app for CVA6 (the host)

### Writing the C code

Create a directory for your AXPY kernel under `sw/host`:

```bash
mkdir sw/host/apps/axpy
```

And a `src` subdirectory to host your source code:

```bash
mkdir sw/host/apps/axpy/src
```

Here, create a new file named `axpy.c` with the following contents:

```C
#include "host.c"
#include "data.h"

// Define your kernel
void axpy(uint32_t l, double a, double *x, double *y, double *z) {
    for (uint32_t i = 0; i < l ; i++) {
        z[i] = a * x[i] + y[i];
    }
}

int main() {
    // Wake up the Snitch cores even if we don't use them
    reset_and_ungate_quad(0);
    deisolate_quad(0, ISO_MASK_ALL);

    // Read the mcycle CSR (this is our way to mark/delimit a specific code region for benchmarking)
    uint64_t start_cycle = mcycle();
    
    // Call your kernel
    axpy(L, a, x, y, z);
    
    // Read the mcycle CSR
    uint64_t end_cycle = mcycle();
}

```

The `host.c` file defines several convenience functions for you to use, such as `mcycle()` and the other functions used in `main`. These sources are located under `sw/host/runtime` and are automatically referenced by our compilation scripts.

We will have to instead create the `data.h` file ourselves. Create a `data` folder to host the data for your kernel to operate on:

```bash
mkdir sw/host/apps/axpy/data
```

Here, create a C file named `data.h` with the following contents:

```C
uint32_t L = 16;

double a = 2;

double x[16] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};

double y[16] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  1,  1,  1,  1,  1,  1};

double z[16];

```

In this file we hardcode the data to be used by the kernel. This data will be loaded in memory together with your application code. In general, to verify your code you may want to randomly generate the above data. Or you may want to test your kernel on different problem sizes, e.g. varying the length of the vectors, without having to manually rewrite the file. You can achieve this e.g. with a Python script. You may have a look at the `sw/blas/axpy/datagen` folder in the root of this repository as an example.

### Compiling the C code

In your `axpy` folder, create a new file named `Makefile` with the following contents:

```make
APP     = axpy
SRCS    = src/axpy.c
INCDIRS = data

include ../common.mk
```

This Makefile will be invoked recursively by the top-level Makefile, compiling your source code into an executable with the name provided in the `APP` variable.

In order for the top-level Makefile to find your application, add the following line to `sw/host/Makefile`:

```make
APPS += axpy
```

Now you can recompile all software for Occamy, including your newly added AXPY application, with the following command (in the `occamy` folder):

```bash
make DEBUG=ON sw
```

Note, only the targets depending on the sources you have added/modified will be recompiled.

The `DEBUG=ON` flag is used to tell the compiler to produce debugging symbols. It is necessary for the `annotate` target, showcased in the Debugging section of this guide, to work.

In the `sw/host/apps/axpy/build` directory, you will now find your `axpy` executable and some other files which were automatically generated to aid debugging. Open `axpy.dump` and search for `<x>`, `<y>` and `<z>`. You will see the addresses where the respective vectors defined in `data.h` have been allocated by the compiler. This file can also be very useful to see what assembly instructions your source code was compiled to, and correlate the traces (we will later see) with the source code.

If you want to dig deeper into how our build system works and how these files were generated you can follow the recursive Makefile invocations starting from the `sw` target in `occamy/Makefile`.

### Run

Run the executable on your Occamy hardware in simulation:

```bash
# If it's the first time you run this the logs/ folder won't exist and you will have to create it
mkdir logs
# Run the simulation in the current terminal
bin/occamy_top.vsim sw/host/apps/axpy/build/axpy
# Run the simulation in the QuestaSim GUI
bin/occamy_top.vsim.gui sw/host/apps/axpy/build/axpy
```

### Debugging and benchmarking

When you run the simulation, every core will log all the instructions it executes (along with additional information, such as the value of the registers before/after the instruction) in a trace file, located in the `./logs` directory. The traces are identified by their hart ID, that is a unique ID for every hardware thread (hart) in a RISC-V system (and since all our cores have a single thread that is a unique ID per core):
- `trace_hart_00000.txt` : The CVA6 trace
- `trace_hart_0000x.dasm` : The Snitch cores traces
Indeed, in Occamy, CVA6 is associated with hartid 0, and all Snitches follow.

Snitch traces are in a different format (`.dasm`), not human readable, and have to be processed with the following command first. It will fail if you forget to wake up the Snitch cores from your CVA6 code since they would not log any instruction to the trace files.

```bash
make traces
```

In addition to generating readable traces (`.txt` format), the above command also dumps several performance metrics for the Snitch cores at the end of the trace. These can be collected into a single CSV file with the following target:

```bash
make logs/perf.csv
# View the CSV file
libreoffice logs/perf.csv
```

You will notice that the CVA6 core (hart 0) presents only little information: `X_tstart` and `X_tend`. These are the cycles in which a particular code region X starts and ends. Code regions are defined by calls to `mcycle()`. Every call to this function defines two code regions:
- the code preceding the call, up to the previous `mcycle()` call or the start of the source file
- the code following the call, up to the next `mcycle()` call or the end of the source file

The CSV file can be useful to automate collection and post-processing of benchmarking data.

Finally, debugging your program from the trace alone can be quite tedious and time-consuming. You would have to manually understand which instructions in the trace correspond to which lines in your source code. Surely, you can help yourself with the disassembly.

Alternatively, you can automatically annotate the traces with that information. With the following commands you can view the trace instructions side-by-side with the corresponding source code lines they were compiled from:

```bash
make annotate
kompare -o logs/trace_hart_00000.diff
```

If you prefer to view this information in a regular text editor (e.g. for search), you can open the `logs/trace_hart_xxxxx.s` files. Here, the annotations are interleaved with the trace rather than being presented side-by-side.

## Creating your first app for Snitch (the device)

### Writing the Snitch (device) code

It is is now time to run some code on the Snitch clusters!

Create a new `axpy` folder under the `sw/device/apps` directory:
```bash
mkdir sw/device/apps/axpy
```

Again create a `src` subdirectory to host your source code:
```bash
mkdir sw/device/apps/axpy/src
```

Here, create a new file named `axpy.c`, with the following contents:

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

    // Perform some operations (e.g. clear interrupt) after wakeup
    post_wakeup_cl();

    // DM core does not participate in the computation
    if(snrt_is_compute_core()) {
        uint32_t start_cycle = mcycle();
        axpy(L, a, x, y, z);
        uint32_t end_cycle = mcycle();
    }

    // Synchronize all cores and send an interrupt to CVA6
    return_to_cva6(SYNC_ALL);
}
```

The `snrt.h` file implements the snRuntime API, a library of convenience functions to program Snitch cluster based systems. It defines `snrt_cluster_core_idx()` for instance, that reads the `mhartid` CSR and other Snitch cluster related data structures. In addition to these, it provides Occamy-specific convenience functions such as `return_to_cva6()`, which exploits the CLINT peripheral to send an interrupt to the CVA6 host.

Note also that `start_cycle` is now of type `uint32_t`. Don't forget that Snitch has a 32-bit integer ISA, while CVA6 has a 64-bit architecture. 

___Note:__ When you have time, have a look at the files inside `sw/snRuntime` in the root of this repository to see what kind of functionality the snRuntime API defines. Note this is only an API, with some base implementations. The Occamy implementation of the snRuntime can be found under `occamy/sw/device/runtime`. It is automatically built and linked with user applications thanks to our compilation scripts._

Also, copy the `data.h` file from the host directory to the device directory:
```bash
mkdir sw/device/apps/axpy/data/
cp sw/host/apps/axpy/data/data.h sw/device/apps/axpy/data/
```

### Write the CVA6 (host) code

Occamy is a heterogeneous system, which relies on a host to offload a computation to the Snitch accelerator.
We will not use CVA6 to compute the AXPY anymore, but we do need to manage the Snitch accelerator.
Edit `sw/host/apps/axpy/src/axpy.c` with the following contents:

```C
#include "host.c"

int main() {
    // Reset and ungate quadrant 0, deisolate
    reset_and_ungate_quad(0);
    deisolate_quad(0, ISO_MASK_ALL);

    // Enable interrupts to receive notice of job termination
    enable_sw_interrupts();

    // Program Snitch entry point and communication buffer
    program_snitches();

    // Wakeup Snitches with interrupts
    wakeup_snitches_cl();

    // Wait for an interrupt from the Snitches to communicate that they are done
    wait_snitches_done();
}
```

### Compile and execute your heterogeneous application

Now we need to tell our build system how to compile our heterogeneous application.

In `sw/device/apps/axpy` create a new `Makefile` with the following contents:

```make
APP     = axpy
SRCS    = src/axpy.c
INCDIRS = data

include ../common.mk
```

By now you should be familiar with the contents of this Makefile as it reflects the one you previously wrote for the CVA6 application. With this information the build scripts will generate a binary named `axpy.bin` in the `sw/device/apps/axpy/build` directory. This binary contains the code that will be executed by the Snitch cores.

Again, add your application to the list of applications the top-level Makefile should compile. Add the following line to `sw/device/Makefile`:

```make
APPS += axpy
```

It remains for us to tell the compiler which CVA6 and Snitch executables we want to "bundle" together in a heterogenous application. To do so, edit `sw/host/apps/axpy/Makefile`:

```make
APP  = axpy
SRCS = src/axpy.c
INCL_DEVICE_BINARY = true

include ../common.mk
```

It is sufficient to tell the build system that we want to build a heterogeneous executable by setting `INCL_DEVICE_BINARY` to `true`, and it will automatically look for the Snitch application with the same name as CVA6's.

You can now compile your program:

```bash
make DEBUG=ON sw
```

If you last built your hardware or software with the single-cluster configuration there is no need to respecify it explicitly on the command-line, it will be picked up automatically.

Now run your program in simulation:
```bash
bin/occamy_top.vsim sw/host/apps/axpy/build/axpy
```

You can inspect the traces as seen before:

```bash
make traces
# Annotate with the Snitch C code
make BINARY=sw/device/apps/axpy/build/axpy.elf annotate -j
# Export the performance metrics
make logs/perf.csv
# Open the results
libreoffice logs/perf.csv
```

This file contains a lot of information which we might not be interested at first. To simply visualize the runtime of the various regions (delimited by `mcycle()` calls) in our code we can use the following commands:

```bash
# Similar to logs/perf.csv but filters all but tstart and tend metrics
make logs/event.csv
# Labels, filters and reorders the event regions as specified by an application-specific layout file
../../../util/trace/layout_events.py logs/event.csv sw/host/apps/axpy/layout.csv -o logs/trace.csv
# Creates a trace file which can be visualized with Chrome's TraceViewer
../../../util/trace/eventvis.py -o logs/trace.json logs/trace.csv
```

Open a Chrome browser and go to `chrome://tracing`. Here you can load the `logs/trace.json` file and graphically view the execution of the marked regions in your code. To learn more about the layout file syntax and what the Python scripts do you can have a look at the description comment in the scripts themselves.

__Great, but, have you noticed a problem?__

Look into `sw/device/apps/axpy/build/axpy.dump` and search for the address of the output variable `<z>` :

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

Modify `sw/device/apps/axpy/src/axpy.c` to truly parallelize your kernel:

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

    if(snrt_is_dm_core())
        return 0;

    uint32_t start_cycle = mcycle();
    axpy(L / snrt_cluster_compute_core_num(), a, x, y, z);
    uint32_t end_cycle = mcycle();

    return 0;
}
```

Now re-run your kernel and compare the execution time of section 1 with the previous version.

## Code reuse

As you may have noticed, there is a good deal of code which is independent of the core we execute our AXPY kernel on. This is true for the `data.h` file and possible data generation scripts. The Snitch AXPY kernel itself is not specific to Occamy, but can be ported to any platform with provides an implementation of the snRuntime API. An example is the standalone Snitch cluster, with its own testbench and SW development environment.

It is thus preferable to develop the data generation scripts and Snitch kernels in a shared location, from which multiple platforms can take and include the code. The `sw` directory in the root of this repository was created with this goal in mind. For the AXPY example, shared sources are hosted under the `sw/blas/axpy` directory. As an example of how these shared sources are used to build an AXPY application for a specific platform (in this case the standalone Snitch cluster) you can have a look at the `hw/system/snitch_cluster/sw/apps/blas/axpy`.

We recommend that you follow this approach also in your own developments for as much of the code which can be reused.

# Troubleshooting

```bash
# When building your app
$ make DEBUG=ON update-sw
lto1: fatal error: bytecode stream in file '../../../../../sw/snRuntime/build/libsnRuntime-cluster.a' generated with LTO version 8.1 instead of the expected 7.1
# You did not compile the snRuntime with the same compiler, you need to clean it :
$ rm -rf ../../../sw/snRuntime/build
$ make DEBUG=ON update-sw
```

```bash
# When building your app
$ make DEBUG=ON update-sw
.../hw/system/occamy/sw/occamyRuntime/start_host.S:12: Error: unable to include `./
# We observed this error on certain versions of GCC please use the one recommended
$ export PATH=/home/colluca/workspace/riscv/bin/:$PATH
$ make DEBUG=ON update-sw
```

```bash
# My code does not end but enter an infinite loop...
# You can just kill it (Ctrl+C) after a given amount of time and reduce the size of the trace with
for a in `ls logs/*.dasm`; do
tmp=`head -n 2000 $a`; echo $tmp > $a
done
```