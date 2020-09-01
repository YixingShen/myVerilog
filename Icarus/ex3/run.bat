@ECHO OFF
PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

iverilog -o fulladder.vvp fulladder.v testbench_top.v
vvp fulladder.vvp
gtkwave test.vcd

PAUSE
