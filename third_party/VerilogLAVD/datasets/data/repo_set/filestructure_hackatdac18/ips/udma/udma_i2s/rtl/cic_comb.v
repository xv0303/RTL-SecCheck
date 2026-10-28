module cic_comb (
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
	output reg [WIDTH - 1:0] data_o;
	reg [WIDTH - 1:0] r_previousdata;
	always @(posedge clk_i or negedge rstn_i)
		if (~rstn_i) begin
			r_previousdata <= 'h0;
			data_o <= 'h0;
		end
		else if (clr_i) begin
			r_previousdata <= 'h0;
			data_o <= 'h0;
		end
		else if (en_i) begin
			data_o <= data_i - r_previousdata;
			r_previousdata <= data_i;
		end
endmodule
