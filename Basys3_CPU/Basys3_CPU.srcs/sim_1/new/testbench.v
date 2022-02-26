`timescale 1ns / 1ps



module testbench();
    
    reg clock = 0;
    
    
    always #1 clock = ~clock;
    
    
    reg[15:0] sw = 133;
    
    wire[15:0] leds;
    wire[6:0] seg;
    wire[3:0] anode;
    
    
    top t(clock, sw, leds, seg, anode);
    
    
endmodule
