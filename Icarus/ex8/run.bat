@ECHO OFF
PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

iverilog -o mydff.vvp mydff.v testbench_top.v
vvp mydff.vvp
gtkwave test.vcd

PAUSE
