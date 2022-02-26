`timescale 1ns / 1ps


`include "instruction_defs.vh"


module alu#(parameter bits=15)(input clk, 
                            input enabled,
                            input multiplier_enabled,
                            input divider_enabled,
                            input[7:0] instr, 
                            input[bits:0] a, 
                            input[bits:0] b, 
                            output[bits:0] out1, 
                            output[bits:0] out2, 
                            output done);
                            
                        
    reg[bits:0] res1 = 0;

    wire[31:0] multiplier_result;
    wire[15:0] divider_result, divider_remainder;
    wire multiplier_done, divider_done;
    
    
    multiplier#(bits) mult1(clk, multiplier_enabled & enabled, a, b, multiplier_result, multiplier_done);
    divider#(bits) div1(clk, divider_enabled & enabled, a, b, divider_result, divider_remainder, divider_done);

    assign out1 = multiplier_enabled ? multiplier_result[15:0] : 
                    divider_enabled ? divider_result : res1;
                    
    assign out2 = multiplier_enabled ? multiplier_result[31:16] : divider_remainder;
    assign done = multiplier_done & divider_done;


    wire[3:0] shift_amount = b[3:0];

    always@(posedge clk) begin
        
        if (enabled) case (instr)
        
            `ADD: res1 <= a + b;
            `SUB: res1 <= a - b;
        
            `AND: res1 <= a & b;
            `OR:  res1 <= a | b;
            `XOR: res1 <= a ^ b;
            
            `NOT: res1 <= ~a;
                  
            `SHL: res1 <= a << shift_amount;
            `SHR: res1 <= a >> shift_amount;

        endcase
    
    end

endmodule