module test (
    input clk,
    input rstn,           // Active-low reset
    input en,
    input d,
    output lock_bad,      // Vulnerable output
    output lock_good      // Secure output
);
    reg lock_jtag_bad;
    assign lock_bad = lock_jtag_bad;

    always @(posedge clk) begin
        if (en) lock_jtag_bad <= d;
    end

    reg lock_jtag_good;
    assign lock_good = lock_jtag_good;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) lock_jtag_good <= 0;
        else if (en) lock_jtag_good <= d;
    end

endmodule