
read_verilog hdl/spdif_decoder/spdif_decoder.v
read_verilog hdl/amp_frontend/amp_frontend.v

read_verilog -lib /home/jakobsen/work/opentools/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

proc;; 
memory;; 
techmap;;

dfflibmap -liberty /home/jakobsen/work/opentools/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

abc -liberty /home/jakobsen/work/opentools/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib;;

write_verilog obj/spdif_decoder.v

