# Convert Systemverilog modules to Verilog for SymbiYosys (sby)

VLIBS=../../../../../../rtl
SRC=../../../../../../rtl/axi4l_pkg.sv ../../../rtl/axi4l_timer.sv

.PHONY: all lint bmc prove cover status statusreset

all: tb.v
	sby -f tb.sby

lint: tb.v
	verilator --lint-only -Wall -Wno-VARHIDDEN $<

bmc: tb.v
	sby -f tb.sby bmc

prove: tb.v
	sby -f tb.sby prove

cover: tb.v
	sby -f tb.sby cover

status:
	sby --status -f tb.sby

statusreset:
	sby --statusreset -f tb.sby

tb.v: tb.sv $(SRC)
	sv2v --exclude=assert --libdir=$(VLIBS) $(SRC) $< > $@
