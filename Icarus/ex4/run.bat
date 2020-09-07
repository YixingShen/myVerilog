@ECHO OFF
PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

iverilog -o priority_encoders.vvp priority_encoders.v testbench_top.v
vvp priority_encoders.vvp
gtkwave test.vcd

PAUSE
