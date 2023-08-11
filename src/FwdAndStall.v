`timescale 1ns / 1ps

module FwdAndStall(
    input wire [4:0]ID_rs,
    input wire [4:0]ID_rt,
    input wire [1:0]ID_PCSrc,
    input wire ID_comp_true,
    input wire IDEX_RegWrite,
    input wire [4:0]IDEX_RegWriteID,
    //input wire IDEX_MemtoReg,
    input wire [4:0]EX_rs,
    input wire [4:0]EX_rt,
    input wire EX_ALUSrcA,
    input wire EX_ALUSrcB,
    input wire EXMEM_RegWrite,
    input wire [4:0]EXMEM_RegWriteID,
    input wire EXMEM_MemtoReg,
    input wire [4:0]MEM_rt,
    input wire [4:0]WB_RegWriteID,
    input wire WB_RegWrite,
    
    output wire [1:0]ID_CompSourceA,
    output wire [1:0]ID_CompSourceB,
    output wire [1:0]EX_busAMUX,
    output wire [1:0]EX_busBMUX,
    output wire MEM_MemWriteDataSource, //0:不转发 1:从WB转发
    
    output wire [1:0]IFIDop,
    output wire [1:0]IDEXop,
    output wire [1:0]EXMEMop
    );
    
    wire holdIDEX;
    wire holdIFID;
    wire flushIFID;
    
    assign ID_CompSourceA = (EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg == 1'b0 && EXMEM_RegWriteID == ID_rs && EXMEM_RegWriteID != 5'h0) ? 2'd1 :
                            (WB_RegWrite == 1'b1 && WB_RegWriteID == ID_rs && WB_RegWriteID != 5'h0) ? 2'd2 : 2'd0;
    assign ID_CompSourceB = (EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg == 1'b0 && EXMEM_RegWriteID == ID_rt && EXMEM_RegWriteID != 5'h0) ? 2'd1 :
                            (WB_RegWrite == 1'b1 && WB_RegWriteID == ID_rt && WB_RegWriteID != 5'h0) ? 2'd2 : 2'd0;
    assign EX_busAMUX = (EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg == 1'b0 && EXMEM_RegWriteID != 5'h0 && EXMEM_RegWriteID == EX_rs) ? 2'd1 :
                        (WB_RegWrite == 1'b1 && WB_RegWriteID != 5'h0 && WB_RegWriteID == EX_rs) ? 2'd2 : 2'd0;
    assign EX_busBMUX = (EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg == 1'b0 && EXMEM_RegWriteID != 5'h0 && EXMEM_RegWriteID == EX_rt) ? 2'd1 :
                        (WB_RegWrite == 1'b1 && WB_RegWriteID != 5'h0 && WB_RegWriteID == EX_rt) ? 2'd2 : 2'd0;
    assign MEM_MemWriteDataSource = (WB_RegWrite == 1'b1 && WB_RegWriteID != 5'h0 && WB_RegWriteID == MEM_rt);
    
    assign holdIFID = ((IDEX_RegWriteID != 5'h0 && ID_PCSrc == 2'd1) && ((IDEX_RegWrite == 1'b1 && (IDEX_RegWriteID == ID_rs || IDEX_RegWrite == ID_rt)))) || //ALU->branch or Load->branch(stage1)
                        (EXMEM_RegWriteID != 5'h0 && ID_PCSrc == 2'd1 && EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg == 1'b1 && (EXMEM_RegWriteID == ID_rs || EXMEM_RegWriteID == ID_rt)) ? 1'b1 :1'b0; //Load->branch(stage2)
    assign holdIDEX = EXMEM_RegWriteID != 5'h0 && (EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg == 1'b1 && ((EXMEM_RegWriteID == EX_rs && EX_ALUSrcA == 1'b0) || (EXMEM_RegWriteID == EX_rt && EX_ALUSrcB == 1'b0))) ? 1'b1 : 1'b0;
    
    assign flushIFID = (ID_PCSrc == 2'd2 || ID_PCSrc == 2'd3) || (ID_PCSrc == 2'd1 && ID_comp_true);
    
    assign IFIDop = (holdIFID || holdIDEX) ? 2'd2 : flushIFID ? 2'd1 :2'd0;
    assign IDEXop = holdIDEX ? 2'd2 : holdIFID ? 2'd1 : 2'd0; //IFID保持，IDEX不保持时，要清零IDEX，防止出现两个EX
    assign EXMEMop = holdIDEX ? 2'h1 : 2'h0;
endmodule
