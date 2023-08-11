# 32位MIPS五级流水线处理器实验报告

马嘉成 2021011966 无18

## 实验目的

设计并用FPGA实现一个支持32位MIPS指令子集，能够实现冒险的检测和处理的处理器，并用它运行Dijkstra算法计算单源最短路径之和，并用程序控制外设实现结果在七段数码管上的显示。

## 设计方案

### 整体框架

哈佛架构。采用5级流水线，分为`IF`/`ID`/`EX`/`MEM`/`WB`五个阶段。级间有`IF/ID`、`ID/EX`、`EX/MEM`、`MEM/WB`四组寄存器，`IF/ID`与`ID/EX`支持顺序执行、清零与保持三种工作模式，`EX/MEM`支持顺序执行与清零两种工作模式，`MEM/WB`仅支持顺序执行。在`ID`阶段提前判断分支指令，在`ID`阶段跳转。使用`Controller`模块在`ID`阶段生成控制信号，使用单独的冒险检测与处理模块`FwdAndStall`实现对数据冒险和控制冒险的检测。寄存器堆`RegFile`本身不支持先写后读，通过转发实现相同效果。

### 指令集支持情况

在支持春季学期单周期处理器的支持指令集基础上，增添了算术逻辑指令`ori`、分支指令`beq`、`bne`、`blez`、`bgtz`和`bltz`、跳转指令`j`、`jal`、`jr`、`jalr`。

### 设计框图

//img

由于控制信号和中间变量过多，部分细节未在此图上画出。

## 原理说明及关键代码实现

### 五级流水线

一条指令分为取指令`IF`、指令译码`ID`、执行`EX`、内存读写`MEM`和写回`WB`五个执行步骤。步骤之间设有寄存器存储下一步骤指令所需的控制信号和数据。级间寄存器有三种工作模式，分别为顺序执行、清零和保持。顺序执行就是在每个时钟的上升沿时读取前级的数据保存起来。清零就是在上升沿时将其存储的数据全部置零。保持就是在上升沿处读取自己的现有数据并保存，等效为不变。在本处理器中，具体有`IF/ID`、`ID/EX`、`EX/MEM`、`MEM/WB`四组寄存器，`IF/ID`与`ID/EX`支持顺序执行、清零与保持三种工作模式，`EX/MEM`支持顺序执行与清零两种工作模式，`MEM/WB`仅支持顺序执行。在`ID`阶段提前判断分支指令，在`ID`阶段跳转。

使用流水线，可以将关键路径缩短，有利于提高主频，减小慢指令对处理器性能的拖累。之所以级间寄存器要支持以上三种工作模式，主要是由于数据的产生与使用之间存在时间上的冲突，有时需要后续指令等待前序指令的执行结果。

三种工作状态的实现以`IF/ID`为例：

```verilog
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
```

### 控制信号的生成

控制信号由`Controller`在`ID`阶段生成，生成逻辑如下。

由于分支指令判断为真的条件各不相同，所以需要告诉比较器以什么依据来比较。分支指令所用比较器的比较方式选择

```verilog
 assign compOp = (OpCode == 6'h4 ? 3'd0 : //beq
                 (OpCode == 6'h5 ? 3'd1 : //bne
                 (OpCode == 6'h6 ? 3'd2 : //blez
                 (OpCode == 6'h7 ? 3'd3 : 3'd4)))); //bgtz,bltz
```

PC寄存器更新的来源。对于顺序执行的指令，PC来源于`PC+4`。对于分支指令，PC来源于`PC+4`或者`(PC+4)+Signed_Ext(Immediate << 2)`。对于`j`和`jal`，采用了伪直接寻址，PC来源于`{PCplus4[31:28],Instruction[25:0],2'b00}`。对于`jr`和`jalr`，采用了寄存器寻址，PC来源于`rt`。需要针对不同的指令选择PC更新的来源。

```verilog
assign PCSrc = (OpCode == 6'h4 || OpCode == 6'h5 || OpCode == 6'h6 || OpCode == 6'h7 || OpCode == 6'h1) ? 2'h1 :
               (OpCode == 6'h2 || OpCode == 6'h3) ? 2'h2 :
               (OpCode ==6'h0 && (funct == 6'h8 || funct == 6'h9)) ? 2'h3 : 2'h0; //PC源 PC+4:0 branch:1 j,jal:2 jr,jalr:3
```

寄存器堆的写入使能，防止无关的数据被写入产生错误结果。

```verilog
assign RegWr = (OpCode == 6'h2b || OpCode == 6'h04 || OpCode == 6'h05 || OpCode == 6'h06 || OpCode == 6'h07 || OpCode == 6'h01 || OpCode == 6'h02 || (OpCode == 6'h00 && funct == 6'h08)) ? 1'b0 : 1'b1;
```

立即数操作相关控制信号。

```verilog
assign LuOp = OpCode == 6'h0f; //lui
assign ExtOp = (OpCode == 6'h0c || OpCode == 6'h0d) ? 0 : 1; //仅andi与ori用无符号扩展
```
寄存器堆写入地址。由于支持`jal`和`jalr`，需要单独加入`$ra`的地址选项。
```verilog
assign RegDst = (OpCode == 6'h09 || OpCode == 6'h0f || OpCode == 6'h08 || OpCode == 6'h23 || OpCode == 6'h0a || OpCode == 6'h0d || OpCode == 6'h0c || OpCode == 6'h0b) ? 2'h0 : OpCode == 6'h03 ? 2'h2 : 2'h1; // 0:rt 1:rd 2:$ra
```

ALU的输入选择。`srl`、`sll`、`sra`三条移位指令的移位位数`shamt`应提供给ALU的`in1`接口，所以应该在ALU的`in1`前加一MUX，选择其数据来源于`busA`还是`shamt`。执行需要用立即数进行运算的I型指令例如`addi`、`ori`等时，需要ALU的`in2`接收立即数操作的输出，所以也应在`in2`前加一个判断。

```verilog
assign ALUSrcA = (OpCode == 6'h0 && (funct == 6'h00 || funct == 6'h02 || funct == 6'h03)) ? 1'b1 : 1'b0; //sll srl sra
assign ALUSrcB = (OpCode == 6'h0f || OpCode == 6'h08 || OpCode == 6'h23 || OpCode == 6'h2b || OpCode == 6'h09 || OpCode == 6'h0a || OpCode == 6'h0b || OpCode == 6'h0c || OpCode == 6'h0d) ? 1'b1 : 1'b0;
```

内存控制信号。

```verilog
assign MemWrite = OpCode == 6'h2b;
assign MemRead = OpCode == 6'h23;
```
对于`jal`、`jalr`，应当将当前指令的`PC+4`写回寄存器堆，所以我在`ALUout`后又加了一个MUX来选择哪个作为`ALUout`的值存入`MEM/WB`。
```verilog
assign ALUorRA = OpCode == 6'h03 || (OpCode == 6'h00 && funct == 6'h09); //jal jalr
```
只有`sw`指令需要从内存写回。
```verilog
assign MemtoReg = OpCode == 6'h23;
```

### 控制冒险与数据冒险的解决

我主要采用转发和阻塞的方式解决冒险问题。

#### 所有转发通路

1. WB->MEM.Write_Data
2. WB->EX.busA/EX.busB
3. WB->ID.busA/ID.busB
4. EX/MEM->EX.rs/EX.rt
5. EX/MEM->ID.rs/ID.rt

我梳理了可能遇到的数据冒险和控制冒险，并在后面列出了解决方案

#### 数据冒险

1. Load->Branch(MEM->ID.rs/ID.rt)(数据冒险部分，控制冒险见后)：若`lw`后紧跟分支指令（*并产生数据冒险*，下同），则需要先等待`lw`在MEM阶段读取数据，而后再在ID阶段判断分支。于是让IF和ID阶段stall两个周期，等待`lw`的MEM阶段结束，下一个周期从WB转发给ID阶段
2. ALU->branch(数据冒险部分，控制冒险见后)：若ALU运算指令后紧跟一个分支指令，则需要让IF和ID阶段stall一个周期，等待ALU计算结果，而后从EX/MEM转发给ID
3. LW->ALU：若`lw`指令后紧跟ALU运算指令，则令IF、ID和EX阶段stall一个周期，等待内存读取结束，而后从WB转发给EX.rs/EX.rt
4. Load->Store：若`lw`后紧跟`sw`，从WB转发给MEM.Write Data
5. jal->jr \$ra：由于jal指令后会有一个stall，所以紧随jal后的j指令会与前者相隔一条空指令。我的CPU设计在EX/MEM阶段将PC+4和ALUout合并，所以只要将EX/MEM中的ALUout转发给ID阶段的jr就好了。不过这个冒险在使用的程序中不太容易发生。

#### 控制冒险

1. Jump：直接将IF/ID清零以停止错误指令

2. Branch：若分支成立，则将IF/ID清零以停止错误指令，否则继续顺序执行就可以

#### 代码实现与解释

##### 转发

ID阶段的busA和busB可能需要接收转发。转发的来源有二，EX/MEM寄存器中的ALUout和WB的RegWriteData，再加上不转发共三种模式，分别用1,2,0来表示。首先要判断转发来源的指令是否写寄存器，如果不写就不用转发。如果写寄存器，那么看该条指令要写的数据是否已经生成，所以要看EXMEM寄存器的MemtoReg，如果是`lw`指令，就不能把EX/MEM阶段的数据转发出去。**先判断离得比较近的前序指令是否需要转发，再判断更久远的前序指令是否要转发，这一点很重要**。这样可以保证转发的数据是最新的，防止因连续的数据更新而出错。我的以下程序就先判断EXMEM，EXMEM不需要转发再看WB阶段。而后再看前序指令的目标寄存器是否为0号，如果是就不转发。因为首先对0号寄存器写入是非法的，其次由stall或reset产生的空指令也会将0号寄存器作为rt或rd，如果转发就会出错。最后再看目标地址是否和本条指令的数据源重合。

```verilog
assign ID_CompSourceA = (EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg == 1'b0 && EXMEM_RegWriteID == ID_rs && EXMEM_RegWriteID != 5'h0) ? 2'd1 : (WB_RegWrite == 1'b1 && WB_RegWriteID == ID_rs && WB_RegWriteID != 5'h0) ? 2'd2 : 2'd0;
assign ID_CompSourceB = (EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg == 1'b0 && EXMEM_RegWriteID == ID_rt && EXMEM_RegWriteID != 5'h0) ? 2'd1 : (WB_RegWrite == 1'b1 && WB_RegWriteID == ID_rt && WB_RegWriteID != 5'h0) ? 2'd2 : 2'd0;
```

EX阶段的busA和busB可能需要接收来自EX/MEM或WB的转发，判断逻辑和ID阶段的逻辑一样。

```verilog
assign EX_busAMUX = (EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg == 1'b0 && EXMEM_RegWriteID != 5'h0 && EXMEM_RegWriteID == EX_rs) ? 2'd1 : (WB_RegWrite == 1'b1 && WB_RegWriteID != 5'h0 && WB_RegWriteID == EX_rs) ? 2'd2 : 2'd0;
    assign EX_busBMUX = (EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg == 1'b0 && EXMEM_RegWriteID != 5'h0 && EXMEM_RegWriteID == EX_rt) ? 2'd1 : (WB_RegWrite == 1'b1 && WB_RegWriteID != 5'h0 && WB_RegWriteID == EX_rt) ? 2'd2 : 2'd0;
```

最后一个是WB到MEM.Write_Data的转发。现实中需要此类转发的场景很多，比如对整个数组的搬运，需要大量的读后写。当然，其他指令序列比如ALU后跟`sw`也会需要这种转发。这个转发的判断逻辑比较简单，就是WB阶段要写的寄存器和MEM阶段的rt是一致的。

```verilog
assign MEM_MemWriteDataSource = (WB_RegWrite == 1'b1 && WB_RegWriteID != 5'h0 && WB_RegWriteID == MEM_rt);
```

##### stall

接下来是级间寄存器的控制信号生成

先考察IF/ID是否需要保持不变。不考虑ID/EX或EX/MEM操作的影响，仅考虑IF/ID本身，有以下三种情况需要保持IF/ID不变：ALU->Branch数据冒险、Load->Branch冒险的第一次stall和Load->Branch冒险的第二次stall。首先通过`ID_PCSrc==2'd1`判断处在ID阶段的是一个分支指令，再看前序指令是否要写寄存器，写的是不是`$0`，最后看写的目标寄存器是否和本分支指令的数据来源冲突。

```verilog
assign holdIFID = ((IDEX_RegWriteID != 5'h0 && ID_PCSrc == 2'd1) && ((IDEX_RegWrite == 1'b1 && 				  					(IDEX_RegWriteID == ID_rs || IDEX_RegWrite == ID_rt)))) ||
//ALU->branch or Load->branch(stage1)
                  (EXMEM_RegWriteID != 5'h0 && ID_PCSrc == 2'd1 && EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg 				  == 1'b1 && (EXMEM_RegWriteID == ID_rs || EXMEM_RegWriteID == ID_rt)) ? 1'b1
//Load->branch(stage2)
                  :1'b0;
```

考察ID/EX寄存器是否需要保持不变。仍然，不考虑IF/ID与EX/MEM带来的影响，ID/EX在`lw`指令紧跟ALU时需要stall。先判断EX/MEM阶段是否写寄存器，其目标寄存器是否是0号寄存器，以及MEM阶段此时是否是`lw`指令。仍然，用`MemtoReg==1`判断`lw`指令。然后，判断EX阶段的`ALUSrcA`或`ALUSrcB`是否指向busA或busB，如果ALU此时执行**移位指令或立即数相关指令**，显然不用接收涉及busA或busB的转发。最后，还要看目标寄存器是否和rs或rt冲突。

```verilog
assign holdIDEX = EXMEM_RegWriteID != 5'h0 && (EXMEM_RegWrite == 1'b1 && EXMEM_MemtoReg == 1'b1 && ((EXMEM_RegWriteID == EX_rs && EX_ALUSrcA == 1'b0) || (EXMEM_RegWriteID == EX_rt && EX_ALUSrcB == 1'b0))) ? 1'b1 : 1'b0;
```

考察IF/ID寄存器是否需要清零。IF/ID寄存器的清零是由控制冒险产生的，所以只要检测当前ID阶段是否为跳转或分支指令就好了。注意如果分支指令被判断为分支不成立，则不用flush，继续顺序执行就好了。另外要注意的是ID阶段可能需要stall，如果在此时清空IF/ID寄存器，则会使该指令被**错误地清零**。所以`holdIFID`的优先级应当高于`flushIFID`，这会在更后面的代码中有所体现。

```verilog
assign flushIFID = (ID_PCSrc == 2'd2 || ID_PCSrc == 2'd3) || (ID_PCSrc == 2'd1 && ID_comp_true);
```

最后利用`holdIFID`、`holdIDEX`和`flushIFID`三个结果为依据生成`IFIDop`、`IDEXop`与`EXMEMop`三个控制信号。

```verilog
assign IFIDop = (holdIFID || holdIDEX) ? 2'd2 : flushIFID ? 2'd1 :2'd0;
assign IDEXop = holdIDEX ? 2'd2 : holdIFID ? 2'd1 : 2'd0; //IFID保持，IDEX不保持时，要清零IDEX，防止出现两个EX
assign EXMEMop = holdIDEX ? 2'h1 : 2'h0;
```

另外，在后续阶段保持不变时，应该保持PC不变。于是在IF更新PC时做此判断(注意第一行的判断)：

```verilog
assign PC_next = (IFIDop == 2'd2 || IDEXop == 2'd2 || EXMEMop == 2'd2) ? PC : //前序指令有阻塞时PC不更新
                 (PCSrc == 2'h0) ? PC_plus_4_wire :
                 (PCSrc == 2'h1) ? (comp_true ? branchPC : PC_plus_4_wire) :
                 (PCSrc == 2'h2) ? jPC :
                 (PCSrc == 2'h3) ? jrPC : PC_next;
```

### 分支比较器

ID阶段的`Comparer`模块负责按照指定的比较模式对输入的操作数进行比较，并输出分支是否成立的判断。

```verilog
 case(compOp)
    3'd0: comp_true <= busA == busB; //beq
    3'd1: comp_true <= busA != busB; //bne
     3'd2: comp_true <= busA[31] || (busA == 32'd0); //blez
    3'd3: comp_true <= (!busA[31] && (busA[30:0] != 31'd0)); //bgtz
    default: comp_true <= busA[31]; //bltz
 endcase
```

其中，对和0比较的判断，不能直接用大于小于号，那样是无符号比较，我一开始就是因为这个bug程序一直得不到正确结果。应该自己写判断符号位的代码。

### ALU

算术逻辑运算的大部分代码都是平凡的，但也存在和分支比较器一样的问题。所以为ALU设计了输入信号`sign`。如果`sign==1`，则为有符号比较，否则为无符号比较。控制信号在`ALUControl`模块中生成。

```verilog
wire unsigned_lo31_lt;
wire signed_lt;
assign unsigned_lo31_lt = (in1[30:0] < in2[30:0]);
assign signed_lt = (in1[31] ^ in2[31]) ? (in1[31]? 1 : 0) : unsigned_lo31_lt;
//.....
//case(ALUCtrl)
SLT: out <= {31'h00000000, sign ? signed_lt : in1 < in2};
```

### BCD外设

本硬件系统通过软件程序控制BCD外设，其原理是把一段内存地址作为外设的控制信号，通过程序修改该段内存的内容，从而实现控制BCD的显示。DataMem中的关键代码如下

```verilog
if(Address == 32'h40000010) begin
	BCDData <= Write_data[7:0]; //0xXXXXX[an][BCDData]
	an <= Write_data[11:8];
end
```

由于CPU主频相对于BCD的刷新频率过高，所以我在汇编程序里加入了计数器。BCD的其中一位开始显示后，等待一段时间才会切换到下一位，这样显示效果会更好。

```assembly
refreshdelay:
addi $t2, $t2, -1
bgtz $t2, refreshdelay
addi $t2, $zero, 10000 #等待10000个时钟周期，0.1ms，刷新率10KHz
```

另外，在控制BCD的显示时，需要将对应数字的控制信号写入内存，十六进制就有16种数字需要显示，顺序查找将涉及到连续的分支指令，会造成大量的stall，拖累性能。在本例中只需要显示22，所以按照0 1 2 3 4....的顺序排布查找就可以得到还说得过去的性能，但是如果显示内容随机，顺序查找每次平均要进行8.5次比较，性能很差。我在这里加入了一个二分查找

```assembly
determinedisp: #Binary Search
addi $t7, $t0, -7
bgtz $t7, gt7
beq $t0, 0x0 disp0
beq $t0, 0x1 disp1
beq $t0, 0x2 disp2
beq $t0, 0x3 disp3
beq $t0, 0x4 disp4
beq $t0, 0x5 disp5
beq $t0, 0x6 disp6
beq $t0, 0x7 disp7
gt7:
beq $t0, 0x8 disp8
beq $t0, 0x9 disp9
beq $t0, 0xa dispA
beq $t0, 0xb dispB
beq $t0, 0xc dispC
beq $t0, 0xd dispD
beq $t0, 0xe dispE
beq $t0, 0xf dispF
```

这样可以做到每次平均5.5次比较，这样性能有较大的提升。如果再加一级二分查找，能获得平均4.5次比较，但性能提升有限。

## 仿真结果及分析

本仿真使用春季学期数逻汇编大作业的测试样例作为测试样例，从源点到各点的最短路径距离分别为8 3 5 10 8，和为34，十六进制表示为0x22。由于采用软件方式控制外设BCD，理论上BCD使能an为1时，BCD应当显示2，对应内存为`0x5b`，an为2时，对应内存为`0x5b`，an为4或8时，BCD应当显示0，对应内存为`0x3f`。我将结果用返回值存在$v0中，也就是2号寄存器。仿真结果如下

//img

可以看出，CPU得到了正确的结果，并且数码管的使能信号与显示内容均正确。这验证了本处理器在功能设计上是正确的。由于需要保证更好的显示效果，显示一位BCD需要多个周期的时间，所以上图中好像结果瞬间就出了，但事实上放大前半部分才能看到计算过程。

//img

## 综合与实现情况

### 时序性能

我设置了100MHz的方波时钟

综合

//img

综合后的时序裕量为0.822ns

实现

//img

实现后的时序裕量为0.251ns，说明CPU能稳定工作的最短时钟周期为9.749ns，最高时钟频率为102.57MHz。

关键路径情况

//img

截至$v0返回正确结果的算法指令数

//img

算法开始时间

//img

算法结束时间

//img

CPI：

​	算法用时: 13790-110 = 13680ns
​	时钟周期数: 13680/10 = 1368
​	指令数: 1025
​	CPI = 1.3346

CPI较高，主要是因为汇编大作业写Dijkstra算法时尚没有流水线的知识，没有减少数据与控制冒险的意识，没有针对这方面专门优化过。

### 资源占用

//img

//img

## 硬件调试情况

//img

实际结果与仿真结果吻合。

## 文件清单

top.v

​	CPU.v

​		IF.v

​			InstMem.v

​		ID.v

​			RegFile.v

​			Comparer.v

​			Controller.v

​			ALUControl.v

​		EX.v

​			ALU.v

​		MEM.v

​		WB.v

​	DataMem.v

constraints.xdc //约束

demo_dijkstra.asm //程序

## 心得体会

//img
这次作业我从19号晚写到25号早上，期间大大小小备份了13个版本。之前在数落实验课上写的那些东西和流水线CPU一比更像是小打小闹。不过从最开始写之前感觉心理压力很大，生怕写出什么de不出来的bug，到在上学期数逻课的流水线的基础上搭好框架，做好顶层设计，再到最开始的a、b版，最后不知不觉竟比较顺利地完成了，我觉得自己还算比较幸运。

我认为这次作业是数逻课很好的补充。我上数逻课时以为自己学明白了，但只有当我真正自己写一个处理器，需要推敲设计的细节时，我才意识到很多东西我还没明白。比如说之前我没考虑过转发模块在什么时候判断应该把EX/MEM的数据转发给EX，只是按照对PPT的印象觉得应该判断寄存器堆的写使能为真，目标寄存器非0且有寄存器冲突就好。但是我自己在开始编写之前设计时就要细想，我意识到可能这时有效数据还没有生成，我才又将Load-Use冒险和这里联系了起来。又比如对于级间寄存器，保持和清空哪个更优先？或者同时有两个合法的转发来源，该怎么编写判断逻辑使得输入端能接收到正确的那个？这些问题在理论课上我并没有意识到。就是一开始可能学得比较碎片化，不同思维角度之间没有真的融会贯通，这一写才发现问题所在，才真正把思路理清。

我的另外一点收获是认识到了做好整体设计的重要性。我之前程设比较懒，倾向于想到哪写到哪，毕竟软件编程能更轻易地把程序拆成很多模块，即便写错了哪里，借助IDE强大的Debug工具，改起来也很容易。硬件编程虽然也能Debug，但是却不能像软件Debug一样一行一行跑着看，只能看最终波形来猜哪里写错了。定义Input和output接口时更是有很多变量要处理，稍不留神也许就接错了。所以我一开始就大致拟定了一个草稿，把模块怎么分割、各种冒险处理、输入输出和数据通路都大致想清楚，再去编写，写起来就更不容易出犯迷糊。

//img

这次实验也有些小遗憾，比如由于Dijkstra代码是在学习流水线之前写的，所以没有有意识地去优化代码，使得CPI比较高，没有把CPU本身的时序性能充分发挥出来。以及我本可以加入简单的动态分支预测，让处理器处理分支指令时的性能更好，但是由于个人的时间原因并没能进一步优化。

但总之，看到自己头一次写出来的处理器在板子上跑起来，还能给出正确结果，我还是很有成就感的。很感谢这一学期来理论课和实验课遇到的老师和助教们，是他们的帮助让我在数逻的学习和这次实验中少走了很多弯路，收获了很多知识。
