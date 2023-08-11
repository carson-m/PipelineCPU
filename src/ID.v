`timescale 1ns / 1ps
//To be completed
module ID(
    input wire reset,
    input wire clk, //ʱ��
    input wire [1:0]IDEXop, //0:����˳��ִ�� 1:���� 2:���ֲ���
    input wire [31:0]PCplus4, //PC+4
    input wire [31:0]Instruction, //ָ��
    input wire [31:0]EX_MEM_ALUout, //EX-MEM��ת��
    input wire [1:0]compSourceA, //Comp�Ƚ���ǰ��busA MUX�����ź� 0:���� 1:ת��EX/MEM 2:ת��MEM/WB
    input wire [1:0]compSourceB,
    input wire [31:0]RegWriteData, //Ҫд��RF�����ݣ���WB�ӻ�����ͬʱ������ת��ģ����д���
    input wire [4:0]WriteAddr, //д�Ĵ����ѵ�ַ
    input wire RegWrite,
    
    output wire [31:0]jPC, //j,jal PC
    output wire [31:0]jrPC, //jr,jalr PC
    output wire [31:0]branchPC, //��ָ֧�����ת��ַ
    output wire comp_true, //���ڷ�֧�жϣ�Ϊtrueʱ��֧��������
    output wire [1:0]PCSrc,//PCԴ PC+4:0 branch:1 j,jal:2 jr,jalr:3
    output wire [4:0]rs,
    output wire [4:0]rt,
    //����ΪID/EX�Ĵ�������
    output reg [31:0]IDEX_PCplus4,
    output reg IDEX_RegWrite,
    output reg IDEX_MemRead,
    output reg [4:0]IDEX_WriteRegAddr,
    output reg IDEX_MemWrite,
    output reg IDEX_MemtoReg, //0:ALUout 1:MEMout
    output reg IDEX_ALUSrcA,
    output reg IDEX_ALUSrcB,
    output reg [4:0]IDEX_ALUCtrl,
    output reg IDEX_Sign,
    output reg [31:0]IDEX_busA,
    output reg [31:0]IDEX_busB,
    output reg [31:0]IDEX_Imm,
    output reg [4:0]IDEX_Shamt,
    output reg [4:0]IDEX_rs,
    output reg [4:0]IDEX_rt,
    output reg IDEX_ALUorRA
    );
    
    //wire [4:0]rs;
    //wire [4:0]rt;
    wire [4:0]rd;
    assign rs = Instruction[25:21];
    assign rt = Instruction[20:16];
    assign rd = Instruction[15:11];
    
    wire [4:0]Shamt;
    assign Shamt = Instruction[10:6];
    
    wire IDEX_RegWrite_wire; //�Ĵ�����д��ʹ��
    wire [1:0]RegDst; //�Ĵ�����д���ַѡ�� 0:rt 1:rd 2:$ra
    wire ExtOp; //��չģʽ ExpOpΪ1ʱ���������з�����չ������ֱ�Ӳ�0
    wire LuOp; //Ϊ1����ظ�16λ�����򲻱�
    wire [2:0]compOp; //�Ƚ�ģʽ
    wire MemRead; //MEM��ʹ��
    wire MemWrite; //MEMдʹ��
    wire MemtoReg;
    wire ALUorRA; //0:ALUrslt(ALU������) 1:PC+4(����jal,jalr) ��ΪALUout
    wire ALUSrcA;
    wire ALUSrcB;
    wire [4:0]ALUCtrl; //ALU����
    wire Sign;
    
    wire [31:0]busA; //busA of ID stage
    wire [31:0]busB;
    RegFile RF(reset,clk,RegWrite,rs,rt,WriteAddr,RegWriteData,busA,busB); //RegisterFile
    
    //����������
    wire [31:0] Imm_out; //�������?
    wire [31:0] Ext_temp; //��ʱ��չ���?
    assign Ext_temp = { ExtOp? {16{Instruction[15]}}: 16'h0000, Instruction[15:0]}; //ExpOPΪ1ʱ���������з�����չ������ֱ�Ӳ�0 //Instruction[15]�ظ�16��
    // LUI  ���ظ�16λ? Ext�����Ϊ���룬ȡ���16λ��Ϊ��16λ
    assign Imm_out = LuOp? {Instruction[15:0], 16'h0000}: Ext_temp;
    
    assign branchPC = PCplus4 + {Imm_out[29:0],2'b00}; //branch����ת��ַ
    
    assign jPC = {PCplus4[31:28],Instruction[25:0],2'b00}; //j,jal����ת��ַ
    wire [31:0]real_busA; //��ת�������յ�busA
    wire [31:0]real_busB;
    assign real_busA = (compSourceA == 2'd0 ? busA : (compSourceA == 2'd1 ? EX_MEM_ALUout : RegWriteData)); //����ת��
    assign real_busB = (compSourceB == 2'd0 ? busB : (compSourceB == 2'd1 ? EX_MEM_ALUout : RegWriteData));
    assign jrPC = real_busA; //jr,jalr����תPC
    Comparer comp(real_busA,real_busB,compOp,comp_true); //�Ƚ���comp
    Controller ctrl(Instruction[31:26],Instruction[5:0],compOp,PCSrc,IDEX_RegWrite_wire,ExtOp,LuOp,RegDst,ALUSrcA,ALUSrcB,MemtoReg,MemWrite,MemRead,ALUorRA);
    ALUControl ALUctrl(Instruction[31:26],Instruction[5:0],ALUCtrl,Sign);
    
    
    always @(posedge reset or posedge clk) begin
        if(reset) begin
            IDEX_PCplus4 <= 32'h0;
            IDEX_RegWrite <= 1'b0;
            IDEX_WriteRegAddr <= 5'b0;
            IDEX_MemRead <= 1'b0;
            IDEX_MemWrite <= 1'b0;
            IDEX_MemtoReg <= 1'b0;
            IDEX_ALUSrcA <= 1'b0;
            IDEX_ALUSrcB <= 1'b0;
            IDEX_ALUCtrl <= 5'd0;
            IDEX_Sign <= 1'b0;
            IDEX_busA <= 32'h0;
            IDEX_busB <= 32'h0;
            IDEX_Imm <= 32'h0;
            IDEX_Shamt <= 5'd0;
            IDEX_rs <= 1'b0;
            IDEX_rt <= 1'b0;
            IDEX_ALUorRA <= 1'b0;
        end
        else begin
            case(IDEXop)
            2'h0: begin
                IDEX_PCplus4 <= PCplus4;
                IDEX_RegWrite <= IDEX_RegWrite_wire;
                IDEX_WriteRegAddr <= (RegDst == 2'b0 ? rt : (RegDst == 2'b01 ? rd : 5'b11111)); //rt/rd/$ra
                IDEX_MemRead <= MemRead;
                IDEX_MemWrite <= MemWrite;
                IDEX_MemtoReg <= MemtoReg;
                IDEX_ALUSrcA <= ALUSrcA;
                IDEX_ALUSrcB <= ALUSrcB;
                IDEX_ALUCtrl <= ALUCtrl;
                IDEX_Sign <= Sign;
                IDEX_busA <= real_busA;
                IDEX_busB <= real_busB;
                IDEX_Imm <= Imm_out;
                IDEX_Shamt <= Shamt;
                IDEX_rs <= rs;
                IDEX_rt <= rt;
                IDEX_ALUorRA <= ALUorRA;
            end
            2'h1: begin
                IDEX_PCplus4 <= 32'h0;
                IDEX_RegWrite <= 1'b0;
                IDEX_WriteRegAddr <= 5'b0;
                IDEX_MemRead <= 1'b0;
                IDEX_MemWrite <= 1'b0;
                IDEX_MemtoReg <= 1'b0;
                IDEX_ALUSrcA <= 1'b0;
                IDEX_ALUSrcB <= 1'b0;
                IDEX_ALUCtrl <= 5'd0;
                IDEX_Sign <= 1'b0;
                IDEX_busA <= 32'h0;
                IDEX_busB <= 32'h0;
                IDEX_Imm <= 32'h0;
                IDEX_Shamt <= 5'd0;
                IDEX_rs <= 1'b0;
                IDEX_rt <= 1'b0;
                IDEX_ALUorRA <= 1'b0;
            end
            2'h2: begin
                IDEX_PCplus4 <= IDEX_PCplus4;
                IDEX_RegWrite <= IDEX_RegWrite;
                IDEX_WriteRegAddr <= IDEX_WriteRegAddr;
                IDEX_MemRead <= IDEX_MemRead;
                IDEX_MemWrite <= IDEX_MemWrite;
                IDEX_MemtoReg <= IDEX_MemtoReg;
                IDEX_ALUSrcA <= IDEX_ALUSrcA;
                IDEX_ALUSrcB <= IDEX_ALUSrcB;
                IDEX_ALUCtrl <= IDEX_ALUCtrl;
                IDEX_Sign <= IDEX_Sign;
                IDEX_busA <= IDEX_busA;
                IDEX_busB <= IDEX_busB;
                IDEX_Imm <= IDEX_Imm;
                IDEX_Shamt <= IDEX_Shamt;
                IDEX_rs <= IDEX_rs;
                IDEX_rt <= IDEX_rt;
                IDEX_ALUorRA <= IDEX_ALUorRA;
            end
            default: begin
                IDEX_PCplus4 <= IDEX_PCplus4;
                IDEX_RegWrite <= IDEX_RegWrite;
                IDEX_WriteRegAddr <= IDEX_WriteRegAddr;
                IDEX_MemRead <= IDEX_MemRead;
                IDEX_MemWrite <= IDEX_MemWrite;
                IDEX_MemtoReg <= IDEX_MemtoReg;
                IDEX_ALUSrcA <= IDEX_ALUSrcA;
                IDEX_ALUSrcB <= IDEX_ALUSrcB;
                IDEX_ALUCtrl <= IDEX_ALUCtrl;
                IDEX_Sign <= IDEX_Sign;
                IDEX_busA <= IDEX_busA;
                IDEX_busB <= IDEX_busB;
                IDEX_Imm <= IDEX_Imm;
                IDEX_Shamt <= IDEX_Shamt;
                IDEX_rs <= IDEX_rs;
                IDEX_rt <= IDEX_rt;
                IDEX_ALUorRA <= IDEX_ALUorRA;
            end
            endcase
        end
    end
    
endmodule