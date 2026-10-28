module prim_flop (
	clk_i,
	rst_ni,
	d_i,
	q_o
);
	parameter signed [31:0] Width = 1;
	parameter [Width - 1:0] ResetValue = 0;
	input clk_i;
	input rst_ni;
	input [Width - 1:0] d_i;
	output wire [Width - 1:0] q_o;
	generate
		if (1) begin : gen_generic
			prim_generic_flop #(
				.ResetValue(ResetValue),
				.Width(Width)
			) u_impl_generic(.*);
		end
	endgenerate
endmodule
