`timescale 1ns / 1ps
module DataMem(
	input wire clk,
	input wire reset,
	input wire [31:0]Address,
	input wire [31:0]Write_data,
	input wire MemRead,
	input wire MemWrite,
	output wire [31:0] Read_data,
	output reg [7:0] BCDData,
	output reg [3:0] an
	);

	parameter RAM_SIZE = 512; //内存大小
	parameter RAM_SIZE_BIT = 9;
	
	reg [31:0] RAM_data[RAM_SIZE - 1: 0]; //建立内存
	
	assign Read_data = MemRead ? RAM_data[Address[RAM_SIZE_BIT + 1:2]]: 32'h00000000;
	
	integer i;
        always @(posedge reset or posedge clk)
            if (reset) begin
                BCDData <= 8'h0;
                an <= 4'h0;
                for(i = 0; i < RAM_SIZE; i = i + 1) begin
                    case(i)
                    default: RAM_data[i] <= 32'h00000000;
                    endcase
                end
            end
            else if (MemWrite) begin
                if(Address == 32'h40000010) begin
                    BCDData <= Write_data[7:0]; //0xXXXXX[an][BCDData]
                    an <= Write_data[11:8];
                end
                else begin
                    RAM_data[Address[RAM_SIZE_BIT + 1:2]] <= Write_data;
                end
            end
            else begin
                BCDData <= BCDData;
                an <= an;
            end
endmodule
