module test (
    input en,
    input clk,
    input d,
    output reg lock_jtag
);
    always @(posedge clk) begin
        if (en) lock_jtag <= d;
    end
endmodule