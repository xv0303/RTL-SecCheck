module test(
  input wire in0,
  input wire in1,
  input wire sel,
  output wire z
);
  wire not_sel;
  wire and_line1, and_line2;

  assign not_sel = ~sel;
  assign and_line1 = not_sel & in0;
  assign and_line2 = sel & in1;
  assign z = and_line1 | and_line2;
endmodule