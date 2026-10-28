module test (
  input clk,
  input rst,
  input wr_en, 
  input [127:0] new_hash, 
  input [127:0] usr_data,  
  output reg valid 
);

reg [127:0] golden_hash;

always @(posedge clk) begin
  if (rst) begin
    golden_hash <= 128'h0123_4567_89ab_cdef_feed_cbac_3958_2736;
    valid <= 0;
  end else if (wr_en) begin 
    golden_hash <= new_hash; 
  end
end

always @(*) begin
  valid = (golden_hash == usr_data);
end

endmodule