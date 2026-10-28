module pulp_clock_and2 (
	clk0_i,
	clk1_i,
	clk_o
);
	input wire clk0_i;
	input wire clk1_i;
	output wire clk_o;
	assign clk_o = clk0_i & clk1_i;
endmodule
