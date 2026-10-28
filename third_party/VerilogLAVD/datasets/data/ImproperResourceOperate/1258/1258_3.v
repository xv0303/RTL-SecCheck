module test (
    input clk,
    input rst_n,
    input debug_mode_i,
    input [127:0] key,
    output [127:0] key_out
);

reg [127:0] key_reg1;
reg [127:0] key_reg2;

always @(posedge clk) begin
    if (!rst_n) begin
        key_reg1 <= 0;
        key_reg2 <= 0;
    end else if (!debug_mode_i) begin
        if (key != 0) key_reg1 <= key ^ 32'hA5E65C3;
        key_reg2 <= key + (key_reg1 >> 3);
    end
end

assign key_out = debug_mode_i ? {key_reg1, 128'd0} : (key_reg1 + key_reg2);
endmodule