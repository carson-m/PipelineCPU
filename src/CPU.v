`timescale 1ns / 1ps
//To be compeleted
module CPU(
    input wire reset, 
	input wire clk, 
	input wire [31:0] MemBus_Read_Data,
	output wire MemRead, 
	output wire MemWrite,
	output wire [31:0] MemBus_Address, 
	output wire [31:0] MemBus_Write_Data
    );
    
    wire [1:0]IFIDop;
    wire [1:0]IDEXop;
    wire [1:0]EXMEMop;
    
    wire [1:0]IF_PCSrc;
    wire [31:0]IF_jPC;
    wire [31:0]IF_jrPC;
    wire [31:0]IF_branchPC;
    wire IF_comp_true;
    wire [31:0]ID_PCplus4;
    wire [31:0]ID_Instruction;
    
    IF IFstage(.reset(reset),.clk(clk),.IFIDop(IFIDop),.IDEXop(IDEXop),.EXMEMop(EXMEMop),
               .PCSrc(IF_PCSrc),.jPC(IF_jPC),.jrPC(IF_jrPC),.branchPC(IF_branchPC),
               .comp_true(IF_comp_true),.PC_plus_4(ID_PCplus4),.Instruction(ID_Instruction));
    
    wire [31:0]EXMEM_ALUout;
    wire [1:0]ID_compSourceA;
    wire [1:0]ID_compSourceB;
    wire [31:0]WB_RegWriteData;
    wire MEMWB_RegWrite;
    wire [4:0]MEMWB_RegWriteAddr;
    wire [31:0]IDEX_PCplus4;
    wire IDEX_RegWrite;
    wire IDEX_MemRead;
    wire [4:0]IDEX_WriteRegAddr;
    wire IDEX_MemWrite;
    wire IDEX_MemtoReg;
    wire IDEX_ALUSrcA;
    wire IDEX_ALUSrcB;
    wire [4:0]IDEX_ALUCtrl;
    wire IDEX_Sign;
    wire [31:0]IDEX_busA;
    wire [31:0]IDEX_busB;
    wire [31:0]IDEX_Imm;
    wire [4:0]IDEX_Shamt;
    wire [4:0]IDEX_rs;
    wire [4:0]IDEX_rt;
    wire IDEX_ALUorRA;
    wire [4:0]ID_rs;
    wire [4:0]ID_rt;
    
    ID IDstage(.reset(reset),.clk(clk),.IDEXop(IDEXop),.PCplus4(ID_PCplus4),
               .Instruction(ID_Instruction),.EX_MEM_ALUout(EXMEM_ALUout),
               .compSourceA(ID_compSourceA),.compSourceB(ID_compSourceB),
               .RegWriteData(WB_RegWriteData),.WriteAddr(MEMWB_RegWriteAddr),.RegWrite(MEMWB_RegWrite),.jPC(IF_jPC),
               .jrPC(IF_jrPC),.branchPC(IF_branchPC),.comp_true(IF_comp_true),
               .PCSrc(IF_PCSrc),.rs(ID_rs),.rt(ID_rt),.IDEX_PCplus4(IDEX_PCplus4),.IDEX_RegWrite(IDEX_RegWrite),
               .IDEX_MemRead(IDEX_MemRead),.IDEX_WriteRegAddr(IDEX_WriteRegAddr),
               .IDEX_MemWrite(IDEX_MemWrite),.IDEX_MemtoReg(IDEX_MemtoReg),
               .IDEX_ALUSrcA(IDEX_ALUSrcA),.IDEX_ALUSrcB(IDEX_ALUSrcB),.IDEX_ALUCtrl(IDEX_ALUCtrl),
               .IDEX_Sign(IDEX_Sign),.IDEX_busA(IDEX_busA),.IDEX_busB(IDEX_busB),
               .IDEX_Imm(IDEX_Imm),.IDEX_Shamt(IDEX_Shamt),.IDEX_rs(IDEX_rs),.IDEX_rt(IDEX_rt),
               .IDEX_ALUorRA(IDEX_ALUorRA));
    
    wire [1:0]EX_busAMUX;
    wire [1:0]EX_busBMUX;
    wire EXMEM_RegWrite;
    wire [4:0]EXMEM_WriteRegAddr;
    wire EXMEM_MemtoReg;
    wire EXMEM_MemWrite;
    assign MemWrite = EXMEM_MemWrite;
    wire EXMEM_MemRead;
    assign MemRead = EXMEM_MemRead;
    wire [31:0]EXMEM_MemWriteData;
    wire [4:0]EXMEM_rt;
    wire MEM_MemWriteDataSource;
    wire [31:0]MEM_MemReadData;
    wire [31:0]MEM_RealMemWriteData;
    //wire MEMWB_RegWrite;
    //wire [4:0]MEMWB_RegWriteAddr;
    wire MEMWB_MemtoReg;
    wire [31:0]MEMWB_MemReadData;
    wire [31:0]MEMWB_ALUout;
    assign MemBus_Address = EXMEM_ALUout;
    assign MemBus_Write_Data = MEM_RealMemWriteData;
    assign MEM_MemReadData = MemBus_Read_Data;
   
    EX EXstage(.reset(reset),.clk(clk),.EXMEMop(EXMEMop),.busAMUX(EX_busAMUX),.busBMUX(EX_busBMUX),
               .PCplus4(IDEX_PCplus4),.RegWrite(IDEX_RegWrite),.MemRead(IDEX_MemRead),.WriteRegAddr(IDEX_WriteRegAddr),
               .MemWrite(IDEX_MemWrite),.MemtoReg(IDEX_MemtoReg),.ALUorRA(IDEX_ALUorRA),
               .ALUSrcA(IDEX_ALUSrcA),.ALUSrcB(IDEX_ALUSrcB),.ALUCtrl(IDEX_ALUCtrl),.Sign(IDEX_Sign),
               .busA(IDEX_busA),.busB(IDEX_busB),.Imm(IDEX_Imm),.Shamt(IDEX_Shamt),.rt(IDEX_rt),.WB_RegWriteData(WB_RegWriteData),
               .EXMEM_ALUout(EXMEM_ALUout),.EXMEM_RegWrite(EXMEM_RegWrite),.EXMEM_WriteRegAddr(EXMEM_WriteRegAddr),.EXMEM_MemtoReg(EXMEM_MemtoReg),
               .EXMEM_MemWrite(EXMEM_MemWrite),.EXMEM_MemRead(EXMEM_MemRead),.EXMEM_MemWriteData(EXMEM_MemWriteData),.EXMEM_rt(EXMEM_rt));
    
    MEM MEMstage(.clk(clk),.reset(reset),.ALUout(EXMEM_ALUout),.RegWrite(EXMEM_RegWrite),.RegWriteAddr(EXMEM_WriteRegAddr),.MemtoReg(EXMEM_MemtoReg),
                 .MemWriteDataSource(MEM_MemWriteDataSource),.MemWriteData(EXMEM_MemWriteData),.MemWriteDataWB(WB_RegWriteData),.MemReadData(MEM_MemReadData),
                 .realMemWriteData(MEM_RealMemWriteData),.MEMWB_RegWrite(MEMWB_RegWrite),.MEMWB_RegWriteAddr(MEMWB_RegWriteAddr),.MEMWB_MemtoReg(MEMWB_MemtoReg),
                 .MEMWB_MemReadData(MEMWB_MemReadData),.MEMWB_ALUout(MEMWB_ALUout));
    
    WB WBstage(.ALUout(MEMWB_ALUout),.MEMout(MEMWB_MemReadData),.MemtoReg(MEMWB_MemtoReg),.WriteData(WB_RegWriteData));
    
    FwdAndStall FwdAndStallCtrl(.ID_rs(ID_rs),.ID_rt(ID_rt),.ID_PCSrc(IF_PCSrc),.ID_comp_true(IF_comp_true),.IDEX_RegWrite(IDEX_RegWrite),
                                .IDEX_RegWriteID(IDEX_WriteRegAddr),.EX_rs(IDEX_rs),.EX_rt(IDEX_rt),
                                .EX_ALUSrcA(IDEX_ALUSrcA),.EX_ALUSrcB(IDEX_ALUSrcB),.EXMEM_RegWrite(EXMEM_RegWrite),.EXMEM_RegWriteID(EXMEM_WriteRegAddr),
                                .EXMEM_MemtoReg(EXMEM_MemtoReg),.MEM_rt(EXMEM_rt),.WB_RegWriteID(MEMWB_RegWriteAddr),.WB_RegWrite(MEMWB_RegWrite),
                                .ID_CompSourceA(ID_compSourceA),.ID_CompSourceB(ID_compSourceB),.EX_busAMUX(EX_busAMUX),.EX_busBMUX(EX_busBMUX),.MEM_MemWriteDataSource(MEM_MemWriteDataSource),
                                .IFIDop(IFIDop),.IDEXop(IDEXop),.EXMEMop(EXMEMop));
endmodule
