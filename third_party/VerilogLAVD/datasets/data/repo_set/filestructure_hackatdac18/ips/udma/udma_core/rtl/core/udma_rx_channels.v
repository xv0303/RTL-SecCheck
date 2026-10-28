module udma_rx_channels (
	clk_i,
	rstn_i,
	l2_req_o,
	l2_gnt_i,
	l2_be_o,
	l2_addr_o,
	l2_wdata_o,
	filter_id_o,
	filter_data_o,
	filter_valid_o,
	filter_sot_o,
	filter_eot_o,
	filter_ready_i,
	filter_ch_valid_i,
	filter_ch_addr_i,
	filter_ch_data_i,
	filter_ch_datasize_i,
	filter_ch_ready_o,
	ch_valid_i,
	ch_data_i,
	ch_datasize_i,
	ch_ready_o,
	ch_events_o,
	ch_en_o,
	ch_pending_o,
	ch_curr_addr_o,
	ch_bytes_left_o,
	cfg_startaddr_i,
	cfg_size_i,
	cfg_continuous_i,
	cfg_en_i,
	cfg_filter_i,
	cfg_clr_i
);
	reg _sv2v_0;
	parameter L2_ADDR_WIDTH = 32;
	parameter L2_AWIDTH_NOAL = L2_ADDR_WIDTH + 3;
	parameter L2_DATA_WIDTH = 64;
	parameter DATA_WIDTH = 32;
	parameter N_CHANNELS = 8;
	parameter TRANS_SIZE = 16;
	parameter FILTER_DATA_WIDTH = 32;
	parameter FILTER_ID_WIDTH = $clog2(N_CHANNELS + 1);
	input wire clk_i;
	input wire rstn_i;
	output wire l2_req_o;
	input wire l2_gnt_i;
	output wire [(L2_DATA_WIDTH / 8) - 1:0] l2_be_o;
	output wire [L2_ADDR_WIDTH - 1:0] l2_addr_o;
	output reg [L2_DATA_WIDTH - 1:0] l2_wdata_o;
	output wire [FILTER_ID_WIDTH - 1:0] filter_id_o;
	output wire [FILTER_DATA_WIDTH - 1:0] filter_data_o;
	output wire filter_valid_o;
	output wire filter_sot_o;
	output wire filter_eot_o;
	input wire filter_ready_i;
	input wire filter_ch_valid_i;
	input wire [L2_AWIDTH_NOAL - 1:0] filter_ch_addr_i;
	input wire [DATA_WIDTH - 1:0] filter_ch_data_i;
	input wire [1:0] filter_ch_datasize_i;
	output reg filter_ch_ready_o;
	input wire [N_CHANNELS - 1:0] ch_valid_i;
	input wire [(N_CHANNELS * DATA_WIDTH) - 1:0] ch_data_i;
	input wire [(N_CHANNELS * 2) - 1:0] ch_datasize_i;
	output reg [N_CHANNELS - 1:0] ch_ready_o;
	output wire [N_CHANNELS - 1:0] ch_events_o;
	output wire [N_CHANNELS - 1:0] ch_en_o;
	output wire [N_CHANNELS - 1:0] ch_pending_o;
	output wire [(N_CHANNELS * L2_AWIDTH_NOAL) - 1:0] ch_curr_addr_o;
	output wire [(N_CHANNELS * TRANS_SIZE) - 1:0] ch_bytes_left_o;
	input wire [(N_CHANNELS * L2_AWIDTH_NOAL) - 1:0] cfg_startaddr_i;
	input wire [(N_CHANNELS * TRANS_SIZE) - 1:0] cfg_size_i;
	input wire [N_CHANNELS - 1:0] cfg_continuous_i;
	input wire [N_CHANNELS - 1:0] cfg_en_i;
	input wire [N_CHANNELS - 1:0] cfg_filter_i;
	input wire [N_CHANNELS - 1:0] cfg_clr_i;
	localparam ALIGN_BITS = $clog2(L2_DATA_WIDTH / 8);
	localparam L2_SIZE = L2_ADDR_WIDTH + ALIGN_BITS;
	localparam N_CHANNELS_RX = N_CHANNELS + 1;
	localparam LOG_N_CHANNELS = (N_CHANNELS_RX < 1 ? 0 : (N_CHANNELS_RX < 2 ? 1 : (N_CHANNELS_RX < 4 ? 2 : (N_CHANNELS_RX < 8 ? 3 : (N_CHANNELS_RX < 16 ? 4 : (N_CHANNELS_RX < 32 ? 5 : (N_CHANNELS_RX < 64 ? 6 : (N_CHANNELS_RX < 128 ? 7 : (N_CHANNELS_RX < 256 ? 8 : (N_CHANNELS_RX < 512 ? 9 : (N_CHANNELS_RX < 1024 ? 10 : (N_CHANNELS_RX < 2048 ? 11 : (N_CHANNELS_RX < 4096 ? 12 : (N_CHANNELS_RX < 8192 ? 13 : (N_CHANNELS_RX < 16384 ? 14 : (N_CHANNELS_RX < 32768 ? 15 : (N_CHANNELS_RX < 65536 ? 16 : (N_CHANNELS_RX < 131072 ? 17 : (N_CHANNELS_RX < 262144 ? 18 : (N_CHANNELS_RX < 524288 ? 19 : (N_CHANNELS_RX < 1048576 ? 20 : (N_CHANNELS_RX < 2097152 ? 21 : (N_CHANNELS_RX < 4194304 ? 22 : (N_CHANNELS_RX < 8388608 ? 23 : (N_CHANNELS_RX < 16777216 ? 24 : 25)))))))))))))))))))))))));
	localparam INTFIFO_SIZE = (L2_SIZE + DATA_WIDTH) + 2;
	localparam INTFIFO_FILTER_SIZE = (FILTER_DATA_WIDTH + FILTER_ID_WIDTH) + 2;
	integer i;
	wire [(N_CHANNELS * L2_AWIDTH_NOAL) - 1:0] s_curr_addr;
	wire [N_CHANNELS_RX - 1:0] s_grant;
	reg [N_CHANNELS_RX - 1:0] r_grant;
	wire [N_CHANNELS_RX - 1:0] s_req;
	reg [FILTER_ID_WIDTH - 1:0] s_grant_log;
	wire [N_CHANNELS - 1:0] s_ch_en;
	wire s_anygrant;
	reg r_anygrant;
	reg [31:0] s_data;
	reg [31:0] r_data;
	reg [L2_AWIDTH_NOAL - 1:0] s_addr;
	reg [L2_AWIDTH_NOAL - 1:0] r_addr;
	reg [1:0] s_size;
	reg [1:0] r_size;
	wire [1:0] s_l2_size;
	wire [DATA_WIDTH - 1:0] s_l2_data;
	reg [(L2_DATA_WIDTH / 8) - 1:0] s_l2_be;
	wire [L2_SIZE - 1:0] s_l2_addr;
	wire [INTFIFO_SIZE - 1:0] s_fifoin;
	wire [INTFIFO_SIZE - 1:0] s_fifoout;
	wire [INTFIFO_FILTER_SIZE - 1:0] s_fifoin_filter;
	wire [INTFIFO_FILTER_SIZE - 1:0] s_fifoout_filter;
	wire s_sample_indata;
	wire s_sample_indata_l2;
	wire s_sample_indata_filter;
	wire [N_CHANNELS - 1:0] s_filter;
	reg s_is_filter;
	wire [N_CHANNELS - 1:0] s_ch_events;
	wire [N_CHANNELS - 1:0] s_ch_sot;
	reg s_event;
	reg s_sot;
	assign ch_events_o = s_ch_events;
	assign ch_curr_addr_o = s_curr_addr;
	assign ch_en_o = s_ch_en;
	assign s_fifoin = {r_size, s_addr[L2_SIZE - 1:0], r_data};
	assign s_fifoin_filter = {s_sot, s_event, s_grant_log, r_data};
	assign s_l2_data = s_fifoout[DATA_WIDTH - 1:0];
	assign s_l2_addr = s_fifoout[(L2_SIZE + DATA_WIDTH) - 1:DATA_WIDTH];
	assign s_l2_size = s_fifoout[(L2_SIZE + DATA_WIDTH) + 1:L2_SIZE + DATA_WIDTH];
	assign s_req[N_CHANNELS - 1:0] = ch_valid_i & s_ch_en;
	assign s_req[N_CHANNELS] = filter_ch_valid_i;
	assign l2_be_o = s_l2_be;
	assign l2_addr_o = s_l2_addr[L2_SIZE - 1:ALIGN_BITS];
	assign filter_id_o = s_fifoout_filter[INTFIFO_FILTER_SIZE - 3:FILTER_DATA_WIDTH];
	assign filter_data_o = s_fifoout_filter[FILTER_DATA_WIDTH - 1:0];
	assign filter_sot_o = s_fifoout_filter[INTFIFO_FILTER_SIZE - 1];
	assign filter_eot_o = s_fifoout_filter[INTFIFO_FILTER_SIZE - 2];
	assign s_sample_indata = s_sample_indata_filter & s_sample_indata_l2;
	wire s_push_l2;
	assign s_push_l2 = r_anygrant & !s_is_filter;
	wire s_push_filter;
	assign s_push_filter = r_anygrant & s_is_filter;
	udma_arbiter #(
		.N(N_CHANNELS_RX),
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
		.valid_o(l2_req_o),
		.ready_i(l2_gnt_i),
		.valid_i(s_push_l2),
		.data_i(s_fifoin),
		.ready_o(s_sample_indata_l2)
	);
	io_generic_fifo #(
		.DATA_WIDTH(INTFIFO_FILTER_SIZE),
		.BUFFER_DEPTH(4)
	) u_filter_fifo(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.elements_o(),
		.clr_i(1'b0),
		.data_o(s_fifoout_filter),
		.valid_o(filter_valid_o),
		.ready_i(filter_ready_i),
		.valid_i(s_push_filter),
		.data_i(s_fifoin_filter),
		.ready_o(s_sample_indata_filter)
	);
	genvar _gv_j_1;
	generate
		for (_gv_j_1 = 0; _gv_j_1 < N_CHANNELS; _gv_j_1 = _gv_j_1 + 1) begin : genblk1
			localparam j = _gv_j_1;
			udma_ch_addrgen #(
				.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
				.TRANS_SIZE(TRANS_SIZE)
			) u_rx_ch_ctrl(
				.clk_i(clk_i),
				.rstn_i(rstn_i),
				.cfg_startaddr_i(cfg_startaddr_i[j * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
				.cfg_size_i(cfg_size_i[j * TRANS_SIZE+:TRANS_SIZE]),
				.cfg_continuous_i(cfg_continuous_i[j]),
				.cfg_filter_i(cfg_filter_i[j]),
				.cfg_en_i(cfg_en_i[j]),
				.cfg_clr_i(cfg_clr_i[j]),
				.int_datasize_i(r_size),
				.int_not_stall_i(s_sample_indata),
				.int_ch_curr_addr_o(s_curr_addr[j * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
				.int_ch_bytes_left_o(ch_bytes_left_o[j * TRANS_SIZE+:TRANS_SIZE]),
				.int_ch_grant_i(r_grant[j]),
				.int_ch_en_o(),
				.int_ch_en_prev_o(s_ch_en[j]),
				.int_ch_pending_o(ch_pending_o[j]),
				.int_ch_sot_o(s_ch_sot[j]),
				.int_ch_events_o(s_ch_events[j]),
				.int_filter_o(s_filter[j])
			);
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		s_grant_log = 0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < N_CHANNELS; i = i + 1)
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
		if (r_grant[N_CHANNELS])
			s_addr = r_addr;
	end
	always @(*) begin : gen_is_filter
		if (_sv2v_0)
			;
		s_is_filter = 0;
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < N_CHANNELS; i = i + 1)
				if (r_grant[i])
					s_is_filter = s_filter[i];
		end
		if (r_grant[N_CHANNELS])
			s_is_filter = 1'b0;
	end
	always @(*) begin : gen_event
		if (_sv2v_0)
			;
		s_event = 1'b0;
		begin : sv2v_autoblock_4
			reg signed [31:0] i;
			for (i = 0; i < N_CHANNELS; i = i + 1)
				if (r_grant[i])
					s_event = s_ch_events[i];
		end
	end
	always @(*) begin : gen_sot
		if (_sv2v_0)
			;
		s_sot = 1'b0;
		begin : sv2v_autoblock_5
			reg signed [31:0] i;
			for (i = 0; i < N_CHANNELS; i = i + 1)
				if (r_grant[i])
					s_sot = s_ch_sot[i];
		end
	end
	always @(*) begin : gen_data
		if (_sv2v_0)
			;
		s_data = 0;
		begin : sv2v_autoblock_6
			reg signed [31:0] i;
			for (i = 0; i < N_CHANNELS; i = i + 1)
				if (s_grant[i])
					s_data = ch_data_i[i * DATA_WIDTH+:DATA_WIDTH];
		end
		if (s_grant[N_CHANNELS])
			s_data = filter_ch_data_i;
	end
	always @(*) begin : gen_size
		if (_sv2v_0)
			;
		s_size = 0;
		begin : sv2v_autoblock_7
			reg signed [31:0] i;
			for (i = 0; i < N_CHANNELS; i = i + 1)
				if (s_grant[i])
					s_size = ch_datasize_i[i * 2+:2];
		end
		if (s_grant[N_CHANNELS])
			s_size = filter_ch_datasize_i;
	end
	always @(*) begin : mux_ready
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_8
			reg signed [31:0] i;
			for (i = 0; i < N_CHANNELS; i = i + 1)
				if (s_grant[i])
					ch_ready_o[i] = s_sample_indata;
				else
					ch_ready_o[i] = 1'b0;
		end
		if (s_grant[N_CHANNELS])
			filter_ch_ready_o = s_sample_indata;
		else
			filter_ch_ready_o = 1'b0;
	end
	always @(posedge clk_i or negedge rstn_i) begin : ff_data
		if (~rstn_i) begin
			r_data <= 1'sb0;
			r_grant <= 1'sb0;
			r_anygrant <= 1'sb0;
			r_size <= 1'sb0;
			r_addr <= 1'sb0;
		end
		else if (s_sample_indata) begin
			r_data <= s_data;
			r_size <= s_size;
			r_grant <= s_grant;
			r_anygrant <= s_anygrant;
			if (s_grant[N_CHANNELS])
				r_addr <= filter_ch_addr_i;
		end
	end
	generate
		if (L2_DATA_WIDTH == 64) begin : genblk2
			always @(*) begin
				if (_sv2v_0)
					;
				case (s_l2_size)
					2'h0:
						if (s_l2_addr[2:0] == 3'b000)
							s_l2_be = 8'b00000001;
						else if (s_l2_addr[2:0] == 3'b001)
							s_l2_be = 8'b00000010;
						else if (s_l2_addr[2:0] == 3'b010)
							s_l2_be = 8'b00000100;
						else if (s_l2_addr[2:0] == 3'b011)
							s_l2_be = 8'b00001000;
						else if (s_l2_addr[2:0] == 3'b100)
							s_l2_be = 8'b00010000;
						else if (s_l2_addr[2:0] == 3'b101)
							s_l2_be = 8'b00100000;
						else if (s_l2_addr[2:0] == 3'b110)
							s_l2_be = 8'b01000000;
						else
							s_l2_be = 8'b10000000;
					2'h1:
						if (s_l2_addr[2:1] == 2'b00)
							s_l2_be = 8'b00000011;
						else if (s_l2_addr[2:1] == 2'b01)
							s_l2_be = 8'b00001100;
						else if (s_l2_addr[2:1] == 2'b10)
							s_l2_be = 8'b00110000;
						else
							s_l2_be = 8'b11000000;
					2'h2:
						if (s_l2_addr[2] == 1'b0)
							s_l2_be = 8'b00001111;
						else
							s_l2_be = 8'b11110000;
					default: s_l2_be = 8'b00000000;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				case (s_l2_be)
					8'b00001111: l2_wdata_o = {32'h00000000, s_l2_data[31:0]};
					8'b11110000: l2_wdata_o = {s_l2_data[31:0], 32'h00000000};
					8'b00000011: l2_wdata_o = {48'h000000000000, s_l2_data[15:0]};
					8'b00001100: l2_wdata_o = {32'h00000000, s_l2_data[15:0], 16'h0000};
					8'b00110000: l2_wdata_o = {16'h0000, s_l2_data[15:0], 32'h00000000};
					8'b11000000: l2_wdata_o = {s_l2_data[15:0], 48'h000000000000};
					8'b00000001: l2_wdata_o = {56'h00000000000000, s_l2_data[7:0]};
					8'b00000010: l2_wdata_o = {48'h000000000000, s_l2_data[7:0], 8'h00};
					8'b00000100: l2_wdata_o = {40'h0000000000, s_l2_data[7:0], 16'h0000};
					8'b00001000: l2_wdata_o = {32'h00000000, s_l2_data[7:0], 24'h000000};
					8'b00010000: l2_wdata_o = {24'h000000, s_l2_data[7:0], 32'h00000000};
					8'b00100000: l2_wdata_o = {16'h0000, s_l2_data[7:0], 40'h0000000000};
					8'b01000000: l2_wdata_o = {8'h00, s_l2_data[7:0], 48'h000000000000};
					8'b10000000: l2_wdata_o = {s_l2_data[7:0], 56'h00000000000000};
					default: l2_wdata_o = 64'hdeadabbadeadbeef;
				endcase
			end
		end
		else if (L2_DATA_WIDTH == 32) begin : genblk2
			always @(*) begin
				if (_sv2v_0)
					;
				case (s_l2_size)
					2'h0:
						if (s_l2_addr[1:0] == 2'b00)
							s_l2_be = 4'b0001;
						else if (s_l2_addr[1:0] == 2'b01)
							s_l2_be = 4'b0010;
						else if (s_l2_addr[1:0] == 2'b10)
							s_l2_be = 4'b0100;
						else
							s_l2_be = 4'b1000;
					2'h1:
						if (s_l2_addr[1] == 1'b0)
							s_l2_be = 4'b0011;
						else
							s_l2_be = 4'b1100;
					2'h2: s_l2_be = 4'b1111;
					default: s_l2_be = 4'b0000;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				case (s_l2_be)
					4'b1111: l2_wdata_o = s_l2_data[31:0];
					4'b0011: l2_wdata_o = {16'h0000, s_l2_data[15:0]};
					4'b1100: l2_wdata_o = {s_l2_data[15:0], 16'h0000};
					4'b0001: l2_wdata_o = {24'h000000, s_l2_data[7:0]};
					4'b0010: l2_wdata_o = {16'h0000, s_l2_data[7:0], 8'h00};
					4'b0100: l2_wdata_o = {8'h00, s_l2_data[7:0], 16'h0000};
					4'b1000: l2_wdata_o = {s_l2_data[7:0], 24'h000000};
					default: l2_wdata_o = 32'hdeadbeef;
				endcase
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
