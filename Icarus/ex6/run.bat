@ECHO OFF
PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

iverilog -o myfulladder.vvp myfulladder.v testbench_top.v
vvp myfulladder.vvp
gtkwave test.vcd

PAUSE
