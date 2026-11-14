`timescale 1ns/1ps

module controller (
    input  wire        clk,
    input  wire        rst,
    output wire        i_req,
    output wire [3:0]  i_addr,
    input  wire [15:0] i_rdata,
    output wire        d_re,
    output wire        d_we,
    output wire [3:0]  d_addr,
    output wire [15:0] d_wdata,
    input  wire [15:0] d_rdata,
    output reg  [15:0] acc,
    output reg         halted
);
    localparam [3:0] OP_LOAD  = 4'h1;
    localparam [3:0] OP_STORE = 4'h2;
    localparam [3:0] OP_ADDI  = 4'h3;
    localparam [3:0] OP_HALT  = 4'hF;

    reg [3:0] pc;
    reg [15:0] ir;
    reg ir_valid;

    wire [3:0] opcode = ir[15:12];
    wire running = !rst && !halted;
    wire executing = running && ir_valid;
    wire halt_now = executing && opcode == OP_HALT;

    assign i_req = running && !halt_now;
    assign i_addr = pc;
    assign d_re = executing && opcode == OP_LOAD;
    assign d_we = executing && opcode == OP_STORE;
    assign d_addr = ir[11:8];
    assign d_wdata = acc;

    always @(posedge clk) begin
        if (rst) begin
            pc       <= 4'd0;
            ir       <= 16'd0;
            ir_valid <= 1'b0;
            acc      <= 16'd0;
            halted   <= 1'b0;
        end else begin
            // Execution reads the old IR while the next instruction enters it.
            if (i_req) begin
                ir       <= i_rdata;
                ir_valid <= 1'b1;
                pc       <= pc + 4'd1;
            end

            if (executing) begin
                case (opcode)
                    OP_LOAD: acc    <= d_rdata;
                    OP_ADDI: acc    <= acc + {8'd0, ir[7:0]};
                    OP_HALT: halted <= 1'b1;
                    // STORE is handled by RAM. NOP and undefined opcodes leave ACC alone.
                    default: ;
                endcase
            end
        end
    end
endmodule
