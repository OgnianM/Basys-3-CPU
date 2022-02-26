<h1> A simple CPU for the Basys 3 board </h1>



<h2> Assembler </h2>

I've based the syntax on Intel x86 assembly, if an instruction has outputs, 
they are stored in operand 1, unless otherwise specified.

All integers in the source are interpreted as hexadecimal, hex integers starting with a letter must be prefixed by
'0x' or they will be interpreted as labels.

The assembler itself doesn't do a lot of syntax validation or error handling.

<h3> Operand types </h3>

| Type | Meaning                                 |
|------|-----------------------------------------|
| reg  | Any GP register r0-r7                   |
| imm  | Any 16-bit hex immediate, 0x0000-0xFFFF |
| any  | reg or imm                              |
| none | No operand                              |


<h3> Instruction set </h3>


| instruction | operand 1 | operand 2 | Note                                                                                           |
|-------------|-----------|-----------|------------------------------------------------------------------------------------------------|
| add         | reg       | any       |                                                                                                |
| sub         | reg       | any       |                                                                                                |
| mul         | reg       | any       | Result stored in <code>{r0 (low 16 bits), r1 (high 16 bits)} </code>                           |
| div         | reg       | any       | Result stored in r0, remainder stored in r1                                                    |
| and         | reg       | any       |                                                                                                |
| or          | reg       | any       |                                                                                                |
| xor         | reg       | any       |                                                                                                |
| not         | reg       |           |                                                                                                |
| shr         | reg       | any       | Only the first 4 bits of op2 are used, the rest are ignored                                    |
| shl         | reg       | any       | Only the first 4 bits of op2 are used, the rest are ignored                                    |
| mov         | reg       | any       |                                                                                                |
| swap        | reg       | reg       |                                                                                                |
| jmp         | any       |           |                                                                                                |
| cmp         | reg       | any       |                                                                                                |
| je          | any       |           |                                                                                                |
| jg          | any       |           |                                                                                                |
| jl          | any       |           |                                                                                                |
| jge         | any       |           |                                                                                                |
| jle         | any       |           |                                                                                                |
| jne         | any       |           |                                                                                                |
| push        | any       |           |                                                                                                |
| pop         | reg       |           |                                                                                                |
| lda         | reg       | any       | Load word at address specified by op2 in op1                                                   |
| sta         | reg       | any       | Store op2 at address specified by op1                                                          |
| call        | any       |           |                                                                                                |
| ret         |           |           |                                                                                                |
| ldsp        | reg       |           | Load stack pointer                                                                             |
| stsp        | any       |           | Set stack pointer                                                                              |
| dled        | any       |           | Display value on LEDs                                                                          |
| ldsw        | reg       |           | Load value of switches                                                                         |
| d7sd        | any       |           | Display value on 7-segment display (hex)<br>Up to 0xFFFF                                       |
| clkdiv      | reg       | any       | Divide core clock by <code>{op1 (low 16), op2 (high 16)}</code><br/> The LSB of op1 is ignored |
| hlt         |           |           | Halt the CPU                                                                                   |

<h3> Labels </h3>
A reference to a label simply turns into an immediate that contains the address of the instruction right after the label. <br>
A special <code>program_end</code> label points to the first uninitialized word after the binary.

<h3> Memory initialization </h3>
<code> dw</code> (define word) can be used to emit arbitrary data into any part of the binary. <br>
<code> dw [size] val1, val2, ..., valN, [implicit zeros up to size]</code> <br>

<h2> CPU </h2>

The CPU itself simply executes the instructions described above, there are no interrupts or out of order execution or
anything fancy really. <br>
All operations work on unsigned 16-bit integers. <br>
Execution starts at address 0 and continues until it encounters a <code>hlt</code> instruction.

The memory size is currently set to 1024 words. <br>
The stack pointer is initialized to point to the last word in memory. <br>
All memory past <code>program_end</code> is not initialized. <br>
All general purpose registers are initialized to zero. <br>

<h3> Execution times </h3>
Instructions with only registers as operands execute in 3 cycles, parsing an immediate takes one additional cycle. <br>
Multiplication and division take anywhere between 0 and 15 cycles on top of that.