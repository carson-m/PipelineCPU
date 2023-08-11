`timescale 1ns / 1ps
module Controller(
    input wire [5:0]OpCode,
    input wire [5:0]funct,
    
    output wire [2:0]compOp, //比较器模式 0:beq 1:bne 2:blez 3:bgtz 4:bltz
    //output wire branch, //是否为分支指令 1是
    //output wire jump, //是否为跳转指令 1是
    output wire [1:0]PCSrc, //PC源 PC+4:0 branch:1 j,jal:2 jr,jalr:3
    output wire RegWr, //RF写使能
    output wire ExtOp, //有无符号扩展 1有0无
    output wire LuOp, //是否加载高16位立即数
    output wire [1:0]RegDst, //写入地址 0:rt 1:rd 2:$ra
    output wire ALUSrcA, //1:Shamt 0:busA
    output wire ALUSrcB, //1:Imm 0:busB
    output wire MemtoReg,
    output wire MemWrite,
    output wire MemRead,
    output wire ALUorRA //0:ALUrslt 1:PC+4   ->ALUout
    );
    
    //拆分指令
    //wire [5:0]OpCode;
    //wire [5:0]funct;
    //assign OpCode = Instruction[31:26];
    //assign funct = Instruction[5:0];
    
    //控制信号生成
    assign compOp = (OpCode == 6'h4 ? 3'd0 : //beq
                    (OpCode == 6'h5 ? 3'd1 : //bne
                    (OpCode == 6'h6 ? 3'd2 : //blez
                    (OpCode == 6'h7 ? 3'd3 : 3'd4)))); //bgtz,bltz
    //assign jump = OpCode == 6'h02 || OpCode == 6'h03 || (OpCode == 6'h00 && (funct == 6'h08 || funct == 6'h09)); //jump/jal/jr/jalr
    //assign branch = OpCode == 6'h04 || OpCode == 6'h05 || OpCode == 6'h06 || OpCode == 6'h07 || OpCode == 6'h01; //beq/bne/blez/bgtz/bltz
    
    assign PCSrc = (OpCode == 6'h4 || OpCode == 6'h5 || OpCode == 6'h6 || OpCode == 6'h7 || OpCode == 6'h1) ? 2'h1 :
                   (OpCode == 6'h2 || OpCode == 6'h3) ? 2'h2 :
                   (OpCode ==6'h0 && (funct == 6'h8 || funct == 6'h9)) ? 2'h3 : 2'h0; //PC源 PC+4:0 branch:1 j,jal:2 jr,jalr:3
    
    assign RegWr = (OpCode == 6'h2b || OpCode == 6'h04 || OpCode == 6'h05 || OpCode == 6'h06 || OpCode == 6'h07 || OpCode == 6'h01 ||
                            OpCode == 6'h02 || (OpCode == 6'h00 && funct == 6'h08)) ? 1'b0 : 1'b1;
    assign LuOp = OpCode == 6'h0f; //lui
    assign ExtOp = (OpCode == 6'h0c || OpCode == 6'h0d) ? 0 : 1; //仅andi与ori用无符号扩展
    
    assign RegDst = (OpCode == 6'h09 || OpCode == 6'h0f || OpCode == 6'h08 || OpCode == 6'h23 ||
                            OpCode == 6'h0a || OpCode == 6'h0d || OpCode == 6'h0c || OpCode == 6'h0b) ? 2'h0 :
                                OpCode == 6'h03 ? 2'h2 : 2'h1; // 0:rt 1:rd 2:$ra
    
    assign ALUSrcA = (OpCode == 6'h0 && (funct == 6'h00 || funct == 6'h02 || funct == 6'h03)) ? 1'b1 : 1'b0; //sll srl sra
    assign ALUSrcB = (OpCode == 6'h0f || OpCode == 6'h08 || OpCode == 6'h23 || OpCode == 6'h2b || OpCode == 6'h09 
                     || OpCode == 6'h0a || OpCode == 6'h0b || OpCode == 6'h0c || OpCode == 6'h0d) ? 1'b1 : 1'b0;
    
    assign MemtoReg = OpCode == 6'h23;
    
    assign MemWrite = OpCode == 6'h2b;
    
    assign MemRead = OpCode == 6'h23;
    
    assign ALUorRA = OpCode == 6'h03 || (OpCode == 6'h00 && funct == 6'h09); //jal jalr
endmodule
