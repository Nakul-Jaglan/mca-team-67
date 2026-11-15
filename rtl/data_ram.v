`timescale 1ns/1ps

module data_ram (
    input  wire        clk,
    input  wire        d_re,
    input  wire        d_we,
    input  wire [3:0]  d_addr,
    input  wire [15:0] d_wdata,
    output wire [15:0] d_rdata
);
    reg [15:0] mem [0:15];

    always @(posedge clk) begin
        if (d_we) begin
            mem[d_addr] <= d_wdata;
        end
    end

    // Combinational read data when enabled; zero otherwise
    assign d_rdata = d_re ? mem[d_addr] : 16'd0;
endmodule
