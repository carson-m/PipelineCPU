`timescale 1ns / 1ps
module WB(
    input wire [31:0]ALUout,
    input wire [31:0]MEMout,
    //input wire MEMWB_RegWrite, //ID��ֱ�Ӵ�MEM/WB��ȡ�����ù�WB
    //input wire [4:0]MEMWB_WriteRegAddr, //ID��ֱ�Ӵ�MEM/WB��ȡ�����ù�WB
    input wire MemtoReg,
    
    //output wire [4:0]WriteRegAddr,
    output wire [31:0]WriteData
    );
    //assign WriteRegAddr = MEMWB_WriteRegAddr;
    assign WriteData = (MemtoReg == 1'b1) ? MEMout : ALUout;
endmodule
