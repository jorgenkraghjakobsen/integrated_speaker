# Simple counter flow pipe cleaner
source "helpers.tcl"
source "flow_helpers.tcl"
source "sky130hd/sky130hd.vars"

set global_place_density 0.99
set global_place_utilization 35 
set global_place_aspect 0.8

set synth_verilog "simple_counter_synth.v"
set design "simple_counter"
set top_module "simple_counter"
set sdc_file "simple_counter.sdc"

set core_area {0.1 0.1 42.0 52.0}
set die_area {0 0 42.2 52.2}

source -echo "flow.tcl"
