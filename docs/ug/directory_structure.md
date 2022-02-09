# Directory Structure

The project is organized as a monolithic repository. Both hardware and software
are co-located. The top-level ist structured as follows:

* `docs`: [Documentation](documentation.md) of the generator and software.
  Contains additional user guides.
* `hw`: All hardware components.
* `sw`: Hardware independent software, libraries, runtimes etc.
* `util`: Utility and helper scripts.

## Hardware

* `ip`: Blocks which are instantiated in the design e.g., they are not
  stand-alone.
    * `src`: RTL sources
    * `test`: Test-benches
* `vendor`: "Third-party" components which are updated using the vendor script.
  They are not (primarily) developed as part of this repository.
* `system`: Specific systems built around Snitch components.
    * `snitch-cluster`: Single cluster with a minimal environment to run
      meaningful applications.
    * `occamy`: Multi-cluster system with an environment to run applications.

## Software

* `vendor`: Software components which come with their own license requirements
  from third parties.

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
