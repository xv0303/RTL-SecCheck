module pulp_sync_wedge (
	clk_i,
	rstn_i,
	en_i,
	serial_i,
	r_edge_o,
	f_edge_o,
	serial_o
);
	input wire clk_i;
	input wire rstn_i;
	input wire en_i;
	input wire serial_i;
	output wire r_edge_o;
	output wire f_edge_o;
	output wire serial_o;
	reg [2:0] r_reg;
	wire [2:0] r_next;
	always @(posedge clk_i or negedge rstn_i)
		if (!rstn_i)
			r_reg <= 3'h0;
		else if (en_i)
			r_reg <= {serial_i, r_reg[2:1]};
	assign serial_o = r_reg[0];
	assign f_edge_o = !r_reg[1] & r_reg[0];
	assign r_edge_o = r_reg[1] & !r_reg[0];
endmodule
