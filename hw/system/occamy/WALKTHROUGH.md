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

### Binaries

At IIS the default version of some tools (`gcc`, `cmake`, ...) might be too old for certain projects. You will need to setup your own default binary for these tools:

```bash
# Create your own bin folder in your home directory
mkdir ~/bin && cd ~/bin
# There you can change the default binaries for your user
ln -s /usr/pack/gcc-9.2.0-af/linux-x64/bin/gcc gcc
ln -s /usr/pack/gcc-9.2.0-af/linux-x64/bin/g++ g++
ln -s /usr/sepp/bin/cmake-3.18.1 cmake
# Now you need to add this folder to your PATH:
# Open ~/.profile and add the line
export PATH=~/bin:$PATH
```

## Cloning and compiling Occamy

First, clone this repository on your scratch folder. We suggest you first make a private fork of the repo.

```bash
git clone https://github.com/pulp-platform/snitch.git --branch=occamy-sw

# Go to the occamy folder
cd hw/system/occamy
```

___Note:__ from now on, assume all the path to be relative to `hw/system/occamy`._

First, the default configuration of Occamy is too large for a fast RTL simulation. Therefore, open `./src/occamy_cfg.hjson`, and reduce `nr_s1_quadrant` and `nr_clusters` (e.g. both to `1`). To make the changes effective, run the following command:

```
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
export PATH=/home/colluca/workspace/riscv/bin/riscv32-unknown-elf-gcc:$PATH
```

You can now compile some applications for Occamy:

```bash
make DEBUG=ON update-sw
```

___Note:__ When you have time, give a look at the `Makefile` and the commands that have been executed by the `update-sw` and `bin/occamy_top.vsim` targets (the latter only if you are interested in how the RTL compilation flow works), note that the Makefile includes the Makefrag in `util/Makefrag` at the root of this repository where plenty of things are defined._

The `update-sw` target firt updated the C headers which depend on the hardware configuration through Solder (we will talk about this later), before calling the `make` target in `./sw/Makefile` to build the apps/kernels in the `./sw` directory. Note that all Occamy software is compiled with `CMake` so you might also want to look into `./sw/CMakeLists.txt` in this directory.

## Creating your first app for CVA6

### Writing the C code

Create a C file in `./sw/src` with the following contents, and call it `axpy.c`.

```C
/* ./src/axpy.c */

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
/* ./src/axpy.h */

// Statically define the data which will be used for the computation
// (this will be loaded into DRAM together with the binary)
#define L 10
double a = 1;
double x[L] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
double y[L] = {9, 8, 7, 6, 5, 4, 3, 2, 1, 0};
double z[L];
```

### Compiling  the C code

Go to `./sw/CMakeLists.txt` and add the following line at the end of the file:

```
add_host_executable(axpy src/axpy.c)
```

The `add_host_executable` function defines an executable for the CVA6 core, its first argument is the name of the executable to create, and the following argument is a list of C files to compile for this executable. 

Now recompile the sources.

```bash
make DEBUG=ON update-sw
```

Your newly created executable will be `./sw/build/axpy`.

___Note__: `add_host_executable` also disassembles your executable, dumping its contents to `./sw/build/axpy.dump`. Have a look at this file. It can be very useful to see what assembly instructions your source code was compiled to, and correlate the traces (we will later see) with the source code._

### Run

Run the executable with the RTL simulation:

```bash
# If it's the first time you run this the logs/ folder won't exist and you will have to create it
mkdir logs
# Run the simulation
./bin/occamy_top.vsim sw/build/axpy
```

### Debugging and benchmarking

When you run the simulation, every core will log all the instruction it executes (along with additional information, such as the value of the registers before/after the instruction) in a trace file, located in the `./logs` directory. The traces are identified by their hart ID, that is a unique ID for every hardware thread (hart) in a RISC-V system (since all our cores have a single thread that is a unique ID per core):
- trace_hart_00000.txt : The CVA6 trace
- trace_hart_0000x.dasm : The Snitch cores traces
Indeed, in Occamy, CVA6 is associated with hartid 0, and all Snitches follow.

Snitch traces are in a different format (`.dasm`), not human readable, and have to be processed with the following command first. The following command will fail if you forget to wake up the Snitch cores since their trace files would be empty.

```bash
make traces
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
make BINARY=sw/build/axpy annotate 
kompare -o logs/trace_hart_00000.diff
```