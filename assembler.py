# Crude Assembler for the StarCore-1 Processor
# Made by: Shaun Beautement & Neo Vorsatz

import sys

# Define Opcodes based on Section 3.2 [cite: 112]
OPCODES = {
    'LD':   '0000', 'ST':   '0001', 'ADD':  '0010', 'SUB':  '0011',
    'INV':  '0100', 'SHL':  '0101', 'SHR':  '0110', 'AND':  '0111',
    'OR':   '1000', 'SLT':  '1001', 'RSVD': '1010', 'BEQ':  '1011',
    'BNE':  '1100', 'JMP':  '1101'
}

def to_bin(value, bits):
    """Converts integer to signed/unsigned binary string."""
    if value < 0:
        value = (1 << bits) + value
    return format(value & ((1 << bits) - 1), f'0{bits}b')

def assemble(line):
    # Clean up line and split components
    line = line.replace(',', ' ').replace('(', ' ').replace(')', ' ').split()
    if not line: return None
    
    instr = line[0].upper()
    op = OPCODES[instr]
    
    try:
        # R-type: [OP][RS1][RS2][WS][unused] 
        if instr in ['ADD', 'SUB', 'SHL', 'SHR', 'AND', 'OR', 'SLT']:
            ws, rs1, rs2 = [int(x[1:]) for x in line[1:4]]
            return op + to_bin(rs1, 3) + to_bin(rs2, 3) + to_bin(ws, 3) + "000"

        # Special R-type: INV [cite: 112]
        elif instr == 'INV':
            ws, rs1 = [int(x[1:]) for x in line[1:3]]
            return op + to_bin(rs1, 3) + "000" + to_bin(ws, 3) + "000"

        # I-type: [OP][RS1][WS][Offset] 
        elif instr in ['LD', 'ST', 'BEQ', 'BNE']:
            # Handle both "LD R1, 4(R2)" and "BEQ R1, R2, 4"
            r_first, r_second, imm = [int(x[1:]) if x.startswith('R') else int(x) for x in line[1:4]]
            # Section 3.1: WS is encoded in [8:6] for I-type [cite: 105]
            return op + to_bin(r_second, 3) + to_bin(r_first, 3) + to_bin(imm, 6)

        # J-type: [OP][Offset] 
        elif instr == 'JMP':
            target = int(line[1])
            return op + to_bin(target, 12)

        # Reserved Opcode [cite: 112]
        elif instr == 'RSVD':
            return op + "0" * 12

    except Exception as e:
        return f"Error assembling {line}: {e}"

# Usage
if __name__ == "__main__":
    # Get input
    input_file = open(input("Enter input file: "), "r")
    asm_program = input_file.readlines()
    input_file.close()

    # Get output
    output_location:str = input("Enter output file: ")
    if output_location=="":
        output_location = "test/generated.prog"
    
    with open(output_location, "w") as f:
        for line in asm_program:
            binary = assemble(line)
            if binary:
                print(f"{line.ljust(15)} -> {binary}")
                f.write(binary + "\n")