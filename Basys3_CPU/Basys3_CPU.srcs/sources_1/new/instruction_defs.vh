

// arithmetic
`define ADD 8'h00
`define SUB 8'h01
`define MUL 8'h02
`define DIV 8'h03


// bitwise
`define AND 8'h04
`define OR 8'h05
`define XOR 8'h06
`define NOT 8'h07
`define SHR 8'h08
`define SHL 8'h09

// move data
`define MOV 8'h0a
`define SWAP 8'h0b

// load immediates
`define LDIMML 8'h0c
`define LDIMMH 8'h0d

// control flow
`define JMP 8'h0e
`define CMP 8'h0f
`define JE 8'h10
`define JG 8'h11
`define JL 8'h12
`define JGE 8'h13
`define JNE 8'h14
`define JLE 8'h15
//`define JZ 8'h16
//`define JNZ 8'h17

// stack
`define PUSH 8'h18
`define POP 8'h19

// memory
`define LDA 8'h1a
`define STA 8'h1b

`define CALL 8'h1c
`define RET 8'h1d

`define LDSP 8'h1e
`define STSP 8'h1f


// Basys 3 specific
`define DLED 8'he0
`define LDSW 8'he1
`define D7SD 8'he2

// control CPU
`define CLKDIV 8'hfe
`define HLT 8'hff
