
BASEDIR=$(shell pwd)
# TARGET : fpga_xo2 | sky130 | sim

TARGET=fpga_xo2
#TARGET=sky130


# Project settings 
PROJ=amp_frontend
TOP=amp_frontend

## Walk all verilog files in a given directory
SOURCEDIR = hdl/amp_frontend
SRC := $(shell ls $(SOURCEDIR)/*.v) 

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
	echo "SRC: " $(SRC)
endif 


ifeq ($(TARGET),fpga_xo2)

##################################################################################
# FPGA target xo2 Lattices
# Tool path setup 

BINFPGA=/usr/local/diamond/3.12/bin/lin64
ISPFPGA=/usr/local/diamond/3.12/ispfpga/bin/lin64
PRGFPGA=/usr/local/programmer/diamond/3.12/bin/lin64

clean :
	rm $(OBJ)/hdl/$(TOP)/$(TARGET)/*
	
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
