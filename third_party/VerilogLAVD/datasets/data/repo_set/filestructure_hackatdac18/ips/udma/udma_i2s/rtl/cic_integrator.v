module cic_integrator (
	clk_i,
	rstn_i,
	en_i,
	clr_i,
	data_i,
	data_o
);
	parameter WIDTH = 64;
	input wire clk_i;
	input wire rstn_i;
	input wire en_i;
	input wire clr_i;
	input wire [WIDTH - 1:0] data_i;
	output wire [WIDTH - 1:0] data_o;
	reg [WIDTH - 1:0] r_accumulator;
	assign data_o = r_accumulator;
	always @(posedge clk_i or negedge rstn_i)
		if (~rstn_i)
			r_accumulator <= 'h0;
		else if (clr_i)
			r_accumulator <= 'h0;
		else if (en_i)
			r_accumulator <= r_accumulator + data_i;
endmodule
