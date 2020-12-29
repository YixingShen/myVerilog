@ECHO OFF
PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

::iverilog -E -opreprocessor_mytest.v mytest.v
iverilog -o wait_example.vvp wait_example.v
vvp wait_example.vvp -v -sdf-warn -sdf-info -sdf-verbose

gtkwave wave.vcd

PAUSE

