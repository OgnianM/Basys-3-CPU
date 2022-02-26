`timescale 1ns / 1ps


module clock_divider(input i_clk, input[31:0] factor, output reg dependent_clock = 0);
    
    reg[31:0] counter = 0;
    
    always@(posedge i_clk) begin
        counter = counter + 1;
        if (counter >= factor) begin
            dependent_clock <= ~dependent_clock;
            counter = 0;
        end 
    end
endmodule
