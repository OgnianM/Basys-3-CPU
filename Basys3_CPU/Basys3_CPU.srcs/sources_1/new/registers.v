`timescale 1ns / 1ps



module registers#(parameter bits=15)(
     input clk,
     input [2:0] r1_sel,
     input [2:0] r2_sel,
     
     output[bits:0] r1_out,
     output[bits:0] r2_out,
     
     input[bits:0] r1_in,
     input[bits:0] r2_in,
     
     input update,
     input imm_source
    );
    
    reg rst = 1;
    reg[2:0] rst_sel = 0;
    
    always@(posedge clk) begin
        if (rst_sel == 7) rst <= 0;
        else rst_sel <= rst_sel + 1;
    end
    
    
    wire[2:0] r1_sel_internal = rst ? rst_sel : r1_sel;
    wire update_internal = rst | update;
    
    
    
    reg[15:0] gprs[7:0];
    
    assign r1_out = gprs[r1_sel],
            r2_out = gprs[r2_sel];

    always@(posedge clk) 
    begin
        if (update_internal) begin
            gprs[r1_sel_internal] <= r1_in;
            
            if (!imm_source && r1_sel != r2_sel)
                gprs[r2_sel] <= r2_in;
        end
    end
    
    
    
endmodule
