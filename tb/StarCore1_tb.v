// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : StarCore1_tb.v
// Description : Integration testbench for the full StarCore-1 processor (Task 8).
//               Runs the program stored in test.prog and verifies processor
//               behaviour over multiple clock cycles using hierarchical signal
//               references.
//
//               This testbench does NOT drive the processor's datapath signals
//               directly — it only drives the clock and observes internal state
//               via hierarchical references.
//
// *** IMPORTANT — Expected compile behaviour with the skeleton ***
// When you first compile this testbench against the skeleton source files,
// iverilog will report "Unable to bind wire/reg/memory" errors for every
// hierarchical reference below (uut.DU.pc_current, uut.DU.instr, etc.).
// This is EXPECTED. Those signals do not yet exist because the Datapath
// module body is empty. The errors will disappear once you implement the
// internal signal declarations and sub-module instantiations in Datapath.v
// and StarCore1.v as required by Tasks 7 and 8.
//
// Hierarchical signal reference examples (valid after implementation):
//   uut.DU.pc_current              — Program Counter (reg in Datapath)
//   uut.DU.instr                   — Currently fetched instruction word (wire)
//   uut.DU.alu_result              — ALU output (wire)
//   uut.DU.zero_flag               — ALU zero flag (wire)
//   uut.DU.reg_file.reg_array[N]   — Register RN value (inside GPR instance)
//   uut.DU.dm.memory[N]            — Data memory word N (inside DataMemory instance)
//   uut.CU.reg_write               — ControlUnit reg_write output
//   uut.CU.alu_op                  — ControlUnit alu_op output
//
// The instance names used here (DU for Datapath, CU for ControlUnit, reg_file
// for GPR, dm for DataMemory) MUST match the names you use when instantiating
// those modules in StarCore1.v and Datapath.v respectively.
//
// Run:
//   iverilog -Wall -I ../src -o ../build/star_sim \
//       ../src/Parameter.v ../src/ALU.v ../src/GPR.v \
//       ../src/InstructionMemory.v ../src/DataMemory.v \
//       ../src/ALU_Control.v ../src/ControlUnit.v \
//       ../src/Datapath.v ../src/StarCore1.v StarCore1_tb.v
//   cd ../test && ../build/star_sim
//   gtkwave ../waves/star.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module StarCore1_tb;

    // -------------------------------------------------------------------------
    // Clock
    // -------------------------------------------------------------------------
    reg clk;
    initial clk = 1'b0;
    always  #5 clk = ~clk;     // 10 ns period — 100 MHz

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    StarCore1 uut (.clk(clk));

    // -------------------------------------------------------------------------
    // Waveform dump — captures ALL signals in the design hierarchy
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("./waves/star.vcd");
        $dumpvars(0, StarCore1_tb);
    end

    // -------------------------------------------------------------------------
    // Failure counter
    // -------------------------------------------------------------------------
    integer fail_count;
    integer test_id;

    initial begin
        fail_count = 0;
        test_id    = 1;
    end

    // -------------------------------------------------------------------------
    // Check tasks — compare 16-bit values observed via hierarchical reference
    // -------------------------------------------------------------------------
    task check16;
        input [15:0] got;
        input [15:0] expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: got = 0x%h (%0d), expected = 0x%h (%0d)",
                         id, got, got, expected, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: value = 0x%h (%0d)", id, got, got);
        end
    endtask

    // -------------------------------------------------------------------------
    // Cycle-by-cycle execution trace
    // This always block fires on every rising clock edge and prints the current
    // processor state. It is your primary debugging tool.
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        $display("%0t ns | PC=0x%h | instr=%b | R2=%3d R3=%3d R4=%3d R5=%3d | alu=%0d z=%b",
            $time,
            uut.DU.pc_current,
            uut.DU.instr,
            uut.DU.reg_file.reg_array[2],
            uut.DU.reg_file.reg_array[3],
            uut.DU.reg_file.reg_array[4],
            uut.DU.reg_file.reg_array[5],
            uut.DU.alu_result,
            uut.DU.zero_flag
        );
    end

    // =========================================================================
    // MAIN STIMULUS BLOCK
    // =========================================================================
    initial begin
        $display("=== StarCore-1 Integration Testbench ===");
        $display("=== Program loaded from ./test/test.prog ===");
        $display("=== Data memory loaded from ./test/test.data ===");
        $display("");

        // -----------------------------------------------------------------------
        // Wait for the simulation to run long enough for your program to
        // complete at least one full pass. Adjust SIM_TIME in Parameter.v
        // if your program needs more cycles.
        // -----------------------------------------------------------------------
        `SIM_TIME;

        // -----------------------------------------------------------------------
        // POST-SIMULATION VERIFICATION
        // -----------------------------------------------------------------------

        $display("");
        $display("--- Post-Simulation Verification (implement Datapath first) ---");

        // -----------------------------------------------------------------------
        // Verify register values after execution.
        // -----------------------------------------------------------------------

        // R0 and R1 are not used by the program, and must remain zero.
        $display("Checking R0 and R1 - unused (expect 0x0000):");
        check16(uut.DU.reg_file.reg_array[0], 16'h0000, test_id); test_id = test_id + 1;
        check16(uut.DU.reg_file.reg_array[1], 16'h0000, test_id); test_id = test_id + 1;

        // Register R2 should have been set to the final base-1 loop index (8).
        $display("Checking R2 after ADDs with 1 (expect R2+=1 (x8) = 0x0008):");
        check16(uut.DU.reg_file.reg_array[2], 16'h0008, test_id);
        test_id = test_id + 1;

        // Register R4 should have been set to the final triangular number (8th: 36).
        $display("Checking R3 after ADDs (expect 8th triangular number: 36):");
        check16(uut.DU.reg_file.reg_array[3], 16'd36, test_id);
        test_id = test_id + 1;

        // Register R4 should have been set to the final loop count (8) multiplied by two by the SHL instruction.
        $display("Checking R4 after SHR (expect final SHR outputs 0x0010):");
        check16(uut.DU.reg_file.reg_array[4], 16'h0010, test_id);
        test_id = test_id + 1;

        // Register R5 should have been reset to zero by the final SLT instruction.
        $display("Checking R5 after SLT (expect final SLT outputs 0x0000):");
        check16(uut.DU.reg_file.reg_array[5], 16'h0000, test_id);
        test_id = test_id + 1;

        // Register R6 should still be holding the number of triangular numbers, 8.
        $display("Checking R6 after LD (expect Mem[1] = 0x0008):");
        check16(uut.DU.reg_file.reg_array[6], 16'h0008, test_id);
        test_id = test_id + 1;

        // Register R7 should still be holding the number 1.
        $display("Checking R6 after LD (expect Mem[0] = 0x0001):");
        check16(uut.DU.reg_file.reg_array[7], 16'h0001, test_id);
        test_id = test_id + 1;

        // -----------------------------------------------------------------------
        // Verify program counter is spinning in the JMP loop.
        //    JMP is the 9th instruction. Each instruction is 2 bytes.
        //    The first instruction is at 0, so the 9th is at 16.
        //    Thus pc_current = 16
        // -----------------------------------------------------------------------
        $display("Checking PC in loop (expect PC = 0x0010):");
        check16(uut.DU.pc_current, 16'd16, test_id);
        test_id = test_id + 1;


        // -----------------------------------------------------------------------
        // Verify data memory.
        // Contents should be the 1st, 2nd, 3rd, ..., 8th triangular numbers.
        //
        // This provides that the SLT and BEQ instructions controlling the loop are working
        // correctly too. The loop run until the last triangular number was written,
        // and then the SLT set the loop condition to false, and BEQ didn't branch.
        // As a result, the loop stopped, preventing earlier results from being clobbered.
        // -----------------------------------------------------------------------
        $display("Checking DataMem after writing all triangular numbers with ST.");
        check16(uut.DU.dm.memory[0], 16'd1, test_id); test_id = test_id + 1;
        check16(uut.DU.dm.memory[1], 16'd3, test_id); test_id = test_id + 1;
        check16(uut.DU.dm.memory[2], 16'd6, test_id); test_id = test_id + 1;
        check16(uut.DU.dm.memory[3], 16'd10, test_id); test_id = test_id + 1;
        check16(uut.DU.dm.memory[4], 16'd15, test_id); test_id = test_id + 1;
        check16(uut.DU.dm.memory[5], 16'd21, test_id); test_id = test_id + 1;
        check16(uut.DU.dm.memory[6], 16'd28, test_id); test_id = test_id + 1;
        check16(uut.DU.dm.memory[7], 16'd36, test_id); test_id = test_id + 1;

        // -----------------------------------------------------------------------
        // Print register and memory state (safe to uncomment after Task 7)
        // -----------------------------------------------------------------------
        $display("");
        $display("--- Final Register File State ---");
        $display("R0=0x%h  R1=0x%h  R2=0x%h  R3=0x%h",
            uut.DU.reg_file.reg_array[0], uut.DU.reg_file.reg_array[1],
            uut.DU.reg_file.reg_array[2], uut.DU.reg_file.reg_array[3]);
        $display("R4=0x%h  R5=0x%h  R6=0x%h  R7=0x%h",
            uut.DU.reg_file.reg_array[4], uut.DU.reg_file.reg_array[5],
            uut.DU.reg_file.reg_array[6], uut.DU.reg_file.reg_array[7]);

        $display("");
        $display("--- Final Data Memory State ---");
        $display("Mem[0]=0x%h  Mem[1]=0x%h  Mem[2]=0x%h  Mem[3]=0x%h",
            uut.DU.dm.memory[0], uut.DU.dm.memory[1],
            uut.DU.dm.memory[2], uut.DU.dm.memory[3]);
        $display("Mem[4]=0x%h  Mem[5]=0x%h  Mem[6]=0x%h  Mem[7]=0x%h",
            uut.DU.dm.memory[4], uut.DU.dm.memory[5],
            uut.DU.dm.memory[6], uut.DU.dm.memory[7]);

        // -----------------------------------------------------------------------
        // Summary
        // -----------------------------------------------------------------------
        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d INTEGRATION TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d INTEGRATION TESTS FAILED ===", fail_count, test_id - 1);

        $finish;
    end

endmodule
