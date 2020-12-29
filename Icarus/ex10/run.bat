@ECHO OFF
PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

iverilog -o my_ring_counter.vvp my_ring_counter.v testbench_top.v
vvp my_ring_counter.vvp
gtkwave test.vcd

PAUSE
