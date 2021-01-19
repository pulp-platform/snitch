# Getting Started

We recommend using the [Docker](ug/../docker.md) container if possible:

```
$ docker run -it -v $REPO_TOP:/repo -w /repo ghcr.io/pulp-platform/snitch
```

`$REPO_TOP` should point to the base of the cloned repository.

If that should not be possible (because of missing privileges for example) you
can install the required tools and components yourself. See [prerequisites]( Prerequisites).

Besides containing the sources for the Snitch core and surrounding cluster
infrastructure this repository also hosts systems, testbenches and related
infrastructure.

All Snitch-based systems in this repository can be found in `hw/system`. To get
accommodated with the system we recommend getting started with the cluster
testbench system. This testbench instantiates a cluster and an "infinite"
simulation memory which the cluster can access, see `hw/system/README.md`.

To build the Verilator executable of this system:

```
    cd $REPO_TOP/hw/system
    make bin/snitch_cluster.vlt
```

This places a binary called `snitch_cluster.vlt` in the `bin` folder. You can
then execute a suitable ELF file by appending it as a positional argument to the
binary:

```
    bin/snitch_cluster.vlt <path/to/riscv-elf>
```

## Prerequisites

We recommend a reasonable new Linux distribution, for example Ubuntu 18.04 with
developer tools (`build-essential`) installed.

Install the Python requirements using:

```
pip3 install --user -r python-requirements.txt
```

We are using `Bender` for file list generation. The easiest way to obtain
`Bender` is through its binary release channel:

```
curl --proto '=https' --tlsv1.2 https://fabianschuiki.github.io/bender/init -sSf | sh
```

An alternative way, if you have Rust installed is `cargo install bender`.

### Tool Requirements

- `bender >= 0.21`
- `verilator >= 4.100`

### Hardware Development

We use `verible` for style linting. Either build it from
[source](https://github.com/google/verible) or - if available for your platform
- use one of the [pre-built images](https://github.com/google/verible/releases).

# Vendored Source Directories

This repo is organized in a monolithic fashion, i.e., all resources are checked
in, we do not use git submodules or other ways of obtaining (HW) source files.
But not all IPs are developed with this repository. We rely on the `vendor` tool
to copy data from other repositories into the tree. We keep separate patches if
changes are necessary. Ideally, patches should be upstreamed to the originating
repository once things stabilize.

## Creating Patches

If you need to make changes to one of the IPs in the `hw/vendor` subdirectory
you need to obtain a set of patches which should be applied. CI will check
whether there are any changes without patches. Upon obtaining the sources the
vendor tool can automatically apply the patches for you.

To create patches you first need to commit the changes. Then, in the current
directory create a set of patches (it will create a file for each commit) for
the commit (range) you are interested:

```
git format-patch --relative -o <path/to/patch/folder> HEAD^1
```

In the vendor file specify the path to the patches:

```
patch_dir: "<path/to/patch/folder>"
```

## Updating Sources

The vendor tool supports updating the sources. If you are in a clean directory
with no changes (you can `git stash` to achieve this), the vendor tool can
automatically commit the updates (`--commit`). For the `common_cells` for
example:

```
./util/vendor.py hw/vendor/pulp_platform_common_cells.vendor.hjson --update --commit
```
