`timescale 1ns / 1ps
module MEM(
    input wire clk,
    input wire reset,
    input wire [31:0]ALUout,
    input wire RegWrite,
    input wire [4:0]RegWriteAddr,
    input wire MemtoReg,
    input wire MemWriteDataSource, //0:��ת�� 1:��WBת��
    //input wire MemWrite, //ֱ�ӷ���DataMem
    //input wire MemRead, //ֱ�ӷ���DataMem
    input wire [31:0]MemWriteData, //��EX/MEM�õ�
    input wire [31:0]MemWriteDataWB, //��WBת����
    input wire [31:0]MemReadData, //���ⲿDataMem�õ�
    //input wire [4:0]rt, //����rt��ת����Դ��regһ��������ת��
    output wire [31:0]realMemWriteData, //������͸�DataMem
    //����ΪMEM/WB�Ĵ���
    output reg MEMWB_RegWrite,
    output reg [4:0]MEMWB_RegWriteAddr,
    output reg MEMWB_MemtoReg,
    output reg [31:0]MEMWB_MemReadData,
    output reg [31:0]MEMWB_ALUout
    );
    
    //DataMem datamem(clk,reset,ALUout,MemWriteData,MemRead,MemWrite,MemReadData,)
    assign realMemWriteData = MemWriteDataSource ? MemWriteDataWB : MemWriteData;
    
    always @(posedge reset or posedge clk) begin
        if(reset) begin
            MEMWB_RegWrite <= 1'b0;
            MEMWB_RegWriteAddr <= 5'd0;
            MEMWB_MemtoReg <= 1'b0;
            MEMWB_MemReadData <= 32'h0;
            MEMWB_ALUout <= 32'h0;
        end
        else begin
            MEMWB_RegWrite <= RegWrite;
            MEMWB_RegWriteAddr <= RegWriteAddr;
            MEMWB_MemtoReg <= MemtoReg;
            MEMWB_MemReadData <= MemReadData;
            MEMWB_ALUout <= ALUout;
        end
    end
endmodule