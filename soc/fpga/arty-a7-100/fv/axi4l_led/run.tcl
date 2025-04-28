clear -all

# read design
analyze -sv ../../rtl/axi4l_pkg.sv
analyze -sv ../../rtl/axi4l_if.sv
analyze -sv ../../rtl/core_if.sv
analyze -sv ../../rtl/axi4l_led.sv +define+FORMAL

# read constraints
analyze -sv12 fv_axi4l_led.sv

elaborate -top axi4l_led

clock axi.aclk
reset -expression !axi.aresetn

check_assumptions
prove -all
