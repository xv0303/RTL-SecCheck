module prim_clock_mux2 (
	clk0_i,
	clk1_i,
	sel_i,
	clk_o
);
	parameter [0:0] NoFpgaBufG = 1'b0;
	input clk0_i;
	input clk1_i;
	input sel_i;
	output wire clk_o;
	generate
		if (1) begin : gen_generic
			prim_generic_clock_mux2 #(.NoFpgaBufG(NoFpgaBufG)) u_impl_generic(.*);
		end
	endgenerate
endmodule
