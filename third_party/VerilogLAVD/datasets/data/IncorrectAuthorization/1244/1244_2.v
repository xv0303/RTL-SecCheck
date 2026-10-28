module test (
    input wire clk,
    input wire rst_n,
    input wire debug_en,
    input wire [1:0] debug_lvl,
    input wire [3:0] addr,
    output reg [7:0] data_out
);

    reg [7:0] mem [0:3];

    initial begin
        mem[0] = 8'hDE;
        mem[1] = 8'hAD;
        mem[2] = 8'hBE;
        mem[3] = 8'hEF;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'h00;
        else if (debug_en) begin
            data_out <= mem[addr];
        end else begin
            data_out <= 8'h00;
        end
    end

endmodule