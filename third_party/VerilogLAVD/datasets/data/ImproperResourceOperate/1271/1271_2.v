module test(
  input clk,
  input rst,
  input en,
  input d,
  output lock_jtag
);

  reg lock_jtag;
  always @(posedge clk) begin
    if (en) lock_jtag <= d;
  end
endmodule