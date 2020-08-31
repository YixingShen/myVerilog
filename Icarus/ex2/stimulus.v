`timescale 1ns / 100ps
module testbench;
    // Inputs
    reg x;
    reg y;
    // Outputs
    wire z;
    // UUT
    comparator uut (
        .x(x), 
        .y(y), 
        .z(z)
    );

    initial begin
	$dumpfile("test.vcd");
    $dumpvars(0,testbench);

    // Initialize
    x = 0;
    y = 0;
	#100;
    #20 x = 1;
    #20 y = 1;
    #20 y = 0;
    #20 x = 1;
    #40;
    end

    initial begin
    $monitor("x=%d,y=%d,z=%d \n",x,y,z);
	//$monitorb("x=",x, " y=",y," z= ",z);
    end

endmodule