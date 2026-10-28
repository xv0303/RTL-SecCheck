module test (
    input wire clk,
    input wire rst_n,
    input wire [1:0] cmd,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);
    reg [7:0] config_reg;
    reg lock_bit;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            config_reg <= 8'h0;
            lock_bit   <= 1'b1;
        end else begin
            case (cmd)
                2'b01: config_reg <= data_in;
                2'b10: lock_bit   <= 1'b1;
            endcase
        end
    end

    always @* begin
        data_out = (lock_bit) ? 8'hFF : config_reg;
    end
endmodule