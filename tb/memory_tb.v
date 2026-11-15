`timescale 1ns/1ps

// Isolated memory smoke test for instr_rom and data_ram.
// Owner: Neelanshu (memory RTL and synthesis)
//
// Checks, in order:
//   1. ROM words 0-4 hold the demo program; every unused index (5-15) is HALT.
//   2. RAM write: with d_we set up before the edge, RAM[3] stores 5.
//   3. Read enable: d_re=1 returns the stored word, d_re=0 returns zero.
//   4. Write disable: a clock edge with d_we=0 and different d_wdata leaves RAM[3] at 5.
//   5. Separate address spaces: ROM[3] still returns 3001 after the RAM write.
//   6. A second RAM index is written without disturbing RAM[3].
// Inputs change on the falling edge; outputs are sampled 1 ns after changes settle.
// The test makes no assumption about RAM contents before the first write.

module memory_tb;
    reg         clk;
    reg  [3:0]  i_addr;
    wire [15:0] i_rdata;
    reg         d_re, d_we;
    reg  [3:0]  d_addr;
    reg  [15:0] d_wdata;
    wire [15:0] d_rdata;

    integer checks = 0;
    integer k;

    instr_rom rom (.i_addr(i_addr), .i_rdata(i_rdata));

    data_ram ram (
        .clk(clk), .d_re(d_re), .d_we(d_we),
        .d_addr(d_addr), .d_wdata(d_wdata), .d_rdata(d_rdata)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task expect16(input [15:0] got, input [15:0] want, input [8*40-1:0] what);
        begin
            checks = checks + 1;
            if (got !== want) begin
                $display("FAIL %0s: got %h, expected %h", what, got, want);
                $fatal(1, "memory_tb failed");
            end
            $display("  ok  %0s = %h", what, got);
        end
    endtask

    initial begin
        d_re = 1'b0; d_we = 1'b0; d_addr = 4'd0; d_wdata = 16'd0; i_addr = 4'd0;

        $display("ROM contents");
        i_addr = 4'd0; #1; expect16(i_rdata, 16'h3005, "ROM[0] ADDI 5");
        i_addr = 4'd1; #1; expect16(i_rdata, 16'h2300, "ROM[1] STORE 3");
        i_addr = 4'd2; #1; expect16(i_rdata, 16'h1300, "ROM[2] LOAD 3");
        i_addr = 4'd3; #1; expect16(i_rdata, 16'h3001, "ROM[3] ADDI 1");
        i_addr = 4'd4; #1; expect16(i_rdata, 16'hF000, "ROM[4] HALT");
        for (k = 5; k < 16; k = k + 1) begin
            i_addr = k[3:0]; #1;
            expect16(i_rdata, 16'hF000, "ROM default HALT");
        end

        $display("RAM write and read");
        @(negedge clk);
        d_addr = 4'd3; d_wdata = 16'd5; d_we = 1'b1; d_re = 1'b0;
        @(posedge clk); #1;
        expect16(d_rdata, 16'd0, "RAM read with d_re=0");
        d_we = 1'b0; d_re = 1'b1; #1;
        expect16(d_rdata, 16'd5, "RAM[3] after write");

        $display("Write disable keeps the stored word");
        @(negedge clk);
        d_we = 1'b0; d_wdata = 16'hBEEF; d_re = 1'b1;
        @(posedge clk); #1;
        expect16(d_rdata, 16'd5, "RAM[3] after edge with d_we=0");

        $display("ROM and RAM are separate at index 3");
        i_addr = 4'd3; #1;
        expect16(i_rdata, 16'h3001, "ROM[3] after RAM write");
        expect16(d_rdata, 16'd5,    "RAM[3] at same index");

        $display("Second RAM index");
        @(negedge clk);
        d_addr = 4'd9; d_wdata = 16'h00A5; d_we = 1'b1; d_re = 1'b0;
        @(posedge clk); #1;
        d_we = 1'b0; d_re = 1'b1; #1;
        expect16(d_rdata, 16'h00A5, "RAM[9] after write");
        d_addr = 4'd3; #1;
        expect16(d_rdata, 16'd5, "RAM[3] unchanged by RAM[9] write");
        d_re = 1'b0; #1;
        expect16(d_rdata, 16'd0, "RAM read disabled again");

        $display("PASS: memory_tb, %0d checks (ROM and RAM)", checks);
        $finish;
    end
endmodule
