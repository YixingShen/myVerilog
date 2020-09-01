@ECHO OFF
PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

iverilog -o comparator.vvp comparator.v testbench_top.v
vvp comparator.vvp
gtkwave test.vcd

PAUSE
