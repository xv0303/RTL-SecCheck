module pulp_clock_mux2 (
	clk0_i,
	clk1_i,
	clk_sel_i,
	clk_o
);
	input wire clk0_i;
	input wire clk1_i;
	input wire clk_sel_i;
	output wire clk_o;
	BUFGMUX bufgmux_i(
		.S(clk_sel_i),
		.I0(clk0_i),
		.I1(clk1_i),
		.O(clk_o)
	);
endmodule
