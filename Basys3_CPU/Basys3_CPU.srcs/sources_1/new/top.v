`timescale 1ns / 1ps




module top(input clk, input[15:0] sw, output[15:0] LED, output[6:0] disp_cathode, output[3:0] disp_anode);
        
        
    parameter memory_size = 16'd1023;
            
    wire[15:0] disp_number,
                memory_address,
                memory_io;
                
    wire memory_write;
    
    memory#(memory_size) memory1(clk, memory_write, memory_address, memory_io);
    ssd_controller ctrl1(clk, disp_number, disp_cathode, disp_anode);
    core#(memory_size) cpu0(clk, memory_io, memory_address, memory_write, sw, LED, disp_number);

endmodule


