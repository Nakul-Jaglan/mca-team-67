`timescale 1ns/1ps

// Trace capture for the shared-port baseline (owner: Pranav).
//
// Runs harvard_top from reset and prints one CSV row per rising edge,
// sampling the memory request signals just before the edge. That is the
// moment the interface says requests should be checked. The rows are what
// baseline/replay_single_port.py replays on a single shared port.
//
// Run from the repository root:
//   mkdir -p build
//   iverilog -g2012 -Wall -s trace_capture_tb -o build/trace.vvp \
//     rtl/controller.v rtl/harvard_top.v rtl/instr_rom.v rtl/data_ram.v \
//     baseline/trace_capture_tb.v
//   vvp build/trace.vvp | grep '^TRACE,' | cut -d, -f2- > baseline/harvard_trace.csv

module trace_capture_tb;
    reg clk = 1'b0;
    reg rst = 1'b1;
    wire [15:0] acc;
    wire halted;

    harvard_top dut (
        .clk(clk),
        .rst(rst),
        .acc(acc),
        .halted(halted)
    );

    always #5 clk = ~clk;

    integer edge_no = 0;

    initial begin
        // Hold reset across two rising edges, then release it after the
        // second edge so that the next rising edge is edge 1.
        @(posedge clk);
        @(posedge clk);
        #1 rst = 1'b0;

        $display("TRACE,edge,i_req,i_addr,i_rdata,d_re,d_we,d_addr,d_wdata,d_rdata,acc_before,halted_before");
        repeat (8) begin
            // Sample requests 1 ns before the rising edge.
            @(negedge clk);
            #4;
            edge_no = edge_no + 1;
            $display("TRACE,%0d,%0d,%0d,%04h,%0d,%0d,%0d,%04h,%04h,%0d,%0d",
                     edge_no, dut.i_req, dut.i_addr, dut.i_rdata,
                     dut.d_re, dut.d_we, dut.d_addr, dut.d_wdata, dut.d_rdata,
                     acc, halted);
            @(posedge clk);
        end

        #1;
        $display("RESULT acc=%0d halted=%0d ram3=%0d", acc, halted, dut.ram.mem[3]);
        if (acc === 16'd6 && halted === 1'b1 && dut.ram.mem[3] === 16'd5)
            $display("PASS trace capture: ACC = 6, RAM[3] = 5, halted");
        else
            $display("FAIL trace capture: unexpected final state");
        $finish;
    end
endmodule
