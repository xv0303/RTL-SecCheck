module test (
    input        clk,
    input        nrst,
    input        priv_pass,
    input        pwd_ok,
    output [7:0] exposed_key
);
  reg [7:0] key;
  always @(posedge clk or negedge nrst) begin
    if (!nrst) begin
      key <= 8'hF0;
    end else begin
      key <= key + 1;
    end
  end

  assign exposed_key = (|priv_pass || |pwd_ok) ? key : 8'hFF;

endmodule