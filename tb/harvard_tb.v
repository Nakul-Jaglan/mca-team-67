`timescale 1ns/1ps

// ============================================================================
// Module: harvard_tb
// Project: MCA Project 9 - Instruction and Data Memory Hierarchy (Phase I)
// Owner: Puneet (Verification & Waveform Evidence)
//
// Description:
//   Integrated cycle-accurate verification testbench for harvard_top.
//   Verifies the controller, instruction ROM, and data RAM across all clock
//   edges from reset through completion.
//
// Key Checks:
//   1. Reset state (inhibit fetches and memory accesses, clear registers).
//   2. Dual-memory overlap on Edge 3: Simultaneous fetch of ROM[2] (LOAD)
//      and data write to RAM[3] (STORE 5).
//   3. Dual-memory overlap on Edge 4: Simultaneous fetch of ROM[3] (ADDI 1)
//      and data read from RAM[3] (LOAD 5).
//   4. Clean program termination on Edge 6 (HALT asserts, requests cease).
//   5. Final architectural state: ACC == 6, RAM[3] == 5, halted == 1.
// ============================================================================

module harvard_tb;

    reg clk;
    reg rst;
    wire [15:0] acc;
    wire halted;

    // Instantiate Top-Level Device Under Test (DUT)
    harvard_top dut (
        .clk(clk),
        .rst(rst),
        .acc(acc),
        .halted(halted)
    );

    // 100 MHz Simulation Clock (10 ns period)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Simulation Watchdog Timer (prevent hang on failure)
    initial begin
        #500;
        $fatal(1, "WATCHDOG TIMEOUT: Simulation exceeded 500 ns without completion.");
    end

    // Stimulus and Verification Process
    initial begin
        // Initialize VCD waveform dumping
        $dumpfile("build/harvard.vcd");
        $dumpvars(0, harvard_tb);

        // --------------------------------------------------------------------
        // 1. Reset Assertion (Synchronous reset held across 2 rising edges)
        // --------------------------------------------------------------------
        rst = 1'b1;
        @(posedge clk); // Clock Edge at 5 ns
        @(posedge clk); // Clock Edge at 15 ns

        // Check internal registers and bus signals during reset
        #1;
        if (dut.control.pc !== 4'd0 || dut.control.ir !== 16'd0 || 
            dut.control.ir_valid !== 1'b0 || acc !== 16'd0 || halted !== 1'b0) begin
            $fatal(1, "RESET CHECK FAILED: Controller registers not cleared during reset.");
        end
        if (dut.i_req !== 1'b0 || dut.d_re !== 1'b0 || dut.d_we !== 1'b0) begin
            $fatal(1, "RESET CHECK FAILED: Bus requests not inhibited during reset.");
        end

        // Deassert reset cleanly on falling edge (at 20 ns)
        @(negedge clk);
        rst = 1'b0;

        $display("\n==========================================================================");
        $display("   MCA PROJECT 9 (TEAM 67): HARVARD ARCHITECTURE VERIFICATION TRACE       ");
        $display("==========================================================================");
        $display("Edge | Pre-Edge Requests (Fetch, Data)      | Post-Edge State (ACC, Halted)");
        $display("-----+--------------------------------------+------------------------------");

        // --------------------------------------------------------------------
        // EDGE 1 (Posedge at 25 ns): Fetch ROM[0] = 3005 (ADDI 5). Data enables low.
        // --------------------------------------------------------------------
        // We are at 20 ns. Advance 4 ns to 24 ns (1 ns before posedge at 25 ns).
        #4;
        if (dut.i_req !== 1'b1 || dut.i_addr !== 4'd0 || dut.i_rdata !== 16'h3005 ||
            dut.d_re !== 1'b0 || dut.d_we !== 1'b0) begin
            $fatal(1, "EDGE 1 PRE-EDGE CHECK FAILED: Expected fetch ROM[0]=3005, data enables low.");
        end
        $write("  1  | Fetch ROM[0]=3005, Data idle        | ");

        @(posedge clk); #1; // Post-edge check at 26 ns
        if (dut.control.ir !== 16'h3005 || dut.control.pc !== 4'd1 || 
            dut.control.ir_valid !== 1'b1 || acc !== 16'd0 || halted !== 1'b0) begin
            $fatal(1, "EDGE 1 POST-EDGE CHECK FAILED: IR not loaded or ACC unexpectedly modified.");
        end
        $display("IR=3005, ACC=%0d, halted=%0d", acc, halted);

        // --------------------------------------------------------------------
        // EDGE 2 (Posedge at 35 ns): Fetch ROM[1] = 2300 (STORE). Execute ADDI 5 -> ACC = 5.
        // --------------------------------------------------------------------
        @(negedge clk); #4; // Advance to 34 ns (1 ns before posedge at 35 ns)
        if (dut.i_req !== 1'b1 || dut.i_addr !== 4'd1 || dut.i_rdata !== 16'h2300 ||
            dut.d_re !== 1'b0 || dut.d_we !== 1'b0) begin
            $fatal(1, "EDGE 2 PRE-EDGE CHECK FAILED: Expected fetch ROM[1]=2300, data enables low.");
        end
        $write("  2  | Fetch ROM[1]=2300, Data idle        | ");

        @(posedge clk); #1; // Post-edge check at 36 ns
        if (dut.control.ir !== 16'h2300 || dut.control.pc !== 4'd2 || 
            acc !== 16'd5 || halted !== 1'b0) begin
            $fatal(1, "EDGE 2 POST-EDGE CHECK FAILED: ACC !== 5 after ADDI 5.");
        end
        $display("IR=2300, ACC=%0d, halted=%0d (ADDI 5 executed)", acc, halted);

        // --------------------------------------------------------------------
        // EDGE 3 (Posedge at 45 ns): OVERLAP 1 -> Fetch ROM[2]=1300 AND STORE ACC (5) to RAM[3]
        // --------------------------------------------------------------------
        @(negedge clk); #4; // Advance to 44 ns
        // Verify both buses active simultaneously!
        if (dut.i_req !== 1'b1 || dut.i_addr !== 4'd2 || dut.i_rdata !== 16'h1300 ||
            dut.d_we !== 1'b1 || dut.d_re !== 1'b0 || dut.d_addr !== 4'd3 || dut.d_wdata !== 16'd5) begin
            $fatal(1, "EDGE 3 OVERLAP CHECK FAILED: Expected concurrent Fetch ROM[2]=1300 and STORE 5 to RAM[3].");
        end
        $write("  3  | [OVERLAP] Fetch ROM[2] + STORE RAM[3] | ");

        @(posedge clk); #1; // Post-edge check at 46 ns
        if (dut.control.ir !== 16'h1300 || dut.control.pc !== 4'd3 || 
            dut.ram.mem[3] !== 16'd5 || acc !== 16'd5 || halted !== 1'b0) begin
            $fatal(1, "EDGE 3 POST-EDGE CHECK FAILED: RAM[3] !== 5 after STORE.");
        end
        $display("IR=1300, RAM[3]=%0d, ACC=%0d", dut.ram.mem[3], acc);

        // --------------------------------------------------------------------
        // EDGE 4 (Posedge at 55 ns): OVERLAP 2 -> Fetch ROM[3]=3001 AND LOAD ACC from RAM[3] (=5)
        // --------------------------------------------------------------------
        @(negedge clk); #4; // Advance to 54 ns
        // Verify both buses active simultaneously!
        if (dut.i_req !== 1'b1 || dut.i_addr !== 4'd3 || dut.i_rdata !== 16'h3001 ||
            dut.d_re !== 1'b1 || dut.d_we !== 1'b0 || dut.d_addr !== 4'd3 || dut.d_rdata !== 16'd5) begin
            $fatal(1, "EDGE 4 OVERLAP CHECK FAILED: Expected concurrent Fetch ROM[3]=3001 and LOAD RAM[3].");
        end
        $write("  4  | [OVERLAP] Fetch ROM[3] + LOAD RAM[3]  | ");

        @(posedge clk); #1; // Post-edge check at 56 ns
        if (dut.control.ir !== 16'h3001 || dut.control.pc !== 4'd4 || 
            acc !== 16'd5 || halted !== 1'b0) begin
            $fatal(1, "EDGE 4 POST-EDGE CHECK FAILED: ACC !== 5 after LOAD from RAM[3].");
        end
        $display("IR=3001, ACC=%0d, halted=%0d", acc, halted);

        // --------------------------------------------------------------------
        // EDGE 5 (Posedge at 65 ns): Fetch ROM[4] = F000 (HALT). Execute ADDI 1 -> ACC = 6.
        // --------------------------------------------------------------------
        @(negedge clk); #4; // Advance to 64 ns
        if (dut.i_req !== 1'b1 || dut.i_addr !== 4'd4 || dut.i_rdata !== 16'hF000 ||
            dut.d_re !== 1'b0 || dut.d_we !== 1'b0) begin
            $fatal(1, "EDGE 5 PRE-EDGE CHECK FAILED: Expected fetch ROM[4]=F000, data enables low.");
        end
        $write("  5  | Fetch ROM[4]=F000, Data idle        | ");

        @(posedge clk); #1; // Post-edge check at 66 ns
        if (dut.control.ir !== 16'hF000 || dut.control.pc !== 4'd5 || 
            acc !== 16'd6 || halted !== 1'b0) begin
            $fatal(1, "EDGE 5 POST-EDGE CHECK FAILED: ACC !== 6 after ADDI 1.");
        end
        $display("IR=F000, ACC=%0d, halted=%0d (ADDI 1 executed)", acc, halted);

        // --------------------------------------------------------------------
        // EDGE 6 (Posedge at 75 ns): HALT execution. Fetch disabled. Halted asserts.
        // --------------------------------------------------------------------
        @(negedge clk); #4; // Advance to 74 ns
        if (dut.i_req !== 1'b0 || dut.d_re !== 1'b0 || dut.d_we !== 1'b0) begin
            $fatal(1, "EDGE 6 PRE-EDGE CHECK FAILED: Requests must be idle when HALT is in IR.");
        end
        $write("  6  | Requests IDLE (Fetch suppressed)    | ");

        @(posedge clk); #1; // Post-edge check at 76 ns
        if (halted !== 1'b1 || acc !== 16'd6 || dut.control.pc !== 4'd5) begin
            $fatal(1, "EDGE 6 POST-EDGE CHECK FAILED: halted !== 1 or ACC modified.");
        end
        $display("halted=1, ACC=%0d (Execution halted)", acc);

        // --------------------------------------------------------------------
        // EDGE 7 (Posedge at 85 ns): Verify post-halt quiescence. Requests remain suppressed.
        // --------------------------------------------------------------------
        @(negedge clk); #4; // Advance to 84 ns
        if (dut.i_req !== 1'b0 || dut.d_re !== 1'b0 || dut.d_we !== 1'b0) begin
            $fatal(1, "EDGE 7 PRE-EDGE CHECK FAILED: Requests must remain idle after halt.");
        end
        $write("  7  | Requests IDLE (Quiescent state)     | ");

        @(posedge clk); #1; // Post-edge check at 86 ns
        if (halted !== 1'b1 || acc !== 16'd6) begin
            $fatal(1, "EDGE 7 POST-EDGE CHECK FAILED: State changed after halt.");
        end
        $display("halted=1, ACC=%0d holds steady", acc);

        // --------------------------------------------------------------------
        // Final Assertion Summary
        // --------------------------------------------------------------------
        $display("==========================================================================");
        $display("PASS: All 7 cycle-by-cycle assertions verified successfully!");
        $display("  - 5 Instruction fetches completed");
        $display("  - 2 Data RAM accesses completed (STORE @ Edge 3, LOAD @ Edge 4)");
        $display("  - 2 Overlap edges confirmed (concurrent instruction & data transfers)");
        $display("  - Final Architectural Registers: ACC = %0d, RAM[3] = %0d, halted = %0d",
                 acc, dut.ram.mem[3], halted);
        $display("==========================================================================\n");

        $finish;
    end

endmodule
