`timescale 1ns / 1ps

module testbench();
	
	reg reset;
	reg sysclk;
	wire [7:0] bcd7;
	wire [3:0] an;
	
	top toptest(sysclk,reset,bcd7,an);
	
	initial begin
		reset = 0;
		sysclk = 1;
		#10 reset = 1;
		#100 reset = 0;
	end
	
	always #5 sysclk = ~sysclk;
		
endmodule
