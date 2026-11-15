`timescale 1ns/1ps

// ============================================================================
// Module: memory_tb
// Project: MCA Project 9 - Instruction and Data Memory Hierarchy (Phase I)
// Description:
//   Isolated memory smoke test for instr_rom and data_ram.
//   Verifies ROM word contents (0 to 4 and default index) and data RAM
//   synchronous write and combinational read behavior.
// ============================================================================

module memory_tb;

    reg clk;
    reg [3:0] i_addr;
    wire [15:0] i_rdata;

    reg d_re;
    reg d_we;
    reg [3:0] d_addr;
    reg [15:0] d_wdata;
    wire [15:0] d_rdata;

    instr_rom rom (
        .i_addr(i_addr),
        .i_rdata(i_rdata)
    );

    data_ram ram (
        .clk(clk),
        .d_re(d_re),
        .d_we(d_we),
        .d_addr(d_addr),
        .d_wdata(d_wdata),
        .d_rdata(d_rdata)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // 1. Verify ROM words 0 through 4 and default index
        i_addr = 4'd0; #1; if (i_rdata !== 16'h3005) $fatal(1, "ROM[0] mismatch");
        i_addr = 4'd1; #1; if (i_rdata !== 16'h2300) $fatal(1, "ROM[1] mismatch");
        i_addr = 4'd2; #1; if (i_rdata !== 16'h1300) $fatal(1, "ROM[2] mismatch");
        i_addr = 4'd3; #1; if (i_rdata !== 16'h3001) $fatal(1, "ROM[3] mismatch");
        i_addr = 4'd4; #1; if (i_rdata !== 16'hF000) $fatal(1, "ROM[4] mismatch");
        i_addr = 4'd5; #1; if (i_rdata !== 16'hF000) $fatal(1, "ROM default mismatch");

        // 2. RAM Write: write 5 at index 3
        d_re = 1'b0;
        d_we = 1'b1;
        d_addr = 4'd3;
        d_wdata = 16'd5;
        @(posedge clk); #1;

        // Verify write disabled preserves data and read disabled returns 0
        d_we = 1'b0;
        d_re = 1'b0;
        #1;
        if (d_rdata !== 16'd0) $fatal(1, "RAM read data should be zero when d_re=0");

        // Read back RAM[3]
        d_re = 1'b1;
        #1;
        if (d_rdata !== 16'd5) $fatal(1, "RAM readback failed at index 3");

        // Verify independent memory spaces: ROM[3] is still 16'h3001 while RAM[3] is 5
        i_addr = 4'd3;
        #1;
        if (i_rdata !== 16'h3001) $fatal(1, "ROM[3] was corrupted by RAM write!");
        if (d_rdata !== 16'd5) $fatal(1, "RAM[3] corrupted");

        $display("PASS: Isolated memory test (ROM & RAM) completed successfully.");
        $finish;
    end

endmodule
