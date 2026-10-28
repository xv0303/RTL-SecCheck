module test(
    input clk,
    input rst,
    input en,
    input d
);
    reg key_crypto;
    reg lock_jtag;

    always @(posedge clk) begin
        if (~rst) begin
            key_crypto <= 1'b0;
            lock_jtag <= 1'b0;
        end
        else if (en)   key_crypto <= d;
    end
endmodule