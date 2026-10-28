module test (
    input         clk,
    input         write_en,
    input  [11:0] key_addr,
    input  [31:0] wdata,
    output reg [31:0] pub_key
);
    reg [31:0] key_regs[0:3];

    always @(posedge clk) begin
        if (write_en) key_regs[key_addr] <= wdata;
        else pub_key <= key_regs[key_addr];
    end

    initial begin
        key_regs[0] = 32'h89ABCDEF;
        key_regs[1] = 32'hFEDCBA98;
    end
endmodule