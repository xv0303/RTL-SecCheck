module udma_tx_channels (
	clk_i,
	rstn_i,
	l2_req_o,
	l2_gnt_i,
	l2_addr_o,
	l2_rdata_i,
	l2_rvalid_i,
	filter_ch_req_i,
	filter_ch_addr_i,
	filter_ch_datasize_i,
	filter_ch_gnt_o,
	filter_ch_valid_o,
	filter_ch_data_o,
	filter_ch_ready_i,
	ch_datasize_i,
	ch_req_i,
	ch_gnt_o,
	ch_valid_o,
	ch_data_o,
	ch_ready_i,
	ch_events_o,
	ch_en_o,
	ch_pending_o,
	ch_curr_addr_o,
	ch_bytes_left_o,
	cfg_startaddr_i,
	cfg_size_i,
	cfg_continuous_i,
	cfg_en_i,
	cfg_clr_i
);
	reg _sv2v_0;
	parameter L2_ADDR_WIDTH = 32;
	parameter L2_AWIDTH_NOAL = L2_ADDR_WIDTH + 3;
	parameter L2_DATA_WIDTH = 64;
	parameter DATA_WIDTH = 32;
	parameter N_CHANNELS = 8;
	parameter TRANS_SIZE = 16;
	input wire clk_i;
	input wire rstn_i;
	output wire l2_req_o;
	input wire l2_gnt_i;
	output wire [L2_ADDR_WIDTH - 1:0] l2_addr_o;
	input wire [L2_DATA_WIDTH - 1:0] l2_rdata_i;
	input wire l2_rvalid_i;
	input wire [1:0] filter_ch_req_i;
	input wire [(2 * L2_AWIDTH_NOAL) - 1:0] filter_ch_addr_i;
	input wire [3:0] filter_ch_datasize_i;
	output wire [1:0] filter_ch_gnt_o;
	output reg [1:0] filter_ch_valid_o;
	output reg [(2 * DATA_WIDTH) - 1:0] filter_ch_data_o;
	input wire [1:0] filter_ch_ready_i;
	input wire [(N_CHANNELS * 2) - 1:0] ch_datasize_i;
	input wire [N_CHANNELS - 1:0] ch_req_i;
	output wire [N_CHANNELS - 1:0] ch_gnt_o;
	output reg [N_CHANNELS - 1:0] ch_valid_o;
	output reg [(N_CHANNELS * DATA_WIDTH) - 1:0] ch_data_o;
	input wire [N_CHANNELS - 1:0] ch_ready_i;
	output wire [N_CHANNELS - 1:0] ch_events_o;
	output wire [N_CHANNELS - 1:0] ch_en_o;
	output wire [N_CHANNELS - 1:0] ch_pending_o;
	output wire [(N_CHANNELS * L2_AWIDTH_NOAL) - 1:0] ch_curr_addr_o;
	output wire [(N_CHANNELS * TRANS_SIZE) - 1:0] ch_bytes_left_o;
	input wire [(N_CHANNELS * L2_AWIDTH_NOAL) - 1:0] cfg_startaddr_i;
	input wire [(N_CHANNELS * TRANS_SIZE) - 1:0] cfg_size_i;
	input wire [N_CHANNELS - 1:0] cfg_continuous_i;
	input wire [N_CHANNELS - 1:0] cfg_en_i;
	input wire [N_CHANNELS - 1:0] cfg_clr_i;
	localparam ALIGN_BITS = $clog2(L2_DATA_WIDTH / 8);
	localparam L2_SIZE = L2_ADDR_WIDTH + ALIGN_BITS;
	localparam N_CHANNELS_TX = N_CHANNELS + 2;
	localparam LOG_N_CHANNELS = $clog2(N_CHANNELS_TX);
	localparam INTFIFO_SIZE = (L2_SIZE + LOG_N_CHANNELS) + 2;
	integer i;
	wire [N_CHANNELS_TX - 1:0] s_grant;
	reg [N_CHANNELS_TX - 1:0] r_grant;
	wire [N_CHANNELS_TX - 1:0] s_req;
	wire [N_CHANNELS_TX - 1:0] s_gnt;
	reg [LOG_N_CHANNELS - 1:0] s_grant_log;
	wire [N_CHANNELS_TX - 1:0] s_ch_ready;
	wire [N_CHANNELS - 1:0] s_ch_en;
	wire [LOG_N_CHANNELS - 1:0] s_resp;
	reg [LOG_N_CHANNELS - 1:0] r_resp;
	reg [LOG_N_CHANNELS - 1:0] r_resp_dly;
	reg r_valid;
	wire s_anygrant;
	reg r_anygrant;
	wire s_send_req;
	reg [L2_AWIDTH_NOAL - 1:0] s_addr;
	wire [(N_CHANNELS_TX * L2_AWIDTH_NOAL) - 1:0] s_curr_addr;
	reg [L2_AWIDTH_NOAL - 1:0] r_in_addr;
	wire [1:0] s_size;
	wire [1:0] s_trans_size;
	reg [DATA_WIDTH - 1:0] s_data;
	reg [1:0] r_size;
	reg [DATA_WIDTH - 1:0] r_data;
	wire [ALIGN_BITS - 1:0] s_addr_lsb;
	reg [ALIGN_BITS - 1:0] r_addr;
	reg [1:0] s_in_size;
	reg [1:0] r_in_size;
	wire [INTFIFO_SIZE - 1:0] s_fifoin;
	wire [INTFIFO_SIZE - 1:0] s_fifoout;
	wire s_l2_req_o;
	wire s_stall;
	wire s_sample_indata;
	assign ch_curr_addr_o = s_curr_addr;
	assign ch_en_o = s_ch_en;
	assign s_fifoin = {s_grant_log, r_in_size, s_addr[L2_SIZE - 1:0]};
	assign l2_addr_o = s_fifoout[L2_SIZE - 1:ALIGN_BITS];
	assign s_addr_lsb = s_fifoout[ALIGN_BITS - 1:0];
	assign s_trans_size = s_fifoout[L2_SIZE + 1:L2_SIZE];
	assign s_resp = s_fifoout[INTFIFO_SIZE - 1:L2_SIZE + 2];
	assign s_req[N_CHANNELS - 1:0] = ch_req_i & s_ch_en;
	assign s_req[N_CHANNELS_TX - 1:N_CHANNELS] = filter_ch_req_i;
	assign s_gnt = (s_sample_indata ? s_grant : 'h0);
	assign s_send_req = r_anygrant;
	assign l2_req_o = s_l2_req_o & ~s_stall;
	assign ch_gnt_o = s_gnt[N_CHANNELS - 1:0];
	assign filter_ch_gnt_o = s_gnt[N_CHANNELS_TX - 1:N_CHANNELS];
	udma_arbiter #(
		.N(N_CHANNELS_TX),
		.S(LOG_N_CHANNELS)
	) u_arbiter(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.req_i(s_req),
		.grant_o(s_grant),
		.grant_ack_i(s_sample_indata),
		.anyGrant_o(s_anygrant)
	);
	io_generic_fifo #(
		.DATA_WIDTH(INTFIFO_SIZE),
		.BUFFER_DEPTH(4)
	) u_fifo(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.elements_o(),
		.clr_i(1'b0),
		.data_o(s_fifoout),
		.valid_o(s_l2_req_o),
		.ready_i(l2_gnt_i),
		.valid_i(s_send_req),
		.data_i(s_fifoin),
		.ready_o(s_sample_indata)
	);
	genvar _gv_j_1;
	generate
		for (_gv_j_1 = 0; _gv_j_1 < N_CHANNELS; _gv_j_1 = _gv_j_1 + 1) begin : genblk1
			localparam j = _gv_j_1;
			udma_ch_addrgen #(
				.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
				.TRANS_SIZE(TRANS_SIZE)
			) u_tx_ch_ctrl(
				.clk_i(clk_i),
				.rstn_i(rstn_i),
				.cfg_startaddr_i(cfg_startaddr_i[j * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
				.cfg_size_i(cfg_size_i[j * TRANS_SIZE+:TRANS_SIZE]),
				.cfg_continuous_i(cfg_continuous_i[j]),
				.cfg_filter_i(1'b0),
				.cfg_en_i(cfg_en_i[j]),
				.cfg_clr_i(cfg_clr_i[j]),
				.int_datasize_i(r_in_size),
				.int_not_stall_i(s_sample_indata),
				.int_ch_curr_addr_o(s_curr_addr[j * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
				.int_ch_bytes_left_o(ch_bytes_left_o[j * TRANS_SIZE+:TRANS_SIZE]),
				.int_ch_grant_i(r_grant[j]),
				.int_ch_en_o(),
				.int_ch_sot_o(),
				.int_ch_en_prev_o(s_ch_en[j]),
				.int_ch_pending_o(ch_pending_o[j]),
				.int_ch_events_o(ch_events_o[j]),
				.int_filter_o()
			);
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		s_grant_log = 0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < N_CHANNELS_TX; i = i + 1)
				if (r_grant[i])
					s_grant_log = i;
		end
	end
	always @(*) begin : gen_addr
		if (_sv2v_0)
			;
		s_addr = 0;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < N_CHANNELS; i = i + 1)
				if (r_grant[i])
					s_addr = s_curr_addr[i * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL];
		end
		if (r_grant[N_CHANNELS] | r_grant[N_CHANNELS + 1])
			s_addr = r_in_addr;
	end
	always @(*) begin : gen_size
		if (_sv2v_0)
			;
		s_in_size = 0;
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < N_CHANNELS; i = i + 1)
				if (s_grant[i])
					s_in_size = ch_datasize_i[i * 2+:2];
		end
		if (s_grant[N_CHANNELS])
			s_in_size = filter_ch_datasize_i[0+:2];
		if (s_grant[N_CHANNELS + 1])
			s_in_size = filter_ch_datasize_i[2+:2];
	end
	always @(*) begin : demux_data
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_4
			reg signed [31:0] i;
			for (i = 0; i < N_CHANNELS; i = i + 1)
				begin
					ch_valid_o[i] = 1'b0;
					ch_data_o[i * DATA_WIDTH+:DATA_WIDTH] = 'hdeadbeef;
				end
		end
		filter_ch_valid_o[0] = 1'b0;
		filter_ch_data_o[0+:DATA_WIDTH] = 'hdeadbeef;
		filter_ch_valid_o[1] = 1'b0;
		filter_ch_data_o[DATA_WIDTH+:DATA_WIDTH] = 'hdeadbeef;
		if (r_resp_dly == N_CHANNELS) begin
			filter_ch_valid_o[0] = r_valid;
			filter_ch_data_o[0+:DATA_WIDTH] = r_data;
		end
		else if (r_resp_dly == (N_CHANNELS + 1)) begin
			filter_ch_valid_o[1] = r_valid;
			filter_ch_data_o[DATA_WIDTH+:DATA_WIDTH] = r_data;
		end
		else begin
			ch_valid_o[r_resp_dly] = r_valid;
			ch_data_o[r_resp_dly * DATA_WIDTH+:DATA_WIDTH] = r_data;
		end
	end
	assign s_ch_ready[N_CHANNELS - 1:0] = ch_ready_i;
	assign s_ch_ready[N_CHANNELS_TX - 1:N_CHANNELS] = filter_ch_ready_i;
	assign s_stall = |(~s_ch_ready & r_resp) & r_valid;
	always @(posedge clk_i or negedge rstn_i) begin : ff_data
		if (~rstn_i) begin
			r_grant <= 1'sb0;
			r_anygrant <= 1'sb0;
			r_resp <= 1'sb0;
			r_resp_dly <= 1'sb0;
			r_valid <= 1'sb0;
			r_in_size <= 1'sb0;
			r_size <= 1'sb0;
			r_addr <= 1'sb0;
			r_data <= 1'sb0;
			r_in_addr <= 1'sb0;
		end
		else begin
			r_valid <= l2_rvalid_i;
			r_resp_dly <= r_resp;
			if (l2_rvalid_i)
				r_data <= s_data;
			if (l2_req_o && l2_gnt_i) begin
				r_resp <= s_resp;
				r_size <= s_trans_size;
				r_addr <= s_addr_lsb;
			end
			if (s_sample_indata) begin
				r_in_size <= s_in_size;
				r_grant <= s_grant;
				r_anygrant <= s_anygrant;
				if (s_grant[N_CHANNELS])
					r_in_addr <= filter_ch_addr_i[0+:L2_AWIDTH_NOAL];
				else if (s_grant[N_CHANNELS + 1])
					r_in_addr <= filter_ch_addr_i[L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL];
			end
		end
	end
	generate
		if (L2_DATA_WIDTH == 64) begin : genblk2
			always @(*) begin
				if (_sv2v_0)
					;
				case (r_size)
					2'h0:
						if (r_addr == 3'b000)
							s_data = {24'h000000, l2_rdata_i[7:0]};
						else if (r_addr == 3'b001)
							s_data = {24'h000000, l2_rdata_i[15:8]};
						else if (r_addr == 3'b010)
							s_data = {24'h000000, l2_rdata_i[23:16]};
						else if (r_addr == 3'b011)
							s_data = {24'h000000, l2_rdata_i[31:24]};
						else if (r_addr == 3'b100)
							s_data = {24'h000000, l2_rdata_i[39:32]};
						else if (r_addr == 3'b101)
							s_data = {24'h000000, l2_rdata_i[47:40]};
						else if (r_addr == 3'b110)
							s_data = {24'h000000, l2_rdata_i[55:48]};
						else
							s_data = {24'h000000, l2_rdata_i[63:56]};
					2'h1:
						if (r_addr[2:1] == 2'b00)
							s_data = {16'h0000, l2_rdata_i[15:0]};
						else if (r_addr[2:1] == 2'b01)
							s_data = {16'h0000, l2_rdata_i[31:16]};
						else if (r_addr[2:1] == 2'b10)
							s_data = {16'h0000, l2_rdata_i[47:32]};
						else
							s_data = {16'h0000, l2_rdata_i[63:48]};
					2'h2:
						if (r_addr[2] == 1'b0)
							s_data = l2_rdata_i[31:0];
						else
							s_data = l2_rdata_i[63:32];
					default: s_data = 32'hdeadbeef;
				endcase
			end
		end
		else if (L2_DATA_WIDTH == 32) begin : genblk2
			always @(*) begin
				if (_sv2v_0)
					;
				case (r_size)
					2'h0:
						if (r_addr[1:0] == 2'b00)
							s_data = {24'h000000, l2_rdata_i[7:0]};
						else if (r_addr[1:0] == 2'b01)
							s_data = {24'h000000, l2_rdata_i[15:8]};
						else if (r_addr[1:0] == 2'b10)
							s_data = {24'h000000, l2_rdata_i[23:16]};
						else
							s_data = {24'h000000, l2_rdata_i[31:24]};
					2'h1:
						if (r_addr[1] == 1'b0)
							s_data = {16'h0000, l2_rdata_i[15:0]};
						else
							s_data = {16'h0000, l2_rdata_i[31:16]};
					2'h2: s_data = l2_rdata_i[31:0];
					default: s_data = 32'hdeadbeef;
				endcase
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
