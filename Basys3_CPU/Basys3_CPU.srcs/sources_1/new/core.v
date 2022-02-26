`timescale 1ns / 1ps



`include "instruction_defs.vh"

`define IMMEDIATE_OPERAND 8'b10000000



`define STATE_QUERY 0
`define STATE_FETCH 1
`define STATE_EXECUTE 2
`define STATE_FETCH_IMMEDIATE 3


module core#(parameter memory_size=1023)(
    input clk,

    inout[15:0] memory_io,
    output reg[15:0] address = 0,
    output reg memory_write_flag = 0,

    input[15:0] basys3_switches,
    output reg[15:0] basys3_leds = 0,
    output reg[15:0] basys3_disp = 0
    );
    
    // Core
    reg rst = 1;
    integer i = 0;
    
    // Stall execution for 8 cycles to allow the registers to clear themselves
    always@(posedge clk) begin
        if (rst) begin
            if (i == 7) begin
                rst <= 0;
            end else i <= i + 1;
        end
    end
    
    
    
    reg[15:0] memory_obus_reg = 0, 
              ip = 0,
              sp = memory_size,
              immediate;
    
    
    reg[7:0] flags = 0,
             state = `STATE_QUERY,
             opcode = 0,
             operand;
    
    
    wire[15:0] incremented_ip = (state == `STATE_FETCH ? address : ip) + 1;
    
    wire[7:0] instr = opcode;

    wire executing = state == `STATE_EXECUTE,
         imm16_source = operand[7];

   wire core_disabled = instr == `HLT | rst;    


    // Memory    
    wire[15:0] memory_ibus;
    reg[15:0] memory_obus = 0;
    assign memory_io = memory_write_flag ? memory_obus : 16'hz;
    assign memory_ibus = memory_io;
        
        
        
    // Clock        
    wire core_clock, divided_clock;
    reg[31:0] clk_div_factor = 0;
    clock_divider clk_div1(clk, clk_div_factor, divided_clock);
    
    /* 
        Disconnect the clock if core_disabled is high, 
        connect the clock to divided_clock if a clock divider is set, 
        otherwise simply use the device clock.
    */
    assign core_clock = core_disabled ? 0 : clk_div_factor != 0 ? divided_clock : clk;
    
    
    // Registers
    wire[2:0] r1_sel = operand[2:0], 
              r2_sel = operand[5:3];
              
    wire[15:0] r1_out, r2_out;
    reg[15:0] r1_result = 0, r2_result = 0;
    
    wire regs_update = state == `STATE_FETCH;

    /*
        r1_result and r2_result must be set to r1_out and r2_out respectively if
        the instruction does not modify them, as they get written to the selected 
        registers with no regard for the currently executing instruction.
        
        register contents get updated when state == `STATE_FETCH because that's just
        how the timing worked out.
    */
    registers regs1(rst ? clk : core_clock, r1_sel, r2_sel, r1_out, r2_out,
                    r1_result, r2_result, regs_update, imm16_source);
    
    wire[15:0] selected_v1 = r1_out,
               selected_v2 = imm16_source ? immediate : r2_out;      
               
    wire[15:0] selected_v1_or_imm16 = imm16_source ? immediate : selected_v1;
    
    
    // Arithmetic
    wire multiplier_enabled = (instr == `MUL),
        divider_enabled = (instr == `DIV);

    wire[15:0] alu_out1, alu_out2;
    
    wire alu_instruction = instr <= `SHL,
         alu_enabled = executing & alu_instruction;

    wire alu_done;
    
    alu alu1(core_clock, alu_enabled, multiplier_enabled, divider_enabled,
            instr, selected_v1, selected_v2, alu_out1, alu_out2, alu_done);
    

    wire stall = ~alu_done;
    
    
    always@(posedge core_clock)  begin
    
        case (state)
            
            `STATE_QUERY: begin
                
                // Store ALU results
                if (alu_instruction) 
                    r1_result <= alu_out1;
                    
                // Finalize memory reads
                else if (instr == `POP || instr == `LDA)
                    r1_result <= memory_ibus;
                    
                if (instr == `RET)
                    address <= memory_ibus;
                else  address <= ip;
                
                // Reset write flag
                memory_write_flag <= 0;
                state <= `STATE_FETCH;
            end        
            
            `STATE_FETCH: begin
            
                opcode <= memory_ibus[7:0];
                operand = memory_ibus[15:8];
                
                state <= (operand[7]) ? `STATE_FETCH_IMMEDIATE : `STATE_EXECUTE;
                
                ip <= incremented_ip;
                address <= incremented_ip;
            end 
            
            `STATE_FETCH_IMMEDIATE: begin
                state <= `STATE_EXECUTE;
                immediate <= memory_ibus;
                ip <= incremented_ip;
            end
            
            `STATE_EXECUTE: begin
            
                if (~stall)
                    state <= `STATE_QUERY;
                
                
                if (alu_enabled) begin
                    
                    if (alu_done) begin
                        if (multiplier_enabled | divider_enabled) begin
                            operand <= 8'b00001000;
                            r2_result <= alu_out2;
                        end else r2_result <= r2_out;
                    end

                end else begin
                
                    memory_write_flag <= (instr == `PUSH | instr == `CALL | instr == `STA);

                
                    case (instr)
                        
                        `PUSH, `CALL: sp <= sp - 1;
                        `POP, `RET: sp = sp + 1;
                        `STSP: sp <= selected_v1_or_imm16;
                    endcase
                    
                    
                    case (instr)
                        `LDA:  address <= selected_v2;
                        `STA:  address <= selected_v1;
                        `POP, `CALL, `RET, `PUSH:  address <= sp;
                    endcase
                    

                    case (instr)
                        `PUSH: memory_obus <= selected_v1_or_imm16;
                        `STA:  memory_obus <= selected_v2;
                        `CALL: memory_obus <= ip;
                    endcase
                    
                
                    case (instr) 
                        `JE:  if (flags[0]) ip <= selected_v1_or_imm16;
                        `JG:  if (flags[1]) ip <= selected_v1_or_imm16;
                        `JL:  if (flags[2]) ip <= selected_v1_or_imm16;
                        `JNE: if (~flags[0]) ip <= selected_v1_or_imm16;
                        `JGE: if (flags[0] | flags[1]) ip <= selected_v1_or_imm16;
                        `JLE: if (flags[0] | flags[2]) ip <= selected_v1_or_imm16;
                        `CALL, `JMP: ip <= selected_v1_or_imm16;
                    endcase

                    
                    case (instr)
                        `MOV:  r1_result <= selected_v2;
                        `SWAP: r1_result <= r2_out;
                        `LDSW: r1_result <= basys3_switches;
                        `LDSP: r1_result <= sp;
                        default: r1_result <= r1_out;
                    endcase
                            
                    
                                        
                    if (instr == `SWAP)
                        r2_result <= r1_out;
                    else r2_result <= r2_out;
                    
                    if (instr == `CMP) begin
                        flags[0] <= selected_v1 == selected_v2;
                        flags[1] <= selected_v1 > selected_v2;
                        flags[2] <= selected_v1 < selected_v2;
                    end 
                    

                    
                    if (instr == `CLKDIV) // Divide specified factor by two, since the counter only triggers on posedge
                        clk_div_factor <= {selected_v2, selected_v1} >> 1;           
                    
                    
                    if (instr == `DLED) 
                        basys3_leds <= selected_v1_or_imm16;
                    
                    if (instr == `D7SD) 
                        basys3_disp <= selected_v1_or_imm16;
                end
            end
            
        endcase
    end
    
    
endmodule
