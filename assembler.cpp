#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <unordered_map>
using namespace std;


void error(string const& msg)
{
    cout << "[ERROR] " << msg << endl;
    exit(-1);
}



#define OPERATION_WITH_IMMEDIATE16 0x8000

enum opcode : uint8_t
{
    // arithmetic
    ADD, SUB, MUL, DIV,

    // bitwise
    AND, OR, XOR, NOT, SHR, SHL,

    // move data
    MOV, SWAP,

    // control flow
    JMP=0x0e, CMP, JE, JG, JL, JGE, JNE, JLE,

    JZ, JNZ,

    // stack
    PUSH, POP,

    // memory
    LDA, STA,

    // subroutines
    CALL, RET,

    LDSP, STSP,


    // Basys 3 specific
    DLED = 0xe0, LDSW, D7SD,

    // control CPU
    CLKDIV = 0xfe, HLT,


    UNDEFINED = 0xdf
};

enum operand_type
{
    imm16,
    reg,
    any,
    none
};
struct instr
{
    opcode code = UNDEFINED;
    operand_type op1 = none, op2 = none;
};


uint16_t encode_register(string const& reg)
{
    if (reg[0] != 'r' || reg[1] < '0' || reg[1] > '7')
        error("Unrecognized register: " + reg);
    return reg[1] - '0';
}

bool is_register(string const& str)
{
    return str.size() == 2 && str[0] == 'r' && str[1] >= '0' && str[1] <= '7';
}


int main(int argc, char* argv[])
{
    if (argc != 3) {

        cout << "Usage: ./asm [input.asm] [output.mem]" << endl;
        return 1;
    }


    static unordered_map<string, instr> encoding =
    {
        { "dled", {DLED, any}},
        { "ldsw", {LDSW, any}},
        { "hlt", {HLT}},
        { "lda", {LDA, reg, any}}, // dst, addr
        { "sta", {STA, reg,any}}, // dst, addr
        { "d7sd", {D7SD, any}},
        { "mov", {MOV, reg, any}}, // dst, src
        { "swap", {SWAP, reg,reg}},
        { "add", {ADD, reg,any}},
        { "sub", {SUB, reg,any}},
        { "jmp", {JMP, any}},
        { "cmp", {CMP, reg,any}},
        { "je", {JE,any}},
        { "jg", {JG,any}},
        { "jl", {JL, any}},
        {"jge", {JGE, any}},
        {"jne", {JNE, any}},
        {"jle", {JLE, any}},
        { "shl", {SHL, reg, any}},
        { "mul", {MUL, reg, any}}, // result = { r0 (low 16), r1 (high 16) }
        { "div", {DIV, reg, any}}, // result = r0, remainder = r1
        { "clkdiv", {CLKDIV, reg, any}}, // {low 16, high 16}
        { "and", {AND, reg,any}},
        {"or", {OR, reg,any}},
        {"xor", {XOR, reg,any}},
        {"not", {NOT, reg}},
        {"shr", {SHR, reg, any}},

        {"push", {PUSH, any}},
        {"pop", {POP, reg}},
        {"call", {CALL, any}},
        {"ret", {RET}},
        {"ldsp", {LDSP, reg}},
        {"stsp", {STSP, any}}
    };


    string input = argv[1], output = argv[2];
    vector<string> asm_lines;


    unordered_map<size_t, size_t> line_offset_to_binary_address;
    unordered_map<string, size_t> label_to_line_offset;
    unordered_map<size_t, string> offset_to_label;


    vector<size_t> offsets_to_link;

    size_t current_offset = 0;


    auto decode_immediate = [&](string const& imm)
    {
        // Hex immediates starting with a letter must be prefixed by "0x" to differentiate them from labels
        if (imm[0] >= '0' && imm[0] <= '9')
            return uint16_t(stoi(imm, 0, 16));

        offset_to_label[current_offset + 1] = imm;
        offsets_to_link.push_back(current_offset+1);

        return uint16_t(0);
    };

    ofstream ofs(output, ios::trunc);
    ifstream ifs(input);

    if (!ifs.good())
        error("Unable to open file ");

    if (!ofs.good())
        error("Unable to create file " + output);

    string temp, hexcoded;

    while (getline(ifs,temp))
    {
        auto sc = temp.find(';');

        if (sc != string::npos)
            temp.erase(sc);

        while (!temp.empty() && temp.back() == ' ') temp.pop_back();
        while (!temp.empty() && temp[0] == ' ') temp.erase(temp.begin());

        if (!temp.empty())
        {


            auto it = temp.find(':');
            if (it != string::npos)
            {
                temp.erase(it);
                if (label_to_line_offset[temp] != 0)
                    cout << "[WARNING] Label redeclaration: \"" << temp << "\"" << endl;

                label_to_line_offset[temp] = asm_lines.size();
            }
            else
                asm_lines.push_back(temp);
         }
    }

    int line_number = 0;


    auto serialize_instr = [&](string& line) -> vector<uint16_t>
    {
        if (line.empty()) return {};

        for (auto& i : line) if (i == ',') i = ' ';

        stringstream ss(line);

        vector<string> components;
        string temp;


        while (getline(ss, temp, ' ')) {
            if (!temp.empty()) {
                auto it = temp.find(',');
                while (it != string::npos) {
                    temp.erase(it, 1);
                    it = temp.find(',');
                }
                components.push_back(temp);
            }
        }

        if (components.empty()) return {};

        if (components[0] == "dw")
        {
            if (components.size() == 1)
            {
                cout << "[WARNING] \"dw\" requires a size, omitting expression." << endl;
                return {};
            }
            int count = stoi(components[1], 0, 16);
            vector<uint16_t> words(count, 0);


            components.erase(components.begin(), components.begin() + 2);

            for (int i = 0; i < std::min<int>(count, components.size()); i++)
                words[i] = stoi(components[i], 0, 16);

            return words;
        }

        auto inst = encoding[components[0]];

        auto required_components = (inst.op1 != none) + (inst.op2 != none);

        if (inst.code == UNDEFINED)
            error("Unrecognized instruction: " + components[0]);

        if ((components.size() - 1) != required_components)
            error("Malformed instruction: " + line);

        uint16_t result = inst.code;

        if (inst.op1 == any)
            inst.op1 = is_register(components[1]) ? reg : imm16;

        if (inst.op2 == any)
            inst.op2 = is_register(components[2]) ? reg : imm16;


        switch(inst.op1)
        {
            case imm16:
                result |= OPERATION_WITH_IMMEDIATE16;
                return {result, decode_immediate(components[1])};
            case reg:
                result |= encode_register(components[1]) << 8;
                break;
            case none:
                return {result};
        }

        switch(inst.op2)
        {
            case imm16:
                result |= OPERATION_WITH_IMMEDIATE16;
                return {result, decode_immediate(components[2])};
            case reg:
                result |= encode_register(components[2]) << 11;
                break;
        }

        return {result};
    };


    vector<uint16_t> encoded;

    for (auto& i : asm_lines)
    {
        line_offset_to_binary_address[line_number++] = current_offset;

        auto coded = serialize_instr(i);
        current_offset += coded.size();
        if (!coded.empty())
            encoded.insert(encoded.end(), coded.begin(), coded.end());
    }

    // define a special program_end label
    label_to_line_offset["program_end"] = -1;
    line_offset_to_binary_address[-1] = encoded.size();


    for (auto& i : offsets_to_link)
    {
        auto lbl = offset_to_label[i];

        if (label_to_line_offset.find(lbl) == label_to_line_offset.end())
            error ("Undeclared label: " + lbl);

        auto loff = label_to_line_offset[lbl];
        auto offset = line_offset_to_binary_address[loff];
        encoded[i] = offset;
    }


    for (auto& y : encoded)
        ofs << std::hex << y << ' ';
    return 0;
}
