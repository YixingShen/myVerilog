@ECHO OFF

PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

iverilog -v -g2001 -osim.vvp uart_tb.v timer.v uart_tx.v uart_rx.v

vvp sim.vvp

gtkwave sim.vcd

PAUSE