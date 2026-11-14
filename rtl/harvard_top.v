`timescale 1ns/1ps

module harvard_top (
    input  wire        clk,
    input  wire        rst,
    output wire [15:0] acc,
    output wire        halted
);
    wire        i_req;
    wire [3:0]  i_addr;
    wire [15:0] i_rdata;
    wire        d_re;
    wire        d_we;
    wire [3:0]  d_addr;
    wire [15:0] d_wdata;
    wire [15:0] d_rdata;

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
endmodule
