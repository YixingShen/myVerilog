@ECHO OFF
PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

iverilog -o my_shift_reg.vvp my_shift_reg.v testbench_top.v
vvp my_shift_reg.vvp
gtkwave test.vcd

PAUSE
