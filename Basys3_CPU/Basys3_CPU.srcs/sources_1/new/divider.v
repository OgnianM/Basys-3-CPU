`timescale 1ns / 1ps


module divider#(parameter bits = 15)(
    input clk,
    input enabled,
    
    input[bits:0] a,
    input[bits:0] b,
    output reg[bits:0] result,
    output reg[bits:0] remainder,
    
    output done
    );
    
    
    reg last_cycle_enabled = 0;
    reg[7:0] bit = 0;
    reg[bits*2+1:0] divisor_intermediate;
   
   
    assign done = enabled ? (~last_cycle_enabled ? 0 : (bit == 8'hff | (remainder < b))) : 1;
   

    always@(posedge clk) begin
        
        last_cycle_enabled <= enabled;
        
        if(enabled) begin
            if (~last_cycle_enabled) begin
                remainder <= a;
                divisor_intermediate <= b << bits;

                bit <= (!a || !b) ? 8'hff : bits;
                result <= 0;

            end else if (~done) begin
            
                if (remainder >= divisor_intermediate) begin
                    remainder <= remainder - divisor_intermediate;
                    result[bit] <= 1;
                end
            
                divisor_intermediate <= divisor_intermediate >> 1;
                
                bit <= bit - 1;                
            end    
        end
    end
    
endmodule
