@ECHO OFF
PATH=PATH;D:\iverilog\bin;D:\iverilog\gtkwave\bin
DEL *.vvp
DEL *.vcd

::iverilog -E -opreprocessor_mytest.v mytest.v
iverilog -o tri_buf_using_assign.vvp tri_buf_using_assign.v
vvp tri_buf_using_assign.vvp -v -sdf-warn -sdf-info -sdf-verbose

gtkwave wave.vcd

PAUSE

