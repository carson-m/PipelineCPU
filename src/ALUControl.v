`timescale 1ns / 1ps
module ALUControl (
    input wire [5:0]OpCode,
    input wire [5:0]Funct,
    output reg [4:0]ALUCtrl,
    output reg Sign
);

parameter ADD = 5'h0;
parameter SUB = 5'h1;
parameter AND = 5'h2;
parameter OR = 5'h3;
parameter XOR = 5'h4;
parameter NOR = 5'h5;
parameter SLL = 5'h6;
parameter SRL = 5'h7;
parameter SRA = 5'h8;
parameter SLT = 5'h9;

always @(*) begin
    case(OpCode)
    6'h23: begin
        ALUCtrl <= ADD;  // lw
        Sign <= 1;
    end
    6'h20: begin
        ALUCtrl <= ADD;  // load byte(lb)
        Sign <= 1;
    end
    6'h2b: begin
        ALUCtrl <= ADD;  // sw
        Sign <= 1;
    end
    6'h0f: begin
        ALUCtrl <= ADD; // lui
        Sign <= Sign; //don't care
    end
    6'h08: begin
        ALUCtrl <= ADD; //addi
        Sign <= 1;
    end
    6'h09: begin
        ALUCtrl <= ADD; //addiu
        Sign <= 0;
    end
    6'h0c: begin
        ALUCtrl <= AND; //andi
        Sign <= Sign;
    end
    6'h0d: begin
        ALUCtrl <= OR; //ori
        Sign <= Sign;
    end
    6'h0a: begin
        ALUCtrl <= SLT; //slti
        Sign <= 1;
    end
    6'h0b: begin
        ALUCtrl <= SLT; //sltiu
        Sign <= 0;
    end
    6'h04: begin
        ALUCtrl <= SUB; // beq
        Sign <= Sign; //don't care
    end
    default: begin // Opcode = 0
        case(Funct)
        6'h20: begin
            ALUCtrl <= ADD;
            Sign <= 1;
        end
        6'h21: begin
            ALUCtrl <= ADD;
            Sign <= 0;
        end
        6'h22: begin
            ALUCtrl <= SUB;
            Sign <= 1;
        end
        6'h23: begin
            ALUCtrl <= SUB;
            Sign <= 0;
        end
        6'h24: begin
            ALUCtrl <= AND;
            Sign <= Sign;
        end
        6'h25: begin
            ALUCtrl <= OR;
            Sign <= Sign;
        end
        6'h26: begin
            ALUCtrl <= XOR;
            Sign <= Sign;
        end
        6'h27: begin
            ALUCtrl <= NOR;
            Sign <= Sign;
        end
        6'h00: begin
            ALUCtrl <= SLL;
            Sign <= Sign;
        end
        6'h02: begin
            ALUCtrl <= SRL;
            Sign <= 0;
        end
        6'h03: begin
            ALUCtrl <= SRA;
            Sign <= 1;
        end
        6'h2a: begin
            ALUCtrl <= SLT;
            Sign <= 1;
        end
        6'h2b: begin
            ALUCtrl <= SLT;
            Sign <= 0;
        end
        6'h08: begin
            ALUCtrl <= ADD;  // jr
            Sign <= Sign;
        end
        6'h09: begin
            ALUCtrl <= ADD;  // jalr
            Sign <= Sign;
        end
        default: begin
            ALUCtrl <= ALUCtrl;
            Sign <= Sign;
        end
        endcase
    end
    endcase    
end
    
endmodule