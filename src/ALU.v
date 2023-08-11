`timescale 1ns / 1ps
module ALU (
    ALUCtrl,
    sign,
    in1,
    in2,
    out
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

input [4:0] ALUCtrl;
input sign;
input [31:0] in1;
input [31:0] in2;
output [31:0] out;

reg [31:0] out;

wire unsigned_lo31_lt;
wire signed_lt;
assign unsigned_lo31_lt = (in1[30:0] < in2[30:0]);
assign signed_lt = (in1[31] ^ in2[31]) ? (in1[31]? 1 : 0) : unsigned_lo31_lt;

always @(*) begin
    case(ALUCtrl)
    ADD: out <= in1 + in2;
    SUB: out <= in1 - in2;
    AND: out <= in1 & in2;
    OR: out <= in1 | in2;
    XOR: out <= in1 ^ in2;
    NOR: out <= ~(in1 | in2);
    SLL: out <= in2 << in1[4:0];
    SRL: out <= in2 >> in1[4:0];
    SRA: out <= {{32{in2[31]}}, in2} >> in1[4:0];
    SLT: out <= {31'h00000000, sign ? signed_lt : in1 < in2};
    default: out <= 0;
    endcase
end

endmodule