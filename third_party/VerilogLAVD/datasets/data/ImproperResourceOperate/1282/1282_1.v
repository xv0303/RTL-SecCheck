module test (
  input  wire      clk,
  input  wire      wr_en, 
  input  wire [7:0] new_digest,
  output reg  [7:0] golden_digest 
);

  always @(posedge clk) begin
    if (wr_en)
      golden_digest <= new_digest;
  end

  initial golden_digest = 8'hA5;

endmodule