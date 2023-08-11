`timescale 1ns / 1ps

module top(
    input wire sysclk,
    input wire reset,
    output wire [7:0]BCDData,
    output wire [3:0]an
    );
    
    wire clk;
    wire [31:0]MemBus_Read_Data;
    wire MemRead;
    wire MemWrite;
    wire [31:0]MemBus_Address;
    wire [31:0]MemBus_Write_Data;
    
    assign clk = sysclk;
    //CLK clock(sysclk,reset,clk);
    CPU myCPU(.clk(clk),.reset(reset),.MemBus_Read_Data(MemBus_Read_Data),.MemRead(MemRead),.MemWrite(MemWrite),.MemBus_Address(MemBus_Address),.MemBus_Write_Data(MemBus_Write_Data));
    DataMem DatMem(.clk(clk),.reset(reset),.Address(MemBus_Address),.Write_data(MemBus_Write_Data),.MemRead(MemRead),.MemWrite(MemWrite),.Read_data(MemBus_Read_Data),
                       .BCDData(BCDData),.an(an));
endmodule
