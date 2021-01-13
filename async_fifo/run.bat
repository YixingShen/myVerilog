@ECHO OFF

PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

iverilog -v -g2001 -osim.vvp async_fifo_tb.v
vvp sim.vvp
gtkwave sim.vcd

PAUSE