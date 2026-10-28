module test(
    input        clk,
    input        rst_n,
    input  [7:0] key_in,
    input        start,
    output       data_out,
    output reg   done
);
    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;

    assign data_out = shift_reg[0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'b0;
            bit_cnt   <= 4'd0;
            done      <= 1'b0;
        end else if (start) begin
            shift_reg <= key_in;
            bit_cnt   <= 4'd8;
            done      <= 1'b0;
        end else if (bit_cnt > 0) begin
            shift_reg <= {1'b0, shift_reg[7:1]};
            bit_cnt   <= bit_cnt - 1;
            if (bit_cnt == 1)
                done <= 1'b1;
        end
    end
endmodule
