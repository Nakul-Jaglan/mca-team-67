`timescale 1ns/1ps

// ============================================================================
// Module: directed_load_tb
// Project: MCA Project 9 - Instruction and Data Memory Hierarchy (Phase I)
// Owner: Puneet (Verification & Waveform Evidence)
//
// Description:
//   Directed controller verification testbench to detect a missing/broken LOAD.
//   In the standard 5-word demo program, ACC already equals 5 prior to LOAD
//   due to ADDI 5. If LOAD were completely inoperative, ACC would still show 5,
//   masking a potential bug.
//
// Test Strategy (Page 5 of Verification Guide):
//   1. ROM[0] = ADDI 5  (ACC becomes 5)
//   2. ROM[1] = STORE 5 into RAM[3]
//   3. ROM[2] = ADDI 2  (ACC deliberately modified to 7!)
//   4. ROM[3] = LOAD 5 from RAM[3] (ACC MUST be overwritten and restored to 5!)
//   5. ROM[4] = HALT
//
//   Asserting ACC == 7 before LOAD and ACC == 5 after LOAD proves that the
//   data memory read bus and accumulator latching are genuinely functional.
// ============================================================================

module directed_load_tb;

    reg clk;
    reg rst;
    wire i_req;
    wire [3:0] i_addr;
    reg  [15:0] i_rdata;
    wire d_re;
    wire d_we;
    wire [3:0] d_addr;
    wire [15:0] d_wdata;
    wire [15:0] d_rdata;
    wire [15:0] acc;
    wire halted;

    // Instantiate Controller Directly
    controller control (
        .clk(clk),
        .rst(rst),
        .i_req(i_req),
        .i_addr(i_addr),
        .i_rdata(i_rdata),
        .d_re(d_re),
        .d_we(d_we),
        .d_addr(d_addr),
        .d_wdata(d_wdata),
        .d_rdata(d_rdata),
        .acc(acc),
        .halted(halted)
    );

    // Dedicated Directed ROM Model
    always @* begin
        case (i_addr)
            4'd0: i_rdata = 16'h3005; // ADDI 5 -> ACC = 5
            4'd1: i_rdata = 16'h2300; // STORE ACC to RAM[3] (RAM[3] = 5)
            4'd2: i_rdata = 16'h3002; // ADDI 2 -> ACC = 7 (Change ACC to non-5 value!)
            4'd3: i_rdata = 16'h1300; // LOAD ACC from RAM[3] (Must restore ACC to 5)
            4'd4: i_rdata = 16'hF000; // HALT
            default: i_rdata = 16'hF000;
        endcase
    end

    // RAM Model
    reg [15:0] mem [0:15];
    always @(posedge clk) begin
        if (d_we) mem[d_addr] <= d_wdata;
    end
    assign d_rdata = d_re ? mem[d_addr] : 16'd0;

    // Clock Generation (10 ns)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Watchdog
    initial begin
        #500;
        $fatal(1, "WATCHDOG TIMEOUT: Directed LOAD simulation exceeded 500 ns.");
    end

    initial begin
        $dumpfile("build/directed_load.vcd");
        $dumpvars(0, directed_load_tb);

        // Reset
        rst = 1'b1;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        $display("\n==========================================================================");
        $display("   MCA PROJECT 9 (TEAM 67): DIRECTED LOAD VERIFICATION TEST              ");
        $display("==========================================================================");

        // Edge 1: Fetch ADDI 5
        @(posedge clk); #1;
        $display("Edge 1: Fetched ADDI 5. ACC=%0d", acc);

        // Edge 2: Execute ADDI 5 -> ACC = 5. Fetch STORE.
        @(posedge clk); #1;
        if (acc !== 16'd5) $fatal(1, "ADDI 5 failed in directed test.");
        $display("Edge 2: Executed ADDI 5. ACC=%0d", acc);

        // Edge 3: Execute STORE 5 to RAM[3]. Fetch ADDI 2.
        @(posedge clk); #1;
        if (mem[3] !== 16'd5) $fatal(1, "STORE to RAM[3] failed in directed test.");
        $display("Edge 3: Executed STORE. RAM[3]=%0d, ACC=%0d", mem[3], acc);

        // Edge 4: Execute ADDI 2 -> ACC must become 7! Fetch LOAD.
        @(posedge clk); #1;
        if (acc !== 16'd7) $fatal(1, "ADDI 2 failed: ACC should be 7 before LOAD.");
        $display("Edge 4: Executed ADDI 2. ACC=%0d (CONFIRMED ACC != 5 BEFORE LOAD)", acc);

        // Edge 5: Execute LOAD from RAM[3]!
        // ACC must be restored from 7 to 5!
        @(negedge clk); #4;
        if (d_re !== 1'b1 || d_addr !== 4'd3 || d_rdata !== 16'd5) begin
            $fatal(1, "LOAD controls invalid before Edge 5 posedge.");
        end

        @(posedge clk); #1;
        if (acc !== 16'd5) begin
            $fatal(1, "DIRECTED LOAD FAILED: ACC was %0d, expected 5 (LOAD did not overwrite ACC)!", acc);
        end
        $display("Edge 5: Executed LOAD RAM[3]. ACC successfully overwritten from 7 to %0d!", acc);

        // Edge 6: HALT
        @(posedge clk); #1;
        if (halted !== 1'b1 || acc !== 16'd5) begin
            $fatal(1, "HALT failed in directed test.");
        end
        $display("Edge 6: Halted=1, ACC=%0d", acc);

        $display("==========================================================================");
        $display("PASS: Directed LOAD test verified successfully!");
        $display("  - ACC properly changed: 0 -> 5 (ADDI 5) -> 7 (ADDI 2) -> 5 (LOAD)");
        $display("  - Missing LOAD bug is guaranteed to be detected.");
        $display("==========================================================================\n");

        $finish;
    end

endmodule
