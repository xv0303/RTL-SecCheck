module udma_core (
	sys_clk_i,
	per_clk_i,
	dft_cg_enable_i,
	HRESETn,
	PADDR,
	PWDATA,
	PWRITE,
	PSEL,
	PENABLE,
	PRDATA,
	PREADY,
	PSLVERR,
	event_valid_i,
	event_data_i,
	event_ready_o,
	event_o,
	filter_eot_o,
	filter_act_o,
	periph_per_clk_o,
	periph_sys_clk_o,
	periph_data_to_o,
	periph_addr_o,
	periph_rwn_o,
	periph_data_from_i,
	periph_valid_o,
	periph_ready_i,
	rx_l2_req_o,
	rx_l2_gnt_i,
	rx_l2_addr_o,
	rx_l2_be_o,
	rx_l2_wdata_o,
	tx_l2_req_o,
	tx_l2_gnt_i,
	tx_l2_addr_o,
	tx_l2_rdata_i,
	tx_l2_rvalid_i,
	tx_ch_req_i,
	tx_ch_gnt_o,
	tx_ch_valid_o,
	tx_ch_data_o,
	tx_ch_ready_i,
	tx_ch_datasize_i,
	tx_ch_events_o,
	tx_ch_en_o,
	tx_ch_pending_o,
	tx_ch_curr_addr_o,
	tx_ch_bytes_left_o,
	tx_cfg_startaddr_i,
	tx_cfg_size_i,
	tx_cfg_continuous_i,
	tx_cfg_en_i,
	tx_cfg_clr_i,
	rx_ch_datasize_i,
	rx_ch_valid_i,
	rx_ch_data_i,
	rx_ch_ready_o,
	rx_ch_events_o,
	rx_ch_en_o,
	rx_ch_pending_o,
	rx_ch_curr_addr_o,
	rx_ch_bytes_left_o,
	rx_cfg_startaddr_i,
	rx_cfg_size_i,
	rx_cfg_continuous_i,
	rx_cfg_en_i,
	rx_cfg_filter_i,
	rx_cfg_clr_i
);
	reg _sv2v_0;
	parameter L2_DATA_WIDTH = 64;
	parameter DATA_WIDTH = 32;
	parameter L2_ADDR_WIDTH = 15;
	parameter L2_AWIDTH_NOAL = L2_ADDR_WIDTH + ((L2_DATA_WIDTH / 8) < 2 ? 0 : ((L2_DATA_WIDTH / 8) < 3 ? 1 : ((L2_DATA_WIDTH / 8) < 5 ? 2 : ((L2_DATA_WIDTH / 8) < 9 ? 3 : ((L2_DATA_WIDTH / 8) < 17 ? 4 : ((L2_DATA_WIDTH / 8) < 33 ? 5 : ((L2_DATA_WIDTH / 8) < 65 ? 6 : ((L2_DATA_WIDTH / 8) < 129 ? 7 : ((L2_DATA_WIDTH / 8) < 257 ? 8 : ((L2_DATA_WIDTH / 8) < 513 ? 9 : ((L2_DATA_WIDTH / 8) < 1025 ? 10 : ((L2_DATA_WIDTH / 8) < 2049 ? 11 : ((L2_DATA_WIDTH / 8) < 4097 ? 12 : ((L2_DATA_WIDTH / 8) < 8193 ? 13 : ((L2_DATA_WIDTH / 8) < 16385 ? 14 : ((L2_DATA_WIDTH / 8) < 32769 ? 15 : ((L2_DATA_WIDTH / 8) < 65537 ? 16 : ((L2_DATA_WIDTH / 8) < 131073 ? 17 : ((L2_DATA_WIDTH / 8) < 262145 ? 18 : ((L2_DATA_WIDTH / 8) < 524289 ? 19 : ((L2_DATA_WIDTH / 8) < 1048576 ? 20 : ((L2_DATA_WIDTH / 8) < 2097152 ? 21 : ((L2_DATA_WIDTH / 8) < 4194304 ? 22 : ((L2_DATA_WIDTH / 8) < 8388608 ? 23 : ((L2_DATA_WIDTH / 8) < 16777216 ? 24 : 25)))))))))))))))))))))))));
	parameter APB_ADDR_WIDTH = 12;
	parameter N_RX_CHANNELS = 8;
	parameter N_TX_CHANNELS = 8;
	parameter N_PERIPHS = 8;
	parameter TRANS_SIZE = 16;
	input wire sys_clk_i;
	input wire per_clk_i;
	input wire dft_cg_enable_i;
	input wire HRESETn;
	input wire [APB_ADDR_WIDTH - 1:0] PADDR;
	input wire [31:0] PWDATA;
	input wire PWRITE;
	input wire PSEL;
	input wire PENABLE;
	output wire [31:0] PRDATA;
	output wire PREADY;
	output wire PSLVERR;
	input wire event_valid_i;
	input wire [7:0] event_data_i;
	output wire event_ready_o;
	output wire [3:0] event_o;
	output wire filter_eot_o;
	output wire filter_act_o;
	output wire [N_PERIPHS - 1:0] periph_per_clk_o;
	output wire [N_PERIPHS - 1:0] periph_sys_clk_o;
	output wire [31:0] periph_data_to_o;
	output wire [4:0] periph_addr_o;
	output wire periph_rwn_o;
	input wire [(N_PERIPHS * 32) - 1:0] periph_data_from_i;
	output wire [N_PERIPHS - 1:0] periph_valid_o;
	input wire [N_PERIPHS - 1:0] periph_ready_i;
	output wire rx_l2_req_o;
	input wire rx_l2_gnt_i;
	output wire [L2_ADDR_WIDTH - 1:0] rx_l2_addr_o;
	output wire [(L2_DATA_WIDTH / 8) - 1:0] rx_l2_be_o;
	output wire [L2_DATA_WIDTH - 1:0] rx_l2_wdata_o;
	output wire tx_l2_req_o;
	input wire tx_l2_gnt_i;
	output wire [L2_ADDR_WIDTH - 1:0] tx_l2_addr_o;
	input wire [L2_DATA_WIDTH - 1:0] tx_l2_rdata_i;
	input wire tx_l2_rvalid_i;
	input wire [N_TX_CHANNELS - 1:0] tx_ch_req_i;
	output wire [N_TX_CHANNELS - 1:0] tx_ch_gnt_o;
	output wire [N_TX_CHANNELS - 1:0] tx_ch_valid_o;
	output wire [(N_TX_CHANNELS * DATA_WIDTH) - 1:0] tx_ch_data_o;
	input wire [N_TX_CHANNELS - 1:0] tx_ch_ready_i;
	input wire [(N_TX_CHANNELS * 2) - 1:0] tx_ch_datasize_i;
	output wire [N_TX_CHANNELS - 1:0] tx_ch_events_o;
	output wire [N_TX_CHANNELS - 1:0] tx_ch_en_o;
	output wire [N_TX_CHANNELS - 1:0] tx_ch_pending_o;
	output wire [(N_TX_CHANNELS * L2_AWIDTH_NOAL) - 1:0] tx_ch_curr_addr_o;
	output wire [(N_TX_CHANNELS * TRANS_SIZE) - 1:0] tx_ch_bytes_left_o;
	input wire [(N_TX_CHANNELS * L2_AWIDTH_NOAL) - 1:0] tx_cfg_startaddr_i;
	input wire [(N_TX_CHANNELS * TRANS_SIZE) - 1:0] tx_cfg_size_i;
	input wire [N_TX_CHANNELS - 1:0] tx_cfg_continuous_i;
	input wire [N_TX_CHANNELS - 1:0] tx_cfg_en_i;
	input wire [N_TX_CHANNELS - 1:0] tx_cfg_clr_i;
	input wire [(N_RX_CHANNELS * 2) - 1:0] rx_ch_datasize_i;
	input wire [N_RX_CHANNELS - 1:0] rx_ch_valid_i;
	input wire [(N_RX_CHANNELS * DATA_WIDTH) - 1:0] rx_ch_data_i;
	output wire [N_RX_CHANNELS - 1:0] rx_ch_ready_o;
	output wire [N_RX_CHANNELS - 1:0] rx_ch_events_o;
	output wire [N_RX_CHANNELS - 1:0] rx_ch_en_o;
	output wire [N_RX_CHANNELS - 1:0] rx_ch_pending_o;
	output wire [(N_RX_CHANNELS * L2_AWIDTH_NOAL) - 1:0] rx_ch_curr_addr_o;
	output wire [(N_RX_CHANNELS * TRANS_SIZE) - 1:0] rx_ch_bytes_left_o;
	input wire [(N_RX_CHANNELS * L2_AWIDTH_NOAL) - 1:0] rx_cfg_startaddr_i;
	input wire [(N_RX_CHANNELS * TRANS_SIZE) - 1:0] rx_cfg_size_i;
	input wire [N_RX_CHANNELS - 1:0] rx_cfg_continuous_i;
	input wire [N_RX_CHANNELS - 1:0] rx_cfg_en_i;
	input wire [N_RX_CHANNELS - 1:0] rx_cfg_filter_i;
	input wire [N_RX_CHANNELS - 1:0] rx_cfg_clr_i;
	localparam FILTID_WIDTH = $clog2(N_RX_CHANNELS + 1);
	wire [1:0] s_filter_tx_ch_req;
	wire [(2 * L2_AWIDTH_NOAL) - 1:0] s_filter_tx_ch_addr;
	wire [3:0] s_filter_tx_ch_datasize;
	wire [1:0] s_filter_tx_ch_gnt;
	wire [1:0] s_filter_tx_ch_valid;
	wire [(2 * DATA_WIDTH) - 1:0] s_filter_tx_ch_data;
	wire [1:0] s_filter_tx_ch_ready;
	wire [(2 * L2_AWIDTH_NOAL) - 1:0] s_filter_tx_ch_cfg_start_addr;
	wire [3:0] s_filter_tx_ch_cfg_datasize;
	wire [3:0] s_filter_tx_ch_cfg_mode;
	wire [(2 * TRANS_SIZE) - 1:0] s_filter_tx_ch_cfg_len0;
	wire [(2 * TRANS_SIZE) - 1:0] s_filter_tx_ch_cfg_len1;
	wire [(2 * TRANS_SIZE) - 1:0] s_filter_tx_ch_cfg_len2;
	wire s_filter_rx_ch_valid;
	wire [L2_AWIDTH_NOAL - 1:0] s_filter_rx_ch_addr;
	wire [DATA_WIDTH - 1:0] s_filter_rx_ch_data;
	wire [1:0] s_filter_rx_ch_datasize;
	wire s_filter_rx_ch_ready;
	wire [L2_AWIDTH_NOAL - 1:0] s_filter_rx_ch_cfg_start_addr;
	wire [1:0] s_filter_rx_ch_cfg_datasize;
	wire [1:0] s_filter_rx_ch_cfg_mode;
	wire [TRANS_SIZE - 1:0] s_filter_rx_ch_cfg_len0;
	wire [TRANS_SIZE - 1:0] s_filter_rx_ch_cfg_len1;
	wire [TRANS_SIZE - 1:0] s_filter_rx_ch_cfg_len2;
	wire [2:0] s_filter_cfg_mode;
	wire s_filter_cfg_start;
	wire s_au_cfg_use_signed;
	wire s_au_cfg_bypass;
	wire [3:0] s_au_cfg_mode;
	wire [4:0] s_au_cfg_shift;
	wire [31:0] s_au_cfg_reg0;
	wire [31:0] s_au_cfg_reg1;
	wire [31:0] s_bincu_cfg_threshold;
	wire [TRANS_SIZE - 1:0] s_bincu_cfg_counter;
	wire [FILTID_WIDTH - 1:0] s_filter_stream_id;
	wire [DATA_WIDTH - 1:0] s_filter_stream_data;
	wire s_filter_stream_valid;
	wire s_filter_stream_evnt;
	wire s_filter_stream_ready;
	wire [31:0] s_periph_data_to;
	wire [4:0] s_periph_addr;
	wire s_periph_rwn;
	reg [511:0] s_periph_data_from;
	wire [15:0] s_periph_valid;
	reg [15:0] s_periph_ready;
	wire s_periph_ready_from_cgunit;
	wire [31:0] s_periph_data_from_cgunit;
	wire [15:0] s_cg_value;
	assign periph_data_to_o = s_periph_data_to;
	assign periph_addr_o = s_periph_addr;
	assign periph_rwn_o = s_periph_rwn;
	assign periph_valid_o = s_periph_valid[N_PERIPHS - 1:0];
	wire s_clk_core;
	udma_tx_channels #(
		.L2_DATA_WIDTH(L2_DATA_WIDTH),
		.L2_ADDR_WIDTH(L2_ADDR_WIDTH),
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.DATA_WIDTH(32),
		.N_CHANNELS(N_TX_CHANNELS),
		.TRANS_SIZE(TRANS_SIZE)
	) u_tx_channels(
		.clk_i(s_clk_core),
		.rstn_i(HRESETn),
		.l2_req_o(tx_l2_req_o),
		.l2_gnt_i(tx_l2_gnt_i),
		.l2_addr_o(tx_l2_addr_o),
		.l2_rdata_i(tx_l2_rdata_i),
		.l2_rvalid_i(tx_l2_rvalid_i),
		.ch_req_i(tx_ch_req_i),
		.ch_gnt_o(tx_ch_gnt_o),
		.ch_valid_o(tx_ch_valid_o),
		.ch_data_o(tx_ch_data_o),
		.ch_ready_i(tx_ch_ready_i),
		.ch_datasize_i(tx_ch_datasize_i),
		.ch_events_o(tx_ch_events_o),
		.ch_en_o(tx_ch_en_o),
		.ch_pending_o(tx_ch_pending_o),
		.ch_curr_addr_o(tx_ch_curr_addr_o),
		.ch_bytes_left_o(tx_ch_bytes_left_o),
		.filter_ch_req_i(s_filter_tx_ch_req),
		.filter_ch_addr_i(s_filter_tx_ch_addr),
		.filter_ch_datasize_i(s_filter_tx_ch_datasize),
		.filter_ch_gnt_o(s_filter_tx_ch_gnt),
		.filter_ch_valid_o(s_filter_tx_ch_valid),
		.filter_ch_data_o(s_filter_tx_ch_data),
		.filter_ch_ready_i(s_filter_tx_ch_ready),
		.cfg_startaddr_i(tx_cfg_startaddr_i),
		.cfg_size_i(tx_cfg_size_i),
		.cfg_continuous_i(tx_cfg_continuous_i),
		.cfg_en_i(tx_cfg_en_i),
		.cfg_clr_i(tx_cfg_clr_i)
	);
	wire s_filter_stream_sof;
	wire s_filter_stream_eof;
	udma_rx_channels #(
		.L2_DATA_WIDTH(L2_DATA_WIDTH),
		.L2_ADDR_WIDTH(L2_ADDR_WIDTH),
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.DATA_WIDTH(32),
		.N_CHANNELS(N_RX_CHANNELS),
		.TRANS_SIZE(TRANS_SIZE)
	) u_rx_channels(
		.clk_i(s_clk_core),
		.rstn_i(HRESETn),
		.l2_req_o(rx_l2_req_o),
		.l2_addr_o(rx_l2_addr_o),
		.l2_be_o(rx_l2_be_o),
		.l2_wdata_o(rx_l2_wdata_o),
		.l2_gnt_i(rx_l2_gnt_i),
		.ch_valid_i(rx_ch_valid_i),
		.ch_data_i(rx_ch_data_i),
		.ch_ready_o(rx_ch_ready_o),
		.ch_datasize_i(rx_ch_datasize_i),
		.ch_events_o(rx_ch_events_o),
		.ch_en_o(rx_ch_en_o),
		.ch_pending_o(rx_ch_pending_o),
		.ch_curr_addr_o(rx_ch_curr_addr_o),
		.ch_bytes_left_o(rx_ch_bytes_left_o),
		.filter_ch_valid_i(s_filter_rx_ch_valid),
		.filter_ch_addr_i(s_filter_rx_ch_addr),
		.filter_ch_data_i(s_filter_rx_ch_data),
		.filter_ch_datasize_i(s_filter_rx_ch_datasize),
		.filter_ch_ready_o(s_filter_rx_ch_ready),
		.filter_id_o(s_filter_stream_id),
		.filter_data_o(s_filter_stream_data),
		.filter_valid_o(s_filter_stream_valid),
		.filter_sot_o(s_filter_stream_sof),
		.filter_eot_o(s_filter_stream_eof),
		.filter_ready_i(s_filter_stream_ready),
		.cfg_startaddr_i(rx_cfg_startaddr_i),
		.cfg_size_i(rx_cfg_size_i),
		.cfg_continuous_i(rx_cfg_continuous_i),
		.cfg_en_i(rx_cfg_en_i),
		.cfg_filter_i(rx_cfg_filter_i),
		.cfg_clr_i(rx_cfg_clr_i)
	);
	wire s_clk_filter;
	udma_filter #(
		.DATA_WIDTH(DATA_WIDTH),
		.FILTID_WIDTH(FILTID_WIDTH),
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.TRANS_SIZE(TRANS_SIZE)
	) u_udma_filter(
		.clk_i(s_clk_filter),
		.resetn_i(HRESETn),
		.eot_event_o(filter_eot_o),
		.act_event_o(filter_act_o),
		.cfg_filter_mode_i(s_filter_cfg_mode),
		.cfg_filter_start_i(s_filter_cfg_start),
		.cfg_filter_tx_start_addr_i(s_filter_tx_ch_cfg_start_addr),
		.cfg_filter_tx_datasize_i(s_filter_tx_ch_cfg_datasize),
		.cfg_filter_tx_mode_i(s_filter_tx_ch_cfg_mode),
		.cfg_filter_tx_len0_i(s_filter_tx_ch_cfg_len0),
		.cfg_filter_tx_len1_i(s_filter_tx_ch_cfg_len1),
		.cfg_filter_tx_len2_i(s_filter_tx_ch_cfg_len2),
		.cfg_filter_rx_start_addr_i(s_filter_rx_ch_cfg_start_addr),
		.cfg_filter_rx_datasize_i(s_filter_rx_ch_cfg_datasize),
		.cfg_filter_rx_mode_i(s_filter_rx_ch_cfg_mode),
		.cfg_filter_rx_len0_i(s_filter_rx_ch_cfg_len0),
		.cfg_filter_rx_len1_i(s_filter_rx_ch_cfg_len1),
		.cfg_filter_rx_len2_i(s_filter_rx_ch_cfg_len2),
		.cfg_au_use_signed_i(s_au_cfg_use_signed),
		.cfg_au_bypass_i(s_au_cfg_bypass),
		.cfg_au_mode_i(s_au_cfg_mode),
		.cfg_au_shift_i(s_au_cfg_shift),
		.cfg_au_reg0_i(s_au_cfg_reg0),
		.cfg_au_reg1_i(s_au_cfg_reg1),
		.cfg_bincu_threshold_i(s_bincu_cfg_threshold),
		.cfg_bincu_counter_i(s_bincu_cfg_counter),
		.filter_tx_ch_req_o(s_filter_tx_ch_req),
		.filter_tx_ch_addr_o(s_filter_tx_ch_addr),
		.filter_tx_ch_datasize_o(s_filter_tx_ch_datasize),
		.filter_tx_ch_gnt_o(s_filter_tx_ch_gnt),
		.filter_tx_ch_valid_i(s_filter_tx_ch_valid),
		.filter_tx_ch_data_i(s_filter_tx_ch_data),
		.filter_tx_ch_ready_o(s_filter_tx_ch_ready),
		.filter_rx_ch_valid_o(s_filter_rx_ch_valid),
		.filter_rx_ch_addr_o(s_filter_rx_ch_addr),
		.filter_rx_ch_data_o(s_filter_rx_ch_data),
		.filter_rx_ch_datasize_o(s_filter_rx_ch_datasize),
		.filter_rx_ch_ready_i(s_filter_rx_ch_ready),
		.filter_id_i(s_filter_stream_id),
		.filter_data_i(s_filter_stream_data),
		.filter_datasize_i(2'b00),
		.filter_sof_i(s_filter_stream_sof),
		.filter_eof_i(s_filter_stream_eof),
		.filter_valid_i(s_filter_stream_valid),
		.filter_ready_o(s_filter_stream_ready)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 15; i = i + 1)
				if (i < N_PERIPHS) begin
					s_periph_ready[i] = periph_ready_i[i];
					s_periph_data_from = periph_data_from_i[i * 32+:32];
				end
				else begin
					s_periph_ready[i] = 1'b1;
					s_periph_data_from = 32'h00000000;
				end
		end
		s_periph_ready[15] = s_periph_ready_from_cgunit;
		s_periph_data_from[480+:32] = s_periph_data_from_cgunit;
	end
	udma_apb_if #(.APB_ADDR_WIDTH(APB_ADDR_WIDTH)) u_apb_if(
		.PADDR(PADDR),
		.PWDATA(PWDATA),
		.PWRITE(PWRITE),
		.PSEL(PSEL),
		.PENABLE(PENABLE),
		.PRDATA(PRDATA),
		.PREADY(PREADY),
		.PSLVERR(PSLVERR),
		.periph_data_o(s_periph_data_to),
		.periph_addr_o(s_periph_addr),
		.periph_data_i(s_periph_data_from),
		.periph_ready_i(s_periph_ready),
		.periph_valid_o(s_periph_valid),
		.periph_rwn_o(s_periph_rwn)
	);
	wire s_clk_core_en;
	udma_ctrl #(
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.TRANS_SIZE(TRANS_SIZE)
	) u_udma_ctrl(
		.clk_i(sys_clk_i),
		.rstn_i(HRESETn),
		.cfg_data_i(s_periph_data_to),
		.cfg_addr_i(s_periph_addr),
		.cfg_valid_i(s_periph_valid[15]),
		.cfg_rwn_i(s_periph_rwn),
		.cfg_data_o(s_periph_data_from_cgunit),
		.cfg_ready_o(s_periph_ready_from_cgunit),
		.cfg_filter_tx_start_addr_o(s_filter_tx_ch_cfg_start_addr),
		.cfg_filter_tx_datasize_o(s_filter_tx_ch_cfg_datasize),
		.cfg_filter_tx_mode_o(s_filter_tx_ch_cfg_mode),
		.cfg_filter_tx_len0_o(s_filter_tx_ch_cfg_len0),
		.cfg_filter_tx_len1_o(s_filter_tx_ch_cfg_len1),
		.cfg_filter_tx_len2_o(s_filter_tx_ch_cfg_len2),
		.cfg_filter_rx_start_addr_o(s_filter_rx_ch_cfg_start_addr),
		.cfg_filter_rx_datasize_o(s_filter_rx_ch_cfg_datasize),
		.cfg_filter_rx_mode_o(s_filter_rx_ch_cfg_mode),
		.cfg_filter_rx_len0_o(s_filter_rx_ch_cfg_len0),
		.cfg_filter_rx_len1_o(s_filter_rx_ch_cfg_len1),
		.cfg_filter_rx_len2_o(s_filter_rx_ch_cfg_len2),
		.cfg_filter_mode_o(s_filter_cfg_mode),
		.cfg_filter_start_o(s_filter_cfg_start),
		.cfg_au_use_signed_o(s_au_cfg_use_signed),
		.cfg_au_bypass_o(s_au_cfg_bypass),
		.cfg_au_mode_o(s_au_cfg_mode),
		.cfg_au_shift_o(s_au_cfg_shift),
		.cfg_au_reg0_o(s_au_cfg_reg0),
		.cfg_au_reg1_o(s_au_cfg_reg1),
		.cfg_bincu_threshold_o(s_bincu_cfg_threshold),
		.cfg_bincu_counter_o(s_bincu_cfg_counter),
		.cg_value_o(s_cg_value),
		.cg_core_o(s_clk_core_en),
		.rst_value_o(),
		.event_valid_i(event_valid_i),
		.event_data_i(event_data_i),
		.event_ready_o(event_ready_o),
		.event_o(event_o)
	);
	pulp_clock_gating i_clk_gate_sys_udma(
		.clk_i(sys_clk_i),
		.en_i(s_clk_core_en),
		.test_en_i(dft_cg_enable_i),
		.clk_o(s_clk_core)
	);
	pulp_clock_gating i_clk_gate_filter(
		.clk_i(s_clk_core),
		.en_i(s_cg_value[15]),
		.test_en_i(dft_cg_enable_i),
		.clk_o(s_clk_filter)
	);
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < N_PERIPHS; _gv_i_1 = _gv_i_1 + 1) begin : genblk1
			localparam i = _gv_i_1;
			pulp_clock_gating_async i_clk_gate_per(
				.clk_i(per_clk_i),
				.rstn_i(HRESETn),
				.en_async_i(s_cg_value[i]),
				.en_ack_o(),
				.test_en_i(dft_cg_enable_i),
				.clk_o(periph_per_clk_o[i])
			);
			pulp_clock_gating i_clk_gate_sys(
				.clk_i(s_clk_core),
				.en_i(s_cg_value[i]),
				.test_en_i(dft_cg_enable_i),
				.clk_o(periph_sys_clk_o[i])
			);
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
