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

Go to the occamy folder, where most of your efforts will take place:

```
cd hw/system/occamy
```

___Note:__ from now on, assume all the path to be relative to `hw/system/occamy`._

First, the default configuration of Occamy is too large for a fast RTL simulation. Therefore, open `./src/occamy_cfg.hjson`, and reduce `nr_s1_quadrant` and `nr_clusters` (e.g. both to `1`). To make the changes effective, run the following command:

```bash
make update-rtl -B
```

Then compile the hardware:
```bash
# Compile the RTL for Questasim
make bin/occamy_top.vsim
```

This `make` target compiled the RTL simulation model in `./work-vsim` and the [frontend server (fesvr)](https://github.com/riscv-software-src/riscv-isa-sim) C++ sources into `./work`. It also generated a script `./bin/occamy_top.vsim` (_you can read it_) that you can use to start a Questasim session initialized with the ELF of the app/kernel you want to run.
This script relies on the `fesvr` utilities to connect to the RTL simulation and load your ELF program into the simulated DRAM memory.

You can now setup your toolchain. There are plenty of pre-compiled RISC-V toolchains at IIS, for Snitch you should use the following GCC toolchain.

```bash
# You can add this to your ~/.profile such that you do not have to run this command every time you open a new terminal
export PATH=/home/colluca/workspace/riscv/bin/:$PATH
```

You can now compile some applications for Occamy:

```bash
$ make DEBUG=ON update-sw
```

___Note:__ When you have time, give a look at the `Makefile` and the commands that have been executed by the `update-sw` and `./bin/occamy_top.vsim` targets (the latter only if you are interested in how the RTL compilation flow works), note that the Makefile includes the Makefrag in `util/Makefrag` at the root of this repository where plenty of things are defined._

The `update-sw` target firt updated the C headers which depend on the hardware configuration through Solder (we will talk about this later), before calling the `make` target in `./sw/Makefile` to build the apps/kernels in the `./sw` directory. Note that all Occamy software is compiled with `CMake` so you might also want to look into `./sw/CMakeLists.txt` in this directory.

## Creating your first app for CVA6

### Writing the C code

Create a C file in `./sw/src` with the following contents, and call it `axpy.c`.

```C
/* ./sw/src/axpy.c */

#include "host.h"
#include "axpy.h"

// Define your kernel
void axpy(uint32_t l, double *x, double *y, double a, double *z) {
    for (uint32_t i = 0; i < l ; i++) {
        z[i] = a * x[i] + y[i];
    }
}

int main() {
    // Wake up the snitch cores even if we don't use them
    reset_and_ungate_quad(0);
    deisolate_quad(0, ISO_MASK_ALL);
    // Read the mcycle CSR (this is our way to mark/delimit a specific code region for benchmarking)
    uint64_t start_time = __rt_get_timer();
    // Call your kernel
    axpy(L, x, y, a, z);
    // Read the mcycle CSR
    uint64_t end_time = __rt_get_timer();
}
```

Create a C file in `./sw/src` with the following contents, and call it `axpy.h`.


```C
/* ./sw/src/axpy.h */

#ifndef AXPY_DATA_H_
#define AXPY_DATA_H_

// Statically define the data which will be used for the computation
// (this will be loaded into DRAM together with the binary)

#define L 16

double a = 2;
double x[L] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
double y[L] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  1,  1,  1,  1,  1,  1};
double z[L];

uint32_t finished = 0;

#endif // AXPY_DATA_H_
```

### Compiling  the C code

Go to `./sw/CMakeLists.txt` and add the following line at the end of the file:

```CMake
add_host_executable(axpy src/axpy.c)
```

The `add_host_executable` function defines an executable for the CVA6 core, its first argument is the name of the executable to create, and the following argument is a list of C files to compile for this executable. 

Now recompile the sources.

```bash
$ make DEBUG=ON update-sw
```

Your newly created executable will be `./sw/build/axpy`.

___Note__: `add_host_executable` also disassembles your executable, dumping its contents to `./sw/build/axpy.dump`. Have a look at this file. It can be very useful to see what assembly instructions your source code was compiled to, and correlate the traces (we will later see) with the source code._

### Run

Run the executable with the RTL simulation:

```bash
# If it's the first time you run this the logs/ folder won't exist and you will have to create it
$ mkdir logs
# Run the simulation in the current terminal
$ ./bin/occamy_top.vsim sw/build/axpy
# Run the simulation in the QuestaSim GUI
$ ./bin/occamy_top.vsim.gui sw/build/axpy
```

### Debugging and benchmarking

When you run the simulation, every core will log all the instruction it executes (along with additional information, such as the value of the registers before/after the instruction) in a trace file, located in the `./logs` directory. The traces are identified by their hart ID, that is a unique ID for every hardware thread (hart) in a RISC-V system (since all our cores have a single thread that is a unique ID per core):
- trace_hart_00000.txt : The CVA6 trace
- trace_hart_0000x.dasm : The Snitch cores traces
Indeed, in Occamy, CVA6 is associated with hartid 0, and all Snitches follow.

Snitch traces are in a different format (`.dasm`), not human readable, and have to be processed with the following command first. The following command will fail if you forget to wake up the Snitch cores since their trace files would be empty.

```bash
$ make traces
```

In addition to generating readable traces (`.txt` format), the above command also dumps several performance metrics for the core at the end of the trace. These can be collected into a single CSV file with the following target:

```bash
make perf-csv
# View the CSV file
libreoffice logs/perf_metrics.csv
```

You will notice that the CVA6 core (hart 0) presents only little information: `X_tstart` and `X_tend`. These are the cycles in which a particular code region X starts and ends. Code regions are defined by calls to `__rt_get_timer()`. Every call to this function defines two code regions:
- the code preceding the call, up to the previous call or the start of the source file
- the code following the call, up to the next call or the end of the source file

The CSV file can be useful to automate collection and post-processing of benchmarking data.

Finally, debugging your program from the trace alone can be quite tedious and time-consuming. You would have to manually understand which instructions in the trace correspond to which lines in your source code. Surely, you can help yourself with the disassembly.

Alternatively, you can automatically annotate the traces with that information. With the following commands you can view the trace instructions side-by-side with the corresponding source code line which it was compiled from:

```bash
$ make BINARY=sw/build/axpy annotate 
$ kompare -o logs/trace_hart_00000.diff
```

## Creating your first app for Snitch

### Write the Snitch accelerator (device) core

It is is now time to run C code on the Snitch cluster! We will run our axpy on Snitch for instance.

You should already have `./sw/src/axpy.c` and `./sw/src/axpy_data.h`. Please create a file `./sw/src/axpy_snitch.c`.

```C
/* ./sw/src/axpy_snitch.c */

#include "device.h"

#include "axpy_data.h"

// Define your kernel
void axpy(uint32_t l, double *x, double *y, double a, double *z) {
    for (uint32_t i = 0; i < l ; i++) {
        z[i] = a * x[i] + y[i];
    }
}

int main() {

    if(snrt_is_dm_core())
        return 0;
    
    uint32_t start_time = __rt_get_timer();
    axpy(L, x, y, a, z);
    uint32_t end_time = __rt_get_timer();

    return 0;
}
```

Note two things:

First, we now include `device.h` present in `./sw/occamyRuntime`. This file defines __the functions that are must accesible to all Snitch cores in Occamy__. It defines `get_communication_buffer` for instance, that exploits an hardware property of Occamy (the presence of SoC scratch registers). This file also includes the `snRuntime` (by including `sw/snRuntime/include/snrt.h`). The `snRuntime` defines __the functions that must be accessible to all Snitch cores in a Snitch cluster based system__. It defines `snrt_cluster_core_idx` for instance, that reads the `mhartid` CSR and other Snitch cluster related data structures.

Second, `start_time` is now of type `uint32_t`. Don't forget that Snitch embbeds 32-bits int registers and 64-bits float registers!

___Note:__ When you have time, give a look at the files inside `/sw/snRuntime/include` to see what can of functionnalities of the Snitch harware you can use for your kernels._

### Write the CVA6 (host) code

On the CVA6 side now, you don't want to compute AXPY anymore but you will have to monitor the Snitch cluster:

```C
/* ./sw/src/axpy.c */

#include "host.h"

#include "axpy_data.h"

int main() {
    // Un-assert reset on Snitches
    reset_and_ungate_quad(0);
    // Let them communicate with the AXI bus
    deisolate_quad(0, ISO_MASK_ALL);
    // Pass them the pointer to their main function
    program_snitches();
    // Wake them up with an interrupt
    wakeup_snitches();

    wait_snitches_done();
}
```

### Compile and execute your heterogeneous app

Now you need to define your kernel as heterogeneous. Go to `./sw/CMakeLists.txt` and add the following line at the end of the file:

```CMake
add_heterogeneous_executable(axpy src/axpy.c src/axpy_snitch.c)
```

You can now compile and execute your program:

```bash
$ make DEBUG=ON update-sw
$ ./bin/occamy_top.vsim sw/build/axpy
```

You can watch the traces as before :

```bash
$ make traces
# Annotate with the Snitch C code
$ make BINARY=sw/build/sn_axpy.elf annotate  -B
# Export the performance counter
$ make perf-csv
# Open the results
$ libreoffice logs/perf_metrics.csv
```

In this file you can now see the performance metrics inside the differents sections of the code (0=startup, 1=axpy, 2=exit). Note that since CVA6 does not call to `__rt_get_timer` anymore, it only contains one section.

__Great, but, have you noticed a problem?__

Look into `./sw/build/sn_axpy.elf.dump` and search for the address of the output variable `<z>` :

```
Disassembly of section .bss:

80000960 <z>:
	...
```

Now grep this address in your traces :

```bash
$ grep 80000960 logs/*.txt
...
```

It appears in every trace! All the cores issue a `fsd` (float store double) to this address. You are not parallelizing your kernel but executing it 8 times!

Modify your `./sw/src/axpy_snitch.c` to truly parallelize your kernel :

```C
/* ./sw/src/axpy_snitch.c */

#include "device.h"

#include "axpy_data.h"

// Define your kernel
void axpy(uint32_t core_idx uint32_t core_num, uint32_t l, double *x, double *y, double a, double *z) {
    // Let each core compute only a subset of the result
    uint32_t portion_l = l / core_num;
    for (uint32_t i = portion_l * core_idx; i < portion_l * (core_idx+1); i++) {
        z[i] = a * x[i] + y[i];
    }
}

int main() {

    if(snrt_is_dm_core())
        return 0;

    uint32_t core_idx = snrt_cluster_idx();
    uint32_t core_num = snrt_cluster_compute_core_num();

    uint32_t start_time = __rt_get_timer();
    axpy(core_idx, L, x, y, a, z);
    uint32_t end_time = __rt_get_timer();

    return 0;
}
```

Now re-run your kernel and compare the execution time of section 1 with the precedent version.

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