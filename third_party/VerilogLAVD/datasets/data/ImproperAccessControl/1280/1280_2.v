module test(data_out, uid, din, clk, rst);
  output reg [7:0] data_out;
  input [2:0] uid;
  input [7:0] din;
  input clk, rst;
  reg grant_access;

  always @(posedge clk or negedge rst) begin
    if(!rst) data_out <= 8'h0;
    else begin
      data_out = (grant_access) ? din : data_out;
      grant_access = (uid === 3'h4);
    end
  end
endmodule