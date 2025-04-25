clear -all

# read design
analyze -sv ../../rtl/axi4l_pkg.sv
analyze -sv ../../rtl/axi4l_if.sv
analyze -sv ../../rtl/core_if.sv
analyze -sv ../../rtl/axi4l2core.sv +define+FORMAL

# read constraints
analyze -sv12 fv_axi4l2core.sv

elaborate -top axi4l2core

clock axi.aclk
reset -expression !axi.aresetn

check_assumptions
prove -all
