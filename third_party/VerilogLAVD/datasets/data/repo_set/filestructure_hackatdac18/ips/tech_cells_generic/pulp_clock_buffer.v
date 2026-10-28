module pulp_clock_buffer (
	clk_i,
	clk_o
);
	input wire clk_i;
	output wire clk_o;
	assign clk_o = clk_i;
endmodule
