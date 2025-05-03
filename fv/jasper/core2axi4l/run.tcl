clear -all

# read design
analyze -sv ../../../rtl/axi4l_pkg.sv
analyze -sv ../../../rtl/axi4l_if.sv
analyze -sv ../../../rtl/core_if.sv
analyze -sv ../../../rtl/core2axi4l.sv +define+FORMAL

# read constraints
analyze -sv12 fv_core2axi4l.sv

elaborate -top core2axi4l

clock core.clk
reset -expression !core.rst_n

check_assumptions
prove -all
