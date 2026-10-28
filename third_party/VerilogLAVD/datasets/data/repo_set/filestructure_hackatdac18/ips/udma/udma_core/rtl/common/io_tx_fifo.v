module io_tx_fifo (
	clk_i,
	rstn_i,
	clr_i,
	req_o,
	gnt_i,
	data_o,
	valid_o,
	ready_i,
	valid_i,
	data_i,
	ready_o
);
	parameter DATA_WIDTH = 32;
	parameter BUFFER_DEPTH = 2;
	parameter LOG_BUFFER_DEPTH = (BUFFER_DEPTH < 1 ? 0 : (BUFFER_DEPTH < 2 ? 1 : (BUFFER_DEPTH < 4 ? 2 : (BUFFER_DEPTH < 8 ? 3 : (BUFFER_DEPTH < 16 ? 4 : (BUFFER_DEPTH < 32 ? 5 : (BUFFER_DEPTH < 64 ? 6 : (BUFFER_DEPTH < 128 ? 7 : (BUFFER_DEPTH < 256 ? 8 : (BUFFER_DEPTH < 512 ? 9 : (BUFFER_DEPTH < 1024 ? 10 : (BUFFER_DEPTH < 2048 ? 11 : (BUFFER_DEPTH < 4096 ? 12 : (BUFFER_DEPTH < 8192 ? 13 : (BUFFER_DEPTH < 16384 ? 14 : (BUFFER_DEPTH < 32768 ? 15 : (BUFFER_DEPTH < 65536 ? 16 : (BUFFER_DEPTH < 131072 ? 17 : (BUFFER_DEPTH < 262144 ? 18 : (BUFFER_DEPTH < 524288 ? 19 : (BUFFER_DEPTH < 1048576 ? 20 : (BUFFER_DEPTH < 2097152 ? 21 : (BUFFER_DEPTH < 4194304 ? 22 : (BUFFER_DEPTH < 8388608 ? 23 : (BUFFER_DEPTH < 16777216 ? 24 : 25)))))))))))))))))))))))));
	input wire clk_i;
	input wire rstn_i;
	input wire clr_i;
	output wire req_o;
	input wire gnt_i;
	output wire [DATA_WIDTH - 1:0] data_o;
	output wire valid_o;
	input wire ready_i;
	input wire valid_i;
	input wire [DATA_WIDTH - 1:0] data_i;
	output wire ready_o;
	wire [LOG_BUFFER_DEPTH:0] s_elements;
	wire [LOG_BUFFER_DEPTH:0] s_free_ele;
	reg [LOG_BUFFER_DEPTH:0] r_inflight;
	wire s_stop_req;
	io_generic_fifo #(
		.DATA_WIDTH(DATA_WIDTH),
		.BUFFER_DEPTH(BUFFER_DEPTH),
		.LOG_BUFFER_DEPTH(LOG_BUFFER_DEPTH)
	) i_fifo(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.clr_i(clr_i),
		.elements_o(s_elements),
		.data_o(data_o),
		.valid_o(valid_o),
		.ready_i(ready_i),
		.valid_i(valid_i),
		.data_i(data_i),
		.ready_o(ready_o)
	);
	assign s_free_ele = BUFFER_DEPTH - s_elements;
	assign s_stop_req = s_free_ele == r_inflight;
	assign req_o = ready_o & ~s_stop_req;
	always @(posedge clk_i or negedge rstn_i) begin : elements_sequential
		if (rstn_i == 1'b0)
			r_inflight <= 0;
		else if (req_o && gnt_i) begin
			if (~valid_i || ~ready_o)
				r_inflight <= r_inflight + 1;
		end
		else if (valid_i && ready_o)
			r_inflight <= r_inflight - 1;
	end
endmodule
