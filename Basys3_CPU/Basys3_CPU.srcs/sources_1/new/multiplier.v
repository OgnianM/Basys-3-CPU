`timescale 1ns / 1ps


module multiplier#(parameter bits=15)(
    input clk,
    input enabled,
    input [bits:0] a, 
    input [bits:0] b, 
    output reg[bits*2+1:0] result = 0,
    output done
);

    reg last_cycle_enabled = 0;
    
    reg[bits:0] multiplier = 0;
    reg[bits*2+1:0] multiplicand_intermediate;
    reg[7:0] bit = 0;
    
    /*
        Always not done for the first enabled cycle
    */
    assign done = enabled ? (~last_cycle_enabled ? 0 : (bit == (bits+1)) || !multiplier || !multiplicand_intermediate) : 1;

    always@(posedge clk) begin
        last_cycle_enabled <= enabled;
            
        if (enabled) begin
            if (~last_cycle_enabled) begin
                multiplicand_intermediate <= a;
                multiplier <= b;
                bit <= 0;
                result <= 0;
                
            end else if (~done) begin
                if (multiplier[bit] == 1) begin
                    result <= result + multiplicand_intermediate;
                    multiplier[bit] <= 0;
                end
                
                multiplicand_intermediate <= multiplicand_intermediate << 1;
                bit <= bit + 1;
            end
        end    
    end
endmodule
