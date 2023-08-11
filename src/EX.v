`timescale 1ns / 1ps

module EX(
    input wire reset,
    input wire clk,
    input wire [1:0]EXMEMop, //0:正常顺序执行 1:清零 2:保持
    input wire [1:0]busAMUX, //用于转发选择 0:busA 1:EXMEM 2:WB 下同
    input wire [1:0]busBMUX,
    input wire [31:0]PCplus4,
    input wire RegWrite,
    input wire MemRead,
    input wire [4:0]WriteRegAddr,
    input wire MemWrite,
    input wire MemtoReg,
    input wire ALUorRA,
    input wire ALUSrcA,
    input wire ALUSrcB,
    input wire [4:0]ALUCtrl,
    input wire Sign,
    input wire [31:0]busA,
    input wire [31:0]busB,
    input wire [31:0]Imm,
    input wire [4:0]Shamt,
    //input wire [4:0]rs,
    input wire [4:0]rt,
    input wire [31:0]WB_RegWriteData, //WB写回的数据转发
    //以下为EX/MEM寄存器
    output reg [31:0]EXMEM_ALUout,
    output reg EXMEM_RegWrite,
    output reg [4:0]EXMEM_WriteRegAddr,
    output reg EXMEM_MemtoReg,
    output reg EXMEM_MemWrite,
    output reg EXMEM_MemRead,
    output reg [31:0]EXMEM_MemWriteData, //在MEM阶段即将写入内存的数据
    output reg [4:0]EXMEM_rt //记录存储MemWriteData的寄存器ID，用于给MemWriteData转发
    );
    
    wire [31:0]alu_in1;
    wire [31:0]alu_in2;
    wire [31:0]alu_rslt;
    wire [31:0]alu_out;
    ALU alu(ALUCtrl,Sign,alu_in1,alu_in2,alu_rslt);
    wire [31:0]realbusA;
    wire [31:0]realbusB;
    assign realbusA = (busAMUX == 2'd1) ? EXMEM_ALUout : (busAMUX == 2'd2) ? WB_RegWriteData : busA;
    assign realbusB = (busBMUX == 2'd1) ? EXMEM_ALUout : (busBMUX == 2'd2) ? WB_RegWriteData : busB;
    assign alu_in1 = (ALUSrcA == 1'b0) ? realbusA : {27'd0,Shamt};
    assign alu_in2 = (ALUSrcB == 1'b0) ? realbusB : Imm;
    assign alu_out = ALUorRA ? PCplus4 : alu_rslt;
    
    always @(posedge reset or posedge clk) begin
        if(reset) begin
            EXMEM_ALUout <= 32'd0;
            EXMEM_RegWrite <= 1'b0;
            EXMEM_WriteRegAddr <= 32'd0;
            EXMEM_MemtoReg <= 1'b0;
            EXMEM_MemWrite <= 1'b0;
            EXMEM_MemRead <= 1'b0;
            EXMEM_MemWriteData <= 32'd0;
            EXMEM_rt <= 5'h0;
        end
        else begin
        case(EXMEMop)
        2'd0: begin
            EXMEM_ALUout <= alu_out;
            EXMEM_RegWrite <= RegWrite;
            EXMEM_WriteRegAddr <= WriteRegAddr;
            EXMEM_MemtoReg <= MemtoReg;
            EXMEM_MemWrite <= MemWrite;
            EXMEM_MemRead <= MemRead;
            EXMEM_MemWriteData <= realbusB; //此处使用转发后的busB
            EXMEM_rt <= rt;
        end
        2'd1:begin
            EXMEM_ALUout <= 32'd0;
            EXMEM_RegWrite <= 1'b0;
            EXMEM_WriteRegAddr <= 32'd0;
            EXMEM_MemtoReg <= 1'b0;
            EXMEM_MemWrite <= 1'b0;
            EXMEM_MemRead <= 1'b0;
            EXMEM_MemWriteData <= 32'd0;
            EXMEM_rt <= 5'h0;
        end
        2'd2:begin
            EXMEM_ALUout <= EXMEM_ALUout;
            EXMEM_RegWrite <= EXMEM_RegWrite;
            EXMEM_WriteRegAddr <= EXMEM_WriteRegAddr;
            EXMEM_MemtoReg <= EXMEM_MemtoReg;
            EXMEM_MemWrite <= EXMEM_MemWrite;
            EXMEM_MemRead <= EXMEM_MemRead;
            EXMEM_MemWriteData <= EXMEM_MemWriteData;
            EXMEM_rt <= EXMEM_rt;
        end
        default:begin
            EXMEM_ALUout <= EXMEM_ALUout;
            EXMEM_RegWrite <= EXMEM_RegWrite;
            EXMEM_WriteRegAddr <= EXMEM_WriteRegAddr;
            EXMEM_MemtoReg <= EXMEM_MemtoReg;
            EXMEM_MemWrite <= EXMEM_MemWrite;
            EXMEM_MemRead <= EXMEM_MemRead;
            EXMEM_MemWriteData <= EXMEM_MemWriteData;
            EXMEM_rt <= EXMEM_rt;
        end
        endcase
        end
    end
endmodule