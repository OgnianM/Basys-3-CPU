`timescale 1ns / 1ps




module memory#(parameter word_count=255)(
    input clk,
    input write,
    input[15:0] address,
    
    inout[15:0] memory_io
    );
    
    reg[15:0] mem[word_count:0];
    
    initial $readmemh("init_memory.mem", mem);

    assign memory_io = write ? 16'hz : mem[address];
        
    always@(posedge clk) begin
        if (write) 
            mem[address] = memory_io;
    end
    
    
endmodule
