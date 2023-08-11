`timescale 1ns / 1ps
module RegFile(
	input  reset,
	input  clk,
	input  RegWrite,
	input  [4:0]  Read_register1, 
	input  [4:0]  Read_register2, 
	input  [4:0]  Write_register,
	input  [31:0] Write_data,
	output [31:0] Read_data1, 
	output [31:0] Read_data2
);

	reg [31:0] RF_data[31:1];//¼Ä´æÆ÷¶Ñ£¬31*32£¬0ºÅ¼Ä´æÆ÷ÓÀÔ¶Îª0
	
	// ¶ÁÈ¡Êı¾İ
	assign Read_data1 = (Read_register1 == 5'b00000)? 32'h00000000: RF_data[Read_register1];
	assign Read_data2 = (Read_register2 == 5'b00000)? 32'h00000000: RF_data[Read_register2];
	
	integer i;
	// Ğ´ÈëÊı¾İ
	always @(posedge reset or posedge clk)
		if (reset)
			for (i = 1; i < 32; i = i + 1)
				RF_data[i] <= 32'h00000000;
		else if (RegWrite && (Write_register != 5'b00000))
			RF_data[Write_register] <= Write_data;

endmodule
