// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : ALU_tb.v
// Description : Testbench for the ALU module (Task 1).
//               Applies all 8 operations with multiple input pairs and checks
//               both the result output and the zero flag.
//               Produces automated PASS/FAIL output and a waveform dump.
//
// Run:
//   iverilog -Wall -I ../src -o ../build/alu_sim ../src/ALU.v ALU_tb.v
//   cd ../test && ../build/alu_sim
//   gtkwave ../waves/alu_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ALU_tb;

    // -------------------------------------------------------------------------
    // DUT port connections
    // Inputs to the DUT are declared as reg (so the testbench can drive them).
    // Outputs from the DUT are declared as wire (driven by the DUT).
    // -------------------------------------------------------------------------
    reg  [15:0] a;
    reg  [15:0] b;
    reg  [ 2:0] alu_control;
    wire [15:0] result;
    wire        zero;

    // -------------------------------------------------------------------------
    // DUT instantiation — named port connections
    // -------------------------------------------------------------------------
    ALU uut (
        .a           (a),
        .b           (b),
        .alu_control (alu_control),
        .result      (result),
        .zero        (zero)
    );

    // -------------------------------------------------------------------------
    // Waveform dump — always include this block
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("../waves/alu_tb.vcd");
        $dumpvars(0, ALU_tb);
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
    // Reusable check task
    // Compares 'got' against 'expected' and prints PASS or FAIL.
    // Increments fail_count on mismatch.
    // -------------------------------------------------------------------------
    task check_result;
        input [15:0] got;
        input [15:0] expected;
        input [63:0] id;        // test number for display
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: result = %0d (0x%h), expected = %0d (0x%h)",
                         id, got, got, expected, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [T%0d]: result = %0d (0x%h)", id, got, got);
            end
        end
    endtask

    task check_zero;
        input got;
        input expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d] zero flag: got = %b, expected = %b", id, got, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [T%0d] zero flag = %b", id, got);
            end
        end
    endtask

    // =========================================================================
    // STIMULUS AND CHECKING
    // =========================================================================
    initial begin
        $display("=== ALU Testbench ===");
        $display("--- ADD (alu_control = 3'b000) ---");

        // Test ADD
        begin: add_tests
            localparam N = 11;

            integer i, va[0:N-1], vb[0:N-1], vresult[0:N-1], vzero[0:N-1]; i=0;
            // Positive numbers, positive result.
            va[i]=10;     vb[i]=5;       vresult[i]=15; vzero[i]=0; i=i+1;
            // Positive numbers, reversed.
            va[i]=5;      vb[i]=10;      vresult[i]=15; vzero[i]=0; i=i+1;

            // Small negative numbers, negative result.
            va[i]=-10;    vb[i]=-5;     vresult[i]=-15; vzero[i]=0; i=i+1;
            // Small negative numbers, reversed.
            va[i]=-5;     vb[i]=-10;    vresult[i]=-15; vzero[i]=0; i=i+1;

            // Positive an negative number, positive result.
            va[i]=0124;    vb[i]=-0123;  vresult[i]=1;  vzero[i]=0; i=i+1;
            // Positive an negative number, negative result.
            va[i]=0123;    vb[i]=-0124;  vresult[i]=-1; vzero[i]=0; i=i+1;
            // Positive an negative number, zero result.
            va[i]=0123;    vb[i]=-0123;  vresult[i]=0;  vzero[i]=1; i=i+1;

            // Overflow conditions.
            va[i]='ha000;  vb[i]='h6000+1; vresult[i]=1;      vzero[i]=0; i=i+1;
            va[i]='hffff;  vb[i]='hffff;   vresult[i]='hfffe; vzero[i]=0; i=i+1;
            va[i]='hffff;  vb[i]=1;        vresult[i]=0;      vzero[i]=1; i=i+1;

            // Zeros.
            va[i]='h0000; vb[i]='h0000; vresult[i]=0;   vzero[i]=1; i=i+1;

            alu_control = 3'b000;
            for (i = 0; i < N; i = i + 1) begin
                // Set inputs and wait for combinational logic to settle.
                a = va[i]; b = vb[i]; #10
                // Check outputs
                check_result(result, vresult[i], test_id); test_id = test_id + 1;
                check_zero(zero, vzero[i],       test_id); test_id = test_id + 1;
            end
        end


        $display("--- SUB (alu_control = 3'b001) ---");

        // Test SUB
        begin: sub_tests
            localparam N = 13;

            integer i, va[0:N-1], vb[0:N-1], vresult[0:N-1], vzero[0:N-1]; i=0;
            // Small positive numbers, positive result.
            va[i]=10;     vb[i]=5;     vresult[i]=5;    vzero[i]=0; i=i+1;
            // Large positive values, positive result.
            va[i]=40000;  vb[i]=39567; vresult[i]=433;  vzero[i]=0; i=i+1;
            // Small positive numbers, negative result.
            va[i]=5;      vb[i]=10;    vresult[i]=-5;   vzero[i]=0; i=i+1;
            // Large positive numbers, negative result.
            va[i]=39567;  vb[i]=40000; vresult[i]=-433; vzero[i]=0; i=i+1;

            // Small negative numbers, negative result.
            va[i]=-10;     vb[i]=-5;     vresult[i]=-5;   vzero[i]=0; i=i+1;
            // Large negative values, negative result.
            va[i]=-20000;  vb[i]=-19567; vresult[i]=-433; vzero[i]=0; i=i+1;
            // Small negative numbers, positive result.
            va[i]=-5;      vb[i]=-10;    vresult[i]=5;    vzero[i]=0; i=i+1;
            // Large negative numbers, positive result.
            va[i]=-19567;  vb[i]=-20000; vresult[i]=433;  vzero[i]=0; i=i+1;

            // Positive an negative number, positive result.
            va[i]=0123;    vb[i]=-0123;  vresult[i]=0246; vzero[i]=0; i=i+1;

            // Overflow
            va[i]='ha000;  vb[i]=-('h6000+1); vresult[i]=1; vzero[i]=0; i=i+1;

            // Cancellation of identical inputs.
            va[i]='h0000; vb[i]='h0000; vresult[i]=0;   vzero[i]=1; i=i+1;
            va[i]='h1234; vb[i]='h1234; vresult[i]=0;   vzero[i]=1; i=i+1;
            va[i]='hffff; vb[i]='hffff; vresult[i]=0;   vzero[i]=1; i=i+1;

            alu_control = 3'b001;
            for (i = 0; i < N; i = i + 1) begin
                // Set inputs and wait for combinational logic to settle.
                a = va[i]; b = vb[i]; #10
                // Check outputs
                check_result(result, vresult[i], test_id); test_id = test_id + 1;
                check_zero(zero, vzero[i],       test_id); test_id = test_id + 1;
            end
        end


        $display("--- INV (alu_control = 3'b010) ---");

        // Test INV (bitwise NOT, b must be ignored)
        begin: inv_tests
            localparam N = 5;

            integer i, va[0:N-1], vb[0:N-1], vresult[0:N-1], vzero[0:N-1]; i=0;
            // All zeros, and check that b is ignored.
            va[i]='h0000; vb[i]='h0000; vresult[i]='hffff; vzero[i]=0; i=i+1;
            va[i]='h0000; vb[i]='hb3b3; vresult[i]='hffff; vzero[i]=0; i=i+1;
            // All ones. And check that b is ignored.
            va[i]='hffff; vb[i]='h0000; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='hffff; vb[i]='hb3b3; vresult[i]='h0000; vzero[i]=1; i=i+1;
            // Some on, some off.
            va[i]='h37ae; vb[i]='hffff; vresult[i]='hc851; vzero[i]=0; i=i+1;

            alu_control = 3'b010;
            for (i = 0; i < N; i = i + 1) begin
                // Set inputs and wait for combinational logic to settle.
                a = va[i]; b = vb[i]; #10
                // Check outputs
                check_result(result, vresult[i], test_id); test_id = test_id + 1;
                check_zero(zero, vzero[i],       test_id); test_id = test_id + 1;
            end
        end


        $display("--- SHL (alu_control = 3'b011) ---");

        // Test left shift. Remember only b[3:0] is used as the shift amount.
        begin: shl_tests
            localparam N = 16;

            integer i, va[0:N-1], vb[0:N-1], vresult[0:N-1], vzero[0:N-1]; i=0;
            // Test zero with various shifts.
            va[i]='h0000; vb[i]='h0000; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h0000; vb[i]='h0001; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h0000; vb[i]='h0003; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h0000; vb[i]='hffff; vresult[i]='h0000; vzero[i]=1; i=i+1;
            // Test 1 with various shifts.
            va[i]='h0001; vb[i]='h0000; vresult[i]='h0001; vzero[i]=0; i=i+1;
            va[i]='h0001; vb[i]='h0001; vresult[i]='h0002; vzero[i]=0; i=i+1;
            va[i]='h0001; vb[i]='h0003; vresult[i]='h0008; vzero[i]=0; i=i+1;
            va[i]='h0001; vb[i]='hffff; vresult[i]='h8000; vzero[i]=0; i=i+1;
            // Test last bit with various shifts.
            va[i]='h8000; vb[i]='h0000; vresult[i]='h8000; vzero[i]=0; i=i+1;
            va[i]='h8000; vb[i]='h0001; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h8000; vb[i]='hffff; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h8000; vb[i]='h0010; vresult[i]='h8000; vzero[i]=0; i=i+1;
            // Test 0xFFFF with various shifts.
            va[i]='hffff; vb[i]='h0000; vresult[i]='hffff; vzero[i]=0; i=i+1;
            va[i]='hffff; vb[i]='h0001; vresult[i]='hfffe; vzero[i]=0; i=i+1;
            va[i]='hffff; vb[i]='h0003; vresult[i]='hfff8; vzero[i]=0; i=i+1;
            va[i]='hffff; vb[i]='hffff; vresult[i]='h8000; vzero[i]=0; i=i+1;

            alu_control = 3'b011;
            for (i = 0; i < N; i = i + 1) begin
                // Set inputs and wait for combinational logic to settle.
                a = va[i]; b = vb[i]; #10
                // Check outputs
                check_result(result, vresult[i], test_id); test_id = test_id + 1;
                check_zero(zero, vzero[i],       test_id); test_id = test_id + 1;
            end
        end


        $display("--- SHR (alu_control = 3'b100) ---");

        // Test right shift. (logical — MSB fills with 0).
        begin: shr_tests
            localparam N = 16;

            integer i, va[0:N-1], vb[0:N-1], vresult[0:N-1], vzero[0:N-1]; i=0;
            // Test zero with various shifts.
            va[i]='h0000; vb[i]='h0000; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h0000; vb[i]='h0001; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h0000; vb[i]='h0003; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h0000; vb[i]='hffff; vresult[i]='h0000; vzero[i]=1; i=i+1;
            // Test final bit with various shifts.
            va[i]='h8000; vb[i]='h0000; vresult[i]='h8000; vzero[i]=0; i=i+1;
            va[i]='h8000; vb[i]='h0001; vresult[i]='h4000; vzero[i]=0; i=i+1;
            va[i]='h8000; vb[i]='h0003; vresult[i]='h1000; vzero[i]=0; i=i+1;
            va[i]='h8000; vb[i]='hffff; vresult[i]='h0001; vzero[i]=0; i=i+1;
            // Test first bit with various shifts.
            va[i]='h0001; vb[i]='h0000; vresult[i]='h0001; vzero[i]=0; i=i+1;
            va[i]='h0001; vb[i]='h0001; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h0001; vb[i]='hffff; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h0001; vb[i]='h0010; vresult[i]='h0001; vzero[i]=0; i=i+1;
            // Test 0xFFFF with various shifts.
            va[i]='hffff; vb[i]='h0000; vresult[i]='hffff; vzero[i]=0; i=i+1;
            va[i]='hffff; vb[i]='h0001; vresult[i]='h7fff; vzero[i]=0; i=i+1;
            va[i]='hffff; vb[i]='h0003; vresult[i]='h1fff; vzero[i]=0; i=i+1;
            va[i]='hffff; vb[i]='hffff; vresult[i]='h0001; vzero[i]=0; i=i+1;

            alu_control = 3'b100;
            for (i = 0; i < N; i = i + 1) begin
                // Set inputs and wait for combinational logic to settle.
                a = va[i]; b = vb[i]; #10
                // Check outputs
                check_result(result, vresult[i], test_id); test_id = test_id + 1;
                check_zero(zero, vzero[i],       test_id); test_id = test_id + 1;
            end
        end

        $display("--- AND (alu_control = 3'b101) ---");

        // Test bitwise AND.
        begin: and_tests
            localparam N = 6;

            integer i, va[0:N-1], vb[0:N-1], vresult[0:N-1], vzero[0:N-1]; i=0;
            // Test and with zero.
            va[i]='h0000; vb[i]='h1234; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='habcd; vb[i]='h0000; vresult[i]='h0000; vzero[i]=1; i=i+1;
            // Test and with ffff.
            va[i]='h2468; vb[i]='hffff; vresult[i]='h2468; vzero[i]=0; i=i+1;
            va[i]='hffff; vb[i]='h9bdf; vresult[i]='h9bdf; vzero[i]=0; i=i+1;
            // Test with a mixture of set bits.
            va[i]='h1234; vb[i]='h0f0f; vresult[i]='h0204; vzero[i]=0; i=i+1;
            // Test with mutually exclusive bits.
            va[i]='h55cc; vb[i]='haa33; vresult[i]='h0000; vzero[i]=1; i=i+1;

            alu_control = 3'b101;
            for (i = 0; i < N; i = i + 1) begin
                // Set inputs and wait for combinational logic to settle.
                a = va[i]; b = vb[i]; #10
                // Check outputs
                check_result(result, vresult[i], test_id); test_id = test_id + 1;
                check_zero(zero, vzero[i],       test_id); test_id = test_id + 1;
            end
        end

        $display("--- OR (alu_control = 3'b110) ---");

        // Test bitwise OR.
        begin: or_tests
            localparam N = 6;

            integer i, va[0:N-1], vb[0:N-1], vresult[0:N-1], vzero[0:N-1]; i=0;
            // Test or with zero.
            va[i]='h0000; vb[i]='h1234; vresult[i]='h1234; vzero[i]=0; i=i+1;
            va[i]='habcd; vb[i]='h0000; vresult[i]='habcd; vzero[i]=0; i=i+1;
            // Test or with ffff.
            va[i]='h2468; vb[i]='hffff; vresult[i]='hffff; vzero[i]=0; i=i+1;
            va[i]='hffff; vb[i]='h9bdf; vresult[i]='hffff; vzero[i]=0; i=i+1;
            // Test with a mixture of set bits.
            va[i]='h1234; vb[i]='h0f0f; vresult[i]='h1f3f; vzero[i]=0; i=i+1;
            // Test with mutually exclusive bits.
            va[i]='h55cc; vb[i]='haa33; vresult[i]='hffff; vzero[i]=0; i=i+1;

            alu_control = 3'b110;
            for (i = 0; i < N; i = i + 1) begin
                // Set inputs and wait for combinational logic to settle.
                a = va[i]; b = vb[i]; #10
                // Check outputs
                check_result(result, vresult[i], test_id); test_id = test_id + 1;
                check_zero(zero, vzero[i],       test_id); test_id = test_id + 1;
            end
        end


        $display("--- SLT (alu_control = 3'b111) ---");

        // Test set-less-than. Result must be 1 when a < b (unsigned), 0 otherwise.
        begin: sltu_tests
            localparam N = 10;

            integer i, va[0:N-1], vb[0:N-1], vresult[0:N-1], vzero[0:N-1]; i=0;
            // Test equal values (false cases).
            va[i]='h0000; vb[i]='h0000; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h1234; vb[i]='h1234; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='hffff; vb[i]='hffff; vresult[i]='h0000; vzero[i]=1; i=i+1;
            // Test a < b (true cases).
            va[i]='h0000; vb[i]='h0001; vresult[i]='h0001; vzero[i]=0; i=i+1;
            va[i]='h1234; vb[i]='h5678; vresult[i]='h0001; vzero[i]=0; i=i+1;
            va[i]='h7fff; vb[i]='h8000; vresult[i]='h0001; vzero[i]=0; i=i+1;
            va[i]='h0000; vb[i]='hffff; vresult[i]='h0001; vzero[i]=0; i=i+1;
            // Test a > b (false cases).
            va[i]='h0001; vb[i]='h0000; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='h5678; vb[i]='h1234; vresult[i]='h0000; vzero[i]=1; i=i+1;
            va[i]='hffff; vb[i]='h0000; vresult[i]='h0000; vzero[i]=1; i=i+1;

            alu_control = 3'b111;
            for (i = 0; i < N; i = i + 1) begin
                // Set inputs and wait for combinational logic to settle.
                a = va[i]; b = vb[i]; #10
                // Check outputs
                check_result(result, vresult[i], test_id); test_id = test_id + 1;
                check_zero(zero, vzero[i],       test_id); test_id = test_id + 1;
            end
        end

        // $display("--- Zero flag edge cases ---");
        // Note: all zero-flag edge cases are tested above as required, including but not limited to:
        //   Verify the zero flag is asserted for SUB where a == b.
        //   Verify the zero flag is de-asserted for all non-zero results.
        //   Verify the zero flag for INV of 16'hFFFF (result should be 0).

        // -----------------------------------------------------------------------
        // Summary
        // -----------------------------------------------------------------------
        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);

        $finish;
    end

endmodule
