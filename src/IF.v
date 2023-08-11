`timescale 1ns / 1ps
module IF(
    input wire reset,
    input wire clk,
    input wire [1:0] IFIDop, //对IF/ID的操作 0:正常顺序执行 1:清零 2:保持不变
    input wire [1:0] IDEXop, //用于判断阻塞时PC是否更新
    input wire [1:0] EXMEMop, //对EX/MEM，同上
    input wire [1:0] PCSrc, //PC源 PC+4:0 PC:1 branch:2 j,jal:3 jr,jalr:4
    input wire [31:0] jPC, //j,jal类型的地址
    input wire [31:0] jrPC, //jr,jral类型的地址
    input wire [31:0] branchPC, //branch的跳转地址
    input wire comp_true, //分支成立则为1
    output reg [31:0] PC_plus_4, //IF/ID PC+4
    output reg [31:0] Instruction //IF/ID 指令寄存器
    );
    reg  [31:0] PC; //PC
    wire [31:0] PC_plus_4_wire; //PC+4
    wire [31:0]PC_next; //下一条指令的PC地址
    assign PC_plus_4_wire = PC + 32'd4; //PC+4
    assign PC_next = (IFIDop == 2'd2 || IDEXop == 2'd2 || EXMEMop == 2'd2) ? PC : //前序指令有阻塞时PC不更新
                     (PCSrc == 2'h0) ? PC_plus_4_wire :
                     (PCSrc == 2'h1) ? (comp_true ? branchPC : PC_plus_4_wire) :
                     (PCSrc == 2'h2) ? jPC :
                     (PCSrc == 2'h3) ? jrPC : PC_next;
    
    wire [31:0] Instruction_wire; //指令读取
    InstMem instMemory(PC, Instruction_wire); //指令存储器(input PC, output 指令)
    
    always @(posedge reset or posedge clk)
    begin
        if(reset) begin
            PC <= 32'h00000000; //清零PC
            PC_plus_4 <= 32'h00000000; //清零PC+4寄存器
            Instruction <= 32'h00000000; //清零IF/ID指令寄存器
        end
        else begin
            PC <= PC_next; //更新PC
            case(IFIDop) //对IF/ID的操作
            2'd0: begin //顺序执行
                Instruction <= Instruction_wire;
                PC_plus_4 <= PC_plus_4_wire;
            end
            2'd1: begin //清零
                Instruction <= 32'h00000000;
                PC_plus_4 <= 32'h00000000;
            end 
            2'd2: begin //保持不变
                Instruction <= Instruction;
                PC_plus_4 <= PC_plus_4;
            end
            default: begin //默认保持不变
                Instruction <= Instruction;
                PC_plus_4 <= PC_plus_4;
            end
            endcase
        end
    end
endmodule
