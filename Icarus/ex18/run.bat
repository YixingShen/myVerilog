@ECHO OFF
PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

::iverilog -E -opreprocessor_mytest.v mytest.v
iverilog -o edge_wait_example.vvp edge_wait_example.v
vvp edge_wait_example.vvp -v -sdf-warn -sdf-info -sdf-verbose

gtkwave wave.vcd

PAUSE

