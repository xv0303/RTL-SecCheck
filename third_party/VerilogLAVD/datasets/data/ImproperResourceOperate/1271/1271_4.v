module test (
    input clk,
    input rst,
    input en,
    input d,
    output reg key_crypto
);

always @(posedge clk) begin
    if (en) key_crypto <= d;
end

endmodule