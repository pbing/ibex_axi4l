set_property SRC_FILE_INFO {cfile:/home/bernd/Projects/github.com/pbing/ibex_wb/soc/fpga/arty-a7-100/syn/ibex_soc.gen/sources_1/ip/clkgen_50mhz/clkgen_50mhz.xdc rfile:../ibex_soc.gen/sources_1/ip/clkgen_50mhz/clkgen_50mhz.xdc id:1 order:EARLY scoped_inst:crg/u_glk_gen/inst} [current_design]
current_instance crg/u_glk_gen/inst
set_property src_info {type:SCOPED_XDC file:1 line:54 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.100
