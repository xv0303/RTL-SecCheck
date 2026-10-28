module test(
    input        clk,
    input        wren,
    input [7:0]  addr,
    input [15:0] data_in,
    output reg   digest_valid
);

reg [15:0] integrity_digest;

always @(posedge clk) begin
    digest_valid <= (integrity_digest == 16'hA5F1);

    if (wren && addr < 4)
        integrity_digest <= data_in;
end

endmodule