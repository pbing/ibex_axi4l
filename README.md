# ibex_axi4l
[RISC-V Ibex](https://ibex-core.readthedocs.io/en/latest/index.html) core with AXI4-Lite interface.

## Design
The instruction and data memory interfaces are converted to AXI4-Lite.

## Status
- simulated with Verilator
- FPGA proven
  - debugging via BSCANE2 (FPGA implementation)
  - debugging via JTAG (simulation)

## Linting with Verilator
```shell
cd soc/fpga/arty-a7-100/lint
./lint.sh
```

## Simulation with Verilator
```shell
cd soc/fpga/arty-a7-100/sim/default
./use.sh ../../sw/nettle-aes/nettle-aes.vmem
./build.sh
./sim.sh
less trace_core_00000000.log
gtkwave dump.fst
```

## Openocd
### Via BSCANE2
Start `openocd`
```shell
arty-a7-100/util% openocd -f arty-a7-openocd-cfg.tcl 
Open On-Chip Debugger 0.12.0
Licensed under GNU GPL v2
For bug reports, read
	http://openocd.org/doc/doxygen/bugs.html
force hard breakpoints
Info : ftdi: if you experience problems at higher adapter clocks, try the command "ftdi tdo_sample_edge falling"
Info : clock speed 10000 kHz
Info : JTAG tap: riscv.cpu tap/device found: 0x13631093 (mfg: 0x049 (Xilinx), part: 0x3631, ver: 0x1)
Info : datacount=2 progbufsize=8
Info : Examined RISC-V core; found 1 harts
Info :  hart 0: XLEN=32, misa=0x40101104
Info : starting gdb server for riscv.cpu on 3333
Info : Listening on port 3333 for gdb connections
Info : Listening on port 6666 for tcl connections
Info : Listening on port 4444 for telnet connections
```

## Debugging with GDB
```shell
sw/led% riscv32-unknown-elf-gdb -ex "target extended-remote localhost:3333" <executable-file>
GNU gdb (crosstool-NG 1.26.0_rc1) 13.2
Copyright (C) 2023 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "--host=x86_64-build_pc-linux-gnu --target=riscv32-unknown-elf".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<toolchains@lowrisc.org>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from led.elf...
Remote debugging using localhost:3333
```
### Cycles per Instruction (CPI)
| Program    | Cycles | Instructions | CPI  |
|------------|--------|--------------|------|
| crc_32     | 54928  | 23689        | 2.32 |
| nettle-aes | 153360 | 64380        | 2.38 |
| geom. mean |        |              | 2.35 |

## FPGA Implementation
Implementation was done with an [Arty A7-100T](https://digilent.com/shop/arty-a7-100t-artix-7-fpga-development-board/).

The clock for the SOC was 50 MHz.

Resource utilization with instruction cache and four hardware breakpoints:
| LUT  | Registers |
|------|-----------|
| 6569 | 4492      |

## Recources
- Gisselquist Technology LLC, [Building a custom yet functional AXI-lite slave](https://zipcpu.com/blog/2019/01/12/demoaxilite.html).
