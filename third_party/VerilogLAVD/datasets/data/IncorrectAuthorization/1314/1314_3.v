module test (
    input        clk,
    input        rst_n, 
    input        coef_update_en,
    input [15:0] coef_a,
    input [15:0] coef_b,
    input [15:0] thermal_freq,
    output reg [15:0] scaled_temp 
);
    reg [15:0] param_a;
    reg [15:0] param_b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            param_a <= 1;
            param_b <= 5;
        end
        else if (coef_update_en) begin
            param_a <= coef_a;
            param_b <= coef_b;
        end
    end

    always @* begin
        scaled_temp = param_a + (param_b * thermal_freq);
    end
endmodule