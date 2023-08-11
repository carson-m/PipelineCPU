`timescale 1ns / 1ps
module Comparer(
    input wire [31:0]busA,
    input wire [31:0]busB,
    input wire [2:0]compOp, // �ȽϷ��� 0:beq 1:bne 2:blez 3:bgtz 4:bltz
    output reg comp_true // �ȽϽ�����ڶ�ӦcompOp��Ϊ��ʱ����1�����򷵻�0
    );
    
    always @(*) begin
        case(compOp)
        3'd0: comp_true <= busA == busB; //beq
        3'd1: comp_true <= busA != busB; //bne
        3'd2: comp_true <= busA[31] | (busA == 32'd0); //blez
        3'd3: comp_true <= (!busA[31] & (busA[30:0] != 31'd0)); //bgtz
        default: comp_true <= busA[31]; //bltz
        endcase
    end
endmodule
