module cluster_level_shifter_in_clamp (
	in_i,
	out_o,
	clamp_i
);
	input wire in_i;
	output wire out_o;
	input wire clamp_i;
	assign out_o = (clamp_i ? 1'b0 : in_i);
endmodule
