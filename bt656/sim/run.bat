@ECHO OFF

PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

iverilog -v -g2001 -osim.vvp bt656_tb.v ..\rtl\bt656_tx.v

vvp -v sim.vvp -fst

REM gtkwave sim.vcd
gtkwave sim.fst

PAUSE