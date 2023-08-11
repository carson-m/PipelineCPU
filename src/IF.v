`timescale 1ns / 1ps
module IF(
    input wire reset,
    input wire clk,
    input wire [1:0] IFIDop, //��IF/ID�Ĳ��� 0:����˳��ִ�� 1:���� 2:���ֲ���
    input wire [1:0] IDEXop, //�����ж�����ʱPC�Ƿ����
    input wire [1:0] EXMEMop, //��EX/MEM��ͬ��
    input wire [1:0] PCSrc, //PCԴ PC+4:0 PC:1 branch:2 j,jal:3 jr,jalr:4
    input wire [31:0] jPC, //j,jal���͵ĵ�ַ
    input wire [31:0] jrPC, //jr,jral���͵ĵ�ַ
    input wire [31:0] branchPC, //branch����ת��ַ
    input wire comp_true, //��֧������Ϊ1
    output reg [31:0] PC_plus_4, //IF/ID PC+4
    output reg [31:0] Instruction //IF/ID ָ��Ĵ���
    );
    reg  [31:0] PC; //PC
    wire [31:0] PC_plus_4_wire; //PC+4
    wire [31:0]PC_next; //��һ��ָ���PC��ַ
    assign PC_plus_4_wire = PC + 32'd4; //PC+4
    assign PC_next = (IFIDop == 2'd2 || IDEXop == 2'd2 || EXMEMop == 2'd2) ? PC : //ǰ��ָ��������ʱPC������
                     (PCSrc == 2'h0) ? PC_plus_4_wire :
                     (PCSrc == 2'h1) ? (comp_true ? branchPC : PC_plus_4_wire) :
                     (PCSrc == 2'h2) ? jPC :
                     (PCSrc == 2'h3) ? jrPC : PC_next;
    
    wire [31:0] Instruction_wire; //ָ���ȡ
    InstMem instMemory(PC, Instruction_wire); //ָ��洢��(input PC, output ָ��)
    
    always @(posedge reset or posedge clk)
    begin
        if(reset) begin
            PC <= 32'h00000000; //����PC
            PC_plus_4 <= 32'h00000000; //����PC+4�Ĵ���
            Instruction <= 32'h00000000; //����IF/IDָ��Ĵ���
        end
        else begin
            PC <= PC_next; //����PC
            case(IFIDop) //��IF/ID�Ĳ���
            2'd0: begin //˳��ִ��
                Instruction <= Instruction_wire;
                PC_plus_4 <= PC_plus_4_wire;
            end
            2'd1: begin //����
                Instruction <= 32'h00000000;
                PC_plus_4 <= 32'h00000000;
            end 
            2'd2: begin //���ֲ���
                Instruction <= Instruction;
                PC_plus_4 <= PC_plus_4;
            end
            default: begin //Ĭ�ϱ��ֲ���
                Instruction <= Instruction;
                PC_plus_4 <= PC_plus_4;
            end
            endcase
        end
    end
endmodule
