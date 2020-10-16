# Arty S7 Hardware Repository

This repository contains Vivado projects for all demos for the Arty S7.

For more information about the Arty S7, visit its [Resource Center](https://reference.digilentinc.com/reference/programmable-logic/Arty-S7/start) on the Digilent Wiki.

Each demo contained in this repository is documented on the Digilent Wiki, links in the table below.

| Wiki Link | Description |
|-----------|-------------|
| [Arty S7 General Purpose I/O Demo](https://reference.digilentinc.com/reference/programmable-logic/arty-s7/demos/gpio) | This project is a Vivado demo using the Arty S7's LEDs, RGB LED's, pushbuttons, and USB UART bridge |
| [Arty S7 XADC Analog to Digital Converter Demo](https://reference.digilentinc.com/reference/programmable-logic/arty-s7/demos/xadc) | This simple XADC Demo project demonstrates a simple usage of the Arty S7's XADC pin capability |
| [Arty S7 Petalinux Demo](https://reference.digilentinc.com/reference/programmable-logic/arty-s7/demos/petalinux) | A Petalinux project that includes different BSP features by default |

## Repository Description

This repository contains the Vivado projects and hardware designs for all of the demos that we provide for the Arty S7. As some demos also require software sources contained in Vitis workspaces, this repository should not be used directly. The [Arty S7](https://github.com/Digilent/Arty-S7) repository contains all sources for these demos across all tools, and pulls in all of this repository's sources by using it as a submodule.

For instructions on how to use this repository with git, and for additional documentation on the submodule and branch structures used, please visit [Digilent FPGA Demo Git Repositories](https://reference.digilentinc.com/reference/programmable-logic/documents/git) on the Digilent Wiki. Note that use of git is not required to use this demo. Digilent recommends the use of project releases, for which instructions can be found in each demo wiki page, linked in the table of demos, above.

Demos were moved into this repository during 2020.1 updates. History of these demos prior to these updates can be found in their old repositories, linked below:
* https://github.com/Digilent/Arty-S7-25-GPIO/
* https://github.com/Digilent/Arty-S7-50-GPIO/
* https://github.com/Digilent/Arty-S7-25-XADC/
* https://github.com/Digilent/Arty-S7-50-XADC/
* https://github.com/Digilent/Petalinux-Arty-S7-50 and https://github.com/Digilent/Arty-S7-50-base-linux
