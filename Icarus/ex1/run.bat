PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
iverilog -o comparator.vvp comparator.v stimulus.v
vvp comparator.vvp
gtkwave test.vcd
PAUSE
