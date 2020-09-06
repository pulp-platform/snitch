# Directory Structure

The project is organized as a monolithic repository. Both hardware and software are co-located. The top-level ist structured as follows:

* `docs`: [Documentation](documentation.md) of the generator and software. Contains additional user guides.
* `hw`: All hardware components.
* `sw`: Hardware independent software, libraries, runtimes etc.
* `util`: Utility and helper scripts.

## Hardware

* `ip`: Blocks which are instantiated in the design e.g., they are not stand-alone.
    * `src`: RTL sources
    * `test`: Test-benches
* `vendor`: "Third-party" components which are updated using the vendor script. They are not (primarily) developed as part of this repository.
