## Fast setup at IIS

### Scratch folder

First, create yourself a scratch folder to work in it. This is due to the limited size of your home directory, you can select between `/scratch`, `/scratch2`, `/scratch3`.

```bash
# Look how much free space there is in the scratch folders
df -h | grep scratch
# Pick one and create your folder in there, example :
mkdir /scratch/[your username]
# Note, contrary to your home folder, the scratch folder is local to your machine, but you can access it on any other m chine like so
cd /usr/scratch/[your machine]/[your username]
# You can find the name of the machine by running
hostname
# (Note, keep only the name before .ee.ethz.ch)
```

### Binaries

At IIS the default version of some tools (`gcc`, `cmake`, ...) might be too old for certain projects. You will need to setup your own default binary for these tools :

```bash
# Create your own bin folder in your home directory
mkdir ~/bin && cd ~/bin
# There you can change the default binaries for your user
ln -s /usr/pack/gcc-9.2.0-af/linux-x64/bin/gcc gcc
ln -s /usr/pack/gcc-9.2.0-af/linux-x64/bin/g++ g++
ln -s /usr/sepp/bin/cmake-3.18.1 cmake
# Now you need to add this folder to your PATH :
# Open ~/.profile and add the line
export PATH=~/bin:$PATH
```

## Cloning and compiling Occamy

First, clone this repository on your scratch folder (TODO create fork?).

```bash
git clone https://github.com/pulp-platform/snitch.git --branch=occamy_sw

# Go to the occamy folder
cd hw/system/occamy
```

___Note:__ from now on, assume all the path to be relative to `hw/system/occamy`._

First, the default configuration of Occamy is too large for a fast RTL simulation. Therefore, open `./src/occamy_cfg.hjson`, and reduce `nr_s1_quadrant` and `nr_clusters` (e.g. both to `1`). To make the changes effective, run the following command:

```
make update-rtl -B
```

Then compile the hardware :
```bash
# Compile the RTL for Questasim
make bin/occamy_top.vsim
```


This `make` target compiled the RTL simulation model in `./work-vsim` and the [fesvr](https://github.com/riscv-software-src/riscv-isa-sim) into `./work`. It has also generated a script `./bin/occamy_top.vsim` (_you can read it_) that you can use to start a Questasim session initialized with the ELF of the app/kernel you want to run.
This script relies on the `fesvr` utilities to connect to the RTL simulation and load your ELF programs into the simulated CPUs.

You can now setup your toolchain, there are plenty of RISC-V toolchain pre-compiled at IIS, find them using the `riscv` command.



```bash
# Open the help
riscv
# For this walkthough you will need to open a bash session with the pulp riscv32 and a bare-metal riscv64 toolchain :
riscv -pulp-gcc-2.6.0 -riscv64-gcc-11.2.0 bash
```

If you want to add this riscv toolchain to your default terminal without using the `riscv` command, then echo the PATH in this new bash session and add the relevant folders to your `~/.profile`.

```bash
# These are the path added by the riscv command, you can add them in your ~/.profile, but remember it if one day you need to change the toolchain you use!
export PATH=/home/colluca/workspace/riscv/bin/riscv32-unknown-elf-gcc:$PATH
```

You can now compile some applications for Occamy

```bash
make DEBUG=ON update-sw
```

___Note:__ When you have time, give a look at the `Makefile` and the commands that have been executed for these `update-sw` (in priority) and `bin/occamy_top.vsim` (only if you are interested by how does the RTL compilation flow works), note that the Makefile includes the Makefrag in `util/Makefrag` at the root of this repository where plenty of things are defined._

The `update-sw` target updated first the headers through Solder (we will talk about it later), before calling the `make` target in `./sw/Makefile`. Note that every Occamy software is compiled with `Cmake` so you will also want (__very soon__) to look at `./sw/CMakeLists.txt` below this directory.

## Creating your first app for CVA6

### Writing the C code

Create a C file in `./sw/src`, and call it `axpy.c`.
Now write your first code for CVA6 :

```C
/* ./src/axpy.c */

#include ///

// Define your kernel
void axpy(uint32_t l, double *x, double *y, double a, double *z) {
    for (int i = 0; i < l ; i++) {
        z[i] = a * x[i] + y[i];
    }
}

int main() {
    // Wake up the snitch even if we don't use them
    reset_and_ungate_quad(0);
    deisolate_quad(0, ISO_MASK_ALL);
    // Read the timer CSR
    uint64_t start_time = __rt_get_timer();
    // Call your kernel
    axpy(L, x, y, a, z);
    // Read the timer CSR
    uint64_t end_time = __rt_get_timer();
}
```

### Cmopiling  the C code

Go to `./sw/CMakeLists.txt` and add the following line at the end of the file :

```
add_host_executable(axpy src/axpy.c)
```

The `add_host_executable` function defines an executable for the CVA6 core, its first argument is the name of the executable to create, and the next arguments are the C files to compile for this executable. 

Now recompile the sources.

```bash
make DEBUG=ON update-sw
```

You can find your newly created executable in `./sw/build/axpy`.

___Note__: add_host_executable also creates a dump of your executable, you may want to look into `./sw/build/axpy.dump` to see how it has been compiled in assembly._

### Run

Run the executable with the RTL simulation :

```bash
./bin/occamy_top.vsim sw/build/axpy
```

When you run the simulation with an executable, your traces will be logged in `./logs`. Each log is identified
- trace_hart_00000.txt : The CVA6 traces
- trace_hart_0000x.dasm : The snitch cores traces
Indeed, in hardware, CVA6 is associated with hartid 0.

Snitch traces are in a different format, not human readble, and have to be processed first. The following command will fail if you forget to wake up your Snitch cores since their traces files would be empty.

```bash
make traces
```

In addition to generating readable traces, the above command also dumps several performance metrics to file for each hart. These can be collected into a single CSV file with the following target:

```bash
make perf-csv
# Read the csv file
libreoffice logs/perf_metrics.csv
```

You will notice that CVA6 (hart 0) contains only few informations : `x_tstart` and `x_tend`. These are the cycles in which a section starts and end, at each call to `__rt_get_timer()`, you create a new section.

You can annotate the traces with the C code :

```bash
make BINARY=sw/build/axpy annotate 
kompare -o logs/trace_hart_00000.diff
```