
BASEDIR=$(shell pwd)
# TARGET : fpga_xo2_open_tools | fpga_xo2 | sky130 | sim

#TARGET=fpga_xo2

TARGET=fpga_xo2_open_tools
#TARGET=sky130

# Project settings 
PROJ=amp_frontend
TOP=amp_frontend

## Walk all verilog files in a given directory
SOURCEDIR = hdl/amp_frontend
SRC := $(shell ls $(PWD)/$(SOURCEDIR)/*.v) 

ifeq ($(TARGET),fpga_xo2)
  FAM=MachXO2
  DEVICE=LCMXO2-1200HC
  #DEVICE=LCMXO2-1200HC
  PKG=QFN32
  SPEED=5
endif

ifeq ($(TARGET),sky130)
  STD_CELL_LIBRARY=sky130_fd_sc_hd
  PDK_ROOT=/OpenLane/home/jakobsen/work/opentools/open_pdks/sky130/
endif

HDL=$(BASEDIR)/hdl

OBJ=obj/hdl/$(TOP)/$(TARGET)

ifeq ($(TARGET),sky130)
all:
	synth 

synth:
	mkdir -p $(OBJ) ;\
	cd $(OBJ) ;\
	echo "read_verilog $(SRC)" > $(PROJ)_yosys.cmd ;\
    echo "read_verilog -lib /home/jakobsen/work/opentools/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v " >> $(PROJ)_yosys.cmd ;\
	echo "proc;;" >>  $(PROJ)_yosys.cmd ;\
	echo "memory;;" >>  $(PROJ)_yosys.cmd ;\
	echo "techmap;;" >>  $(PROJ)_yosys.cmd ;\
    echo "dfflibmap -liberty /home/jakobsen/work/opentools/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib "  >>  $(PROJ)_yosys.cmd ;\
	echo "abc -liberty /home/jakobsen/work/opentools/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib "  >>  $(PROJ)_yosys.cmd ;\
	echo "write_verilog $(PROJ)_synth.v " >> $(PROJ)_yosys.cmd ;\
	yosys -s $(PROJ)_yosys.cmd 

openroad:
	cd $(OBJ) ;\
	echo "source /home/jakobsen/work/opentools/OpenROAD/test/helpers.tcl" > $(PROJ)_sky130hd.tcl ;\
	echo "source /home/jakobsen/work/opentools/OpenROAD/test/flow_helpers.tcl" >> $(PROJ)_sky130hd.tcl ;\
	echo "source /home/jakobsen/work/asic/integrated_speaker/sky130hd/sky130hd.vars" >> $(PROJ)_sky130hd.tcl ;\
	echo "set global_place_density 0.99" >> $(PROJ)_sky130hd.tcl ;\
	echo "set global_place_utilization 35" >> $(PROJ)_sky130hd.tcl ;\
	echo "set global_place_aspect 0.8" >> $(PROJ)_sky130hd.tcl ;\
	echo "set synth_verilog $(PROJ)_synth.v" >> $(PROJ)_sky130hd.tcl ;\
	echo "set design amp_frontend" >> $(PROJ)_sky130hd.tcl ;\
	echo "set core_area {0.1 0.1 150.0 150.0}" >> $(PROJ)_sky130hd.tcl ;\
	echo "set core_area {0.0 0.0 150.1 150.1}" >> $(PROJ)_sky130hd.tcl ;\
	echo "source -echo \"/home/jakobsen/work/opentools/OpenROAD/test/flow.tcl\"" >> $(PROJ)_sky130hd.tcl ;\
	openroad $(PROJ)_sky130hd.tcl

endif 


ifeq ($(TARGET),fpga_xo2)

##################################################################################
# FPGA target xo2 Lattices
# Tool path setup 

BINFPGA=/usr/local/diamond/3.12/bin/lin64
ISPFPGA=/usr/local/diamond/3.12/ispfpga/bin/lin64
PRGFPGA=/usr/local/programmer/diamond/3.12/bin/lin64

clean :
	rm -rf $(OBJ)/*
	
all : synth map pnr bitgen 
        
synth :
	mkdir -p $(OBJ) ;\
	cd $(OBJ) ;\
	echo "-a $(FAM)" > $(PROJ).synproj ;\
	echo "-d $(DEVICE)" >>  $(PROJ).synproj ;\
	echo "-t $(PKG)" >>  $(PROJ).synproj ;\
	echo "-s $(SPEED)" >>  $(PROJ).synproj ;\
	echo "-frequency 50" >> $(PROJ).synproj ;\
	echo "-optimization_goal Balanced" >> $(PROJ).synproj ;\
	echo "-bram_utilization 100" >> $(PROJ).synproj ;\
	echo "-ramstyle Auto" >> $(PROJ).synproj ;\
	echo "-romstyle auto" >> $(PROJ).synproj ;\
	echo "-dsp_utilization 100" >> $(PROJ).synproj ;\
	echo "-use_dsp 1" >> $(PROJ).synproj ;\
	echo "-use_carry_chain 1" >> $(PROJ).synproj ;\
	echo "-carry_chain_length 0" >> $(PROJ).synproj ;\
	echo "-force_gsr Auto" >> $(PROJ).synproj ;\
	echo "-resource_sharing 1" >> $(PROJ).synproj ;\
	echo "-propagate_constants 1" >> $(PROJ).synproj ;\
	echo "-remove_duplicate_regs 1" >> $(PROJ).synproj ;\
	echo "-mux_style Auto" >> $(PROJ).synproj ;\
	echo "-max_fanout 8" >> $(PROJ).synproj ;\
	echo "-fsm_encoding_style Auto" >> $(PROJ).synproj ;\
	echo "-twr_paths 3" >> $(PROJ).synproj ;\
	echo "-fix_gated_clocks 1" >> $(PROJ).synproj ;\
	echo "-loop_limit 1950" >> $(PROJ).synproj ;\
	echo "-use_io_insertion 1" >> $(PROJ).synproj ;\
	echo "-resolve_mixed_drivers 0" >> $(PROJ).synproj ;\
	echo "-use_io_reg auto" >> $(PROJ).synproj ;\
	echo "-lpf 1" >> $(PROJ).synproj ;\
	echo "-p $(BASEDIR)" >> $(PROJ).synproj ;\
	echo "-ver $(HDL)/$(PROJ)/amp_frontend.v" >> $(PROJ).synproj ;\
	echo "-ver $(HDL)/$(PROJ)/amp_state_control.v" >> $(PROJ).synproj ;\
	echo "-ver $(HDL)/$(PROJ)/amp_i2c_master.v" >> $(PROJ).synproj ;\
	echo "-ver $(HDL)/$(PROJ)/clk_div.v" >> $(PROJ).synproj ;\
	echo "-ver $(HDL)/$(PROJ)/timer_simple.v" >> $(PROJ).synproj ;\
	echo "-ver $(HDL)/sinetable/rom_sine.v" >> $(PROJ).synproj ;\
	echo "-ver $(HDL)/$(PROJ)/amp_i2s_interface.v" >> $(PROJ).synproj ;\
	echo "-ver $(HDL)/spdif_decoder/spdif_decoder.v" >> $(PROJ).synproj ;\
	echo "-ver $(HDL)/pll_x4.v" >> $(PROJ).synproj ;\
	echo "-top $(TOP)" >> $(PROJ).synproj ;\
	echo "-ngd $(PROJ).ngd" >> $(PROJ).synproj ;\
	echo "-sdc $(HDL)/$(PROJ)/$(PROJ).sdc" >> $(PROJ).synproj ;\
	$(ISPFPGA)/synthesis -f $(PROJ).synproj 
	
map :   
	cat $(HDL)/$(PROJ)/*.lpf >> $(OBJ)/$(PROJ).lpf ;\
	cd $(OBJ) ;\
	$(ISPFPGA)/map $(PROJ).ngd -a $(FAM) -p $(DEVICE) -t $(PKG) -s $(SPEED) -oc Commercial \
	-o $(PROJ)_map.ncd -c 0 \
	-pr $(PROJ).prf \
	-mp $(PROJ).mrp \
	-lpf $(PROJ).lpf 

pnr :	
	cd $(OBJ) ;\
	echo "-w -l 5 -i 6  -n 1 -t 1 -s 1 -c 0 -e 0 -exp parUseNBR=1:parCDP=0:parCDR=0:parPathBased=OFF" > $(PROJ).p2t; \
	echo "-rem -distrce -log $(COMP).log -o $(COMP).csv -pr $(PROJ).prf" > $(PROJ).p3t ;\
	$(BINFPGA)/mpartrce -p $(PROJ).p2t \
	-f $(PROJ).p3t \
	-tf $(PROJ).pt $(PROJ)_map.ncd $(PROJ).ncd
	
bitgen : 
	cd $(OBJ) ;\
	$(ISPFPGA)/bitgen -g RamCfg:Reset -path $(BASEDIR) \
	-w $(PROJ).ncd \
	-jedec \
	$(PROJ).prf
 
p :
	$(PRGFPGA)/pgrcmd 
	 
flash : 
	cp program_flow.xcf $(OBJ) ;\
	cd $(OBJ) ;\
	sed -i '/<File/c\<File>$(BASEDIR)/$(OBJ)/$(PROJ).jed</File>' program_flow.xcf ;\
	$(PRGFPGA)/pgrcmd -infile program_flow.xcf \
	-cabletype USB2 -portaddress FTUSB-0 
endif

ifeq ($(TARGET),fpga_xo2_open_tools)
##################################################################################
# FPGA Lattice machXO2 using open tools 
# yosys - nextpnr-machxo2 - ecppack - openfpgaloader 

clean :
	rm -rf $(OBJ)/*
	
all : synth pnr pack prog 

synth : yosys_$(PROJ).ys
	mkdir -p $(OBJ) ;\
	cd $(OBJ) ;\
	yosys yosys_$(PROJ).ys 

yosys_$(PROJ).ys:
	mkdir -p $(OBJ) ;\
	printf "#auto generated yosys script \n\
	read_verilog $(HDL)/$(PROJ)/amp_frontend.v \n\
	read_verilog $(HDL)/$(PROJ)/amp_state_control.v \n\
	read_verilog $(HDL)/$(PROJ)/amp_i2c_master.v \n\
	read_verilog $(HDL)/$(PROJ)/clk_div.v \n\
	read_verilog $(HDL)/$(PROJ)/timer_simple.v \n\
	#read_verilog $(HDL)/sinetable/rom_sine.v \n\
	read_verilog $(HDL)/$(PROJ)/amp_i2s_interface.v \n\
	read_verilog $(HDL)/spdif_decoder/spdif_decoder.v \n\
    #read_verilog $(HDL)/pll_x4.v \n\
	hierarchy -top amp_frontend -libdir .\n\
	synth_machxo2 -json $(PROJ).json \n\
	#shell \n\
	" > $(OBJ)/$@ 
		
pnr: 
	cd $(OBJ) ;\
	nextpnr-machxo2 --1200 --package QFN32 --json $(PROJ).json \
	--write $(PROJ)_pnr.json --textcfg $(PROJ)_pnr.txt

pack:
	cd $(OBJ) ;\
	ecppack $(PROJ)_pnr.txt $(PROJ)_pnr.bit

prog:
	cd $(OBJ) ;\
	openFPGALoader -c ft2232 $(PROJ)_pnr.bit
endif




