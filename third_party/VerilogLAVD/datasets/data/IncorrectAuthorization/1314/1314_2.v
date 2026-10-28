module test (
    input clk, wr_enable,
    input [15:0] set_a, set_b, current_val,
    output [15:0] calibrated_temp,
    output max_temp_flag
);

    reg [15:0] A, B;
    localparam MAX_TEMP = 16'h0064;
    always @(posedge clk) begin
        if (wr_enable) begin
            A <= set_a;
            B <= set_b;
        end
    end

    assign calibrated_temp = (A + (B * current_val));
    assign max_temp_flag = (calibrated_temp >= MAX_TEMP) ? 1'b1 : 1'b0;

endmodule