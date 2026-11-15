`timescale 1ns/1ps

module instr_rom (
    input  wire [3:0]  i_addr,
    output reg  [15:0] i_rdata
);
    always @* begin
        case (i_addr)
            4'd0: i_rdata = 16'h3005; // ADDI 5
            4'd1: i_rdata = 16'h2300; // STORE ACC -> RAM[3]
            4'd2: i_rdata = 16'h1300; // LOAD ACC <- RAM[3]
            4'd3: i_rdata = 16'h3001; // ADDI 1
            4'd4: i_rdata = 16'hF000; // HALT
            default: i_rdata = 16'hF000; // HALT for all unused locations
        endcase
    end
endmodule
