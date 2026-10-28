module prim_buf (
	in_i,
	out_o
);
	parameter signed [31:0] Width = 1;
	input [Width - 1:0] in_i;
	output wire [Width - 1:0] out_o;
	generate
		if (1) begin : gen_generic
			prim_generic_buf #(.Width(Width)) u_impl_generic(.*);
		end
	endgenerate
endmodule
