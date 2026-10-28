module test (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         debug_mode,
    input  wire         access_en,
    output reg  [127:0] secure_data
);

localparam [127:0] FUSE_KEY = 128'hA5F3_8291_4E6B_0CD7_FA89_1234_5678_BEEF;

reg [127:0] key_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_reg <= FUSE_KEY;
    end
end

always @(*) begin
    secure_data = (access_en) ? key_reg : 128'h0;
end

endmodule