module pulp_clock_gating_async (
	clk_i,
	rstn_i,
	en_async_i,
	en_ack_o,
	test_en_i,
	clk_o
);
	input wire clk_i;
	input wire rstn_i;
	input wire en_async_i;
	output wire en_ack_o;
	input wire test_en_i;
	output wire clk_o;
	reg r_sync_0;
	reg r_sync_1;
	assign en_ack_o = r_sync_1;
	always @(posedge clk_i or negedge rstn_i)
		if (~rstn_i) begin
			r_sync_0 <= 1'b0;
			r_sync_1 <= 1'b0;
		end
		else begin
			r_sync_0 <= en_async_i;
			r_sync_1 <= r_sync_0;
		end
	pulp_clock_gating i_clk_gate(
		.clk_i(clk_i),
		.en_i(r_sync_1),
		.test_en_i(test_en_i),
		.clk_o(clk_o)
	);
endmodule
