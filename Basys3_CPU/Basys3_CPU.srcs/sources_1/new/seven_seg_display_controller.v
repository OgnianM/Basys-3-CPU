`timescale 1ns / 1ps




module ssd_controller(
    input clk,
    input[15:0] value,
    
    output reg[6:0] cathode,
    output[3:0] anode
    );
    
    reg[1:0] segment = 0;
    reg[3:0] digit;
    
    assign anode = ~(4'b0001 << segment);

    wire d_clk;
    clock_divider clkd1(clk, 32'd100000, d_clk);
    
    always@(posedge d_clk) begin

        segment = segment + 1;

        case (segment)
           2'h0: digit = value[3:0];
           2'h1: digit = value[7:4]; 
           2'h2: digit = value[11:8]; 
           2'h3: digit = value[15:12];
        endcase
        
        
        case (digit)
            4'h0: cathode = 7'b1000000;    // digit 0
            4'h1: cathode = 7'b1111001;    // digit 1
            4'h2: cathode = 7'b0100100;    // digit 2
            4'h3: cathode = 7'b0110000;    // digit 3
            4'h4: cathode = 7'b0011001;    // digit 4
            4'h5: cathode = 7'b0010010;    // digit 5
            4'h6: cathode = 7'b0000010;    // digit 6
            4'h7: cathode = 7'b1111000;    // digit 7
            4'h8: cathode = 7'b0000000;    // digit 8
            4'h9: cathode = 7'b0010000;    // digit 9
            4'ha: cathode = 7'b0001000;    // digit A
            4'hb: cathode = 7'b0000011;    // digit B
            4'hc: cathode = 7'b1000110;    // digit C
            4'hd: cathode = 7'b0100001;    // digit D
            4'he: cathode = 7'b0000110;    // digit E
            default: cathode = 7'b0001110; // digit F
        endcase
    end
    
endmodule
