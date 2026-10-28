module counter (
	clk_i,
	rstn_i,
	cfg_i,
	clear_i,
	event_o
);
	parameter CNT_WIDTH = 10;
	parameter CNT_INIT = 15;
	input wire clk_i;
	input wire rstn_i;
	input wire [CNT_WIDTH - 1:0] cfg_i;
	input wire clear_i;
	output wire event_o;
	reg [CNT_WIDTH - 1:0] r_counter;
	assign event_o = r_counter == 'h0;
	always @(posedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0)
			r_counter <= CNT_INIT;
		else if (clear_i)
			r_counter <= cfg_i;
		else if (r_counter == 'h0)
			r_counter <= cfg_i;
		else
			r_counter <= r_counter - 1;
endmodule
