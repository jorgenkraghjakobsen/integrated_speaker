


default :
	./makeSineTable > rom_sine_table.hex

rom_v : rom_sine_table.hex
	/usr/local/diamond/3.12/ispfpga/bin/lin64/scuba -w -n rom_sine \
	  -lang verilog -synth lse -bus_exp 7 -bb -arch xo2c00 -type romblk \
	  -device LCMXO2-1200HC -addr_width 7 -data_width 16 -num_words 128 \
	  -outdata REGISTERED -cascade -1 -resetmode SYNC -sync_reset \
	  -memfile rom_sine_table.hex -memformat hex
	  
