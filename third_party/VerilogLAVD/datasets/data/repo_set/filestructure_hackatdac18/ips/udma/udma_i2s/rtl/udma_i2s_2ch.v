module udma_i2s_2ch (
	sys_clk_i,
	periph_clk_i,
	rstn_i,
	dft_test_mode_i,
	dft_cg_enable_i,
	ext_sd0_i,
	ext_sd1_i,
	ext_sck_i,
	ext_ws_i,
	ext_ws_o,
	ext_sck0_o,
	ext_ws0_o,
	ext_mode0_o,
	ext_sck1_o,
	ext_ws1_o,
	ext_mode1_o,
	cfg_data_i,
	cfg_addr_i,
	cfg_valid_i,
	cfg_rwn_i,
	cfg_ready_o,
	cfg_data_o,
	cfg_rx_ch0_startaddr_o,
	cfg_rx_ch0_size_o,
	cfg_rx_ch0_datasize_o,
	cfg_rx_ch0_continuous_o,
	cfg_rx_ch0_en_o,
	cfg_rx_ch0_clr_o,
	cfg_rx_ch0_en_i,
	cfg_rx_ch0_pending_i,
	cfg_rx_ch0_curr_addr_i,
	cfg_rx_ch0_bytes_left_i,
	cfg_rx_ch1_startaddr_o,
	cfg_rx_ch1_size_o,
	cfg_rx_ch1_datasize_o,
	cfg_rx_ch1_continuous_o,
	cfg_rx_ch1_en_o,
	cfg_rx_ch1_clr_o,
	cfg_rx_ch1_en_i,
	cfg_rx_ch1_pending_i,
	cfg_rx_ch1_curr_addr_i,
	cfg_rx_ch1_bytes_left_i,
	data_rx_ch0_datasize_o,
	data_rx_ch0_o,
	data_rx_ch0_valid_o,
	data_rx_ch0_ready_i,
	data_rx_ch1_datasize_o,
	data_rx_ch1_o,
	data_rx_ch1_valid_o,
	data_rx_ch1_ready_i
);
	parameter L2_AWIDTH_NOAL = 12;
	parameter TRANS_SIZE = 16;
	parameter BUFFER_WIDTH = 4;
	input wire sys_clk_i;
	input wire periph_clk_i;
	input wire rstn_i;
	input wire dft_test_mode_i;
	input wire dft_cg_enable_i;
	input wire ext_sd0_i;
	input wire ext_sd1_i;
	input wire ext_sck_i;
	input wire ext_ws_i;
	output wire ext_ws_o;
	output wire ext_sck0_o;
	output wire ext_ws0_o;
	output wire [1:0] ext_mode0_o;
	output wire ext_sck1_o;
	output wire ext_ws1_o;
	output wire [1:0] ext_mode1_o;
	input wire [31:0] cfg_data_i;
	input wire [4:0] cfg_addr_i;
	input wire cfg_valid_i;
	input wire cfg_rwn_i;
	output wire cfg_ready_o;
	output wire [31:0] cfg_data_o;
	output wire [L2_AWIDTH_NOAL - 1:0] cfg_rx_ch0_startaddr_o;
	output wire [TRANS_SIZE - 1:0] cfg_rx_ch0_size_o;
	output wire [1:0] cfg_rx_ch0_datasize_o;
	output wire cfg_rx_ch0_continuous_o;
	output wire cfg_rx_ch0_en_o;
	output wire cfg_rx_ch0_clr_o;
	input wire cfg_rx_ch0_en_i;
	input wire cfg_rx_ch0_pending_i;
	input wire [L2_AWIDTH_NOAL - 1:0] cfg_rx_ch0_curr_addr_i;
	input wire [TRANS_SIZE - 1:0] cfg_rx_ch0_bytes_left_i;
	output wire [L2_AWIDTH_NOAL - 1:0] cfg_rx_ch1_startaddr_o;
	output wire [TRANS_SIZE - 1:0] cfg_rx_ch1_size_o;
	output wire [1:0] cfg_rx_ch1_datasize_o;
	output wire cfg_rx_ch1_continuous_o;
	output wire cfg_rx_ch1_en_o;
	output wire cfg_rx_ch1_clr_o;
	input wire cfg_rx_ch1_en_i;
	input wire cfg_rx_ch1_pending_i;
	input wire [L2_AWIDTH_NOAL - 1:0] cfg_rx_ch1_curr_addr_i;
	input wire [TRANS_SIZE - 1:0] cfg_rx_ch1_bytes_left_i;
	output wire [1:0] data_rx_ch0_datasize_o;
	output wire [31:0] data_rx_ch0_o;
	output wire data_rx_ch0_valid_o;
	input wire data_rx_ch0_ready_i;
	output wire [1:0] data_rx_ch1_datasize_o;
	output wire [31:0] data_rx_ch1_o;
	output wire data_rx_ch1_valid_o;
	input wire data_rx_ch1_ready_i;
	localparam NUM_CHANNELS = 2;
	wire [3:0] s_cfg_ch_mode;
	wire [1:0] s_cfg_pdm_en;
	wire [1:0] s_cfg_pdm_usefilter;
	wire [1:0] s_cfg_pdm_update;
	wire [19:0] s_cfg_pdm_decimation;
	wire [5:0] s_cfg_pdm_shift;
	wire [1:0] s_cfg_useddr;
	wire [1:0] s_cfg_snap_cam;
	wire [1:0] s_cfg_lsb_first;
	wire [4:0] s_cfg_ext_bits_word;
	wire s_cfg0_gen_clk_en;
	wire s_cfg0_gen_clk_end;
	wire [15:0] s_cfg0_gen_clk_div;
	wire [4:0] s_cfg0_bits_word;
	wire s_cfg1_gen_clk_en;
	wire s_cfg1_gen_clk_end;
	wire [15:0] s_cfg1_gen_clk_div;
	wire [4:0] s_cfg1_bits_word;
	wire [63:0] s_fifo_data;
	wire [1:0] s_fifo_valid;
	wire [1:0] s_fifo_ready;
	wire [1:0] s_ext_sd;
	assign data_rx_ch0_o = s_fifo_data[0+:32];
	assign data_rx_ch1_o = s_fifo_data[32+:32];
	assign data_rx_ch0_valid_o = s_fifo_valid[0];
	assign data_rx_ch1_valid_o = s_fifo_valid[1];
	assign s_fifo_ready[0] = data_rx_ch0_ready_i;
	assign s_fifo_ready[1] = data_rx_ch1_ready_i;
	assign s_ext_sd[0] = ext_sd0_i;
	assign s_ext_sd[1] = ext_sd1_i;
	assign ext_mode0_o = s_cfg_ch_mode[0+:2];
	assign ext_mode1_o = s_cfg_ch_mode[2+:2];
	udma_i2s_reg_if #(
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.TRANS_SIZE(TRANS_SIZE),
		.NUM_CHANNELS(NUM_CHANNELS)
	) u_reg_if(
		.clk_i(sys_clk_i),
		.rstn_i(rstn_i),
		.cfg_data_i(cfg_data_i),
		.cfg_addr_i(cfg_addr_i),
		.cfg_valid_i(cfg_valid_i),
		.cfg_rwn_i(cfg_rwn_i),
		.cfg_ready_o(cfg_ready_o),
		.cfg_data_o(cfg_data_o),
		.cfg_rx_ch0_startaddr_o(cfg_rx_ch0_startaddr_o),
		.cfg_rx_ch0_size_o(cfg_rx_ch0_size_o),
		.cfg_rx_ch0_datasize_o(data_rx_ch0_datasize_o),
		.cfg_rx_ch0_continuous_o(cfg_rx_ch0_continuous_o),
		.cfg_rx_ch0_en_o(cfg_rx_ch0_en_o),
		.cfg_rx_ch0_clr_o(cfg_rx_ch0_clr_o),
		.cfg_rx_ch0_en_i(cfg_rx_ch0_en_i),
		.cfg_rx_ch0_pending_i(cfg_rx_ch0_pending_i),
		.cfg_rx_ch0_curr_addr_i(cfg_rx_ch0_curr_addr_i),
		.cfg_rx_ch0_bytes_left_i(cfg_rx_ch0_bytes_left_i),
		.cfg_rx_ch1_startaddr_o(cfg_rx_ch1_startaddr_o),
		.cfg_rx_ch1_size_o(cfg_rx_ch1_size_o),
		.cfg_rx_ch1_datasize_o(data_rx_ch1_datasize_o),
		.cfg_rx_ch1_continuous_o(cfg_rx_ch1_continuous_o),
		.cfg_rx_ch1_en_o(cfg_rx_ch1_en_o),
		.cfg_rx_ch1_clr_o(cfg_rx_ch1_clr_o),
		.cfg_rx_ch1_en_i(cfg_rx_ch1_en_i),
		.cfg_rx_ch1_pending_i(cfg_rx_ch1_pending_i),
		.cfg_rx_ch1_curr_addr_i(cfg_rx_ch1_curr_addr_i),
		.cfg_rx_ch1_bytes_left_i(cfg_rx_ch1_bytes_left_i),
		.cfg_i2s_ch_mode_o(s_cfg_ch_mode),
		.cfg_i2s_snap_cam_o(s_cfg_snap_cam),
		.cfg_i2s_useddr_o(s_cfg_useddr),
		.cfg_i2s_update_o(s_cfg_pdm_update),
		.cfg_i2s_decimation_o(s_cfg_pdm_decimation),
		.cfg_i2s_shift_o(s_cfg_pdm_shift),
		.cfg_i2s_pdm_en_o(s_cfg_pdm_en),
		.cfg_i2s_pdm_usefilter_o(s_cfg_pdm_usefilter),
		.cfg_i2s_lsb_first_o(s_cfg_lsb_first),
		.cfg_i2s_ext_bits_word_o(s_cfg_ext_bits_word),
		.cfg_i2s_0_gen_clk_en_o(s_cfg0_gen_clk_en),
		.cfg_i2s_0_gen_clk_en_i(s_cfg0_gen_clk_end),
		.cfg_i2s_0_gen_clk_div_o(s_cfg0_gen_clk_div),
		.cfg_i2s_0_bits_word_o(s_cfg0_bits_word),
		.cfg_i2s_1_gen_clk_en_o(s_cfg1_gen_clk_en),
		.cfg_i2s_1_gen_clk_en_i(s_cfg1_gen_clk_end),
		.cfg_i2s_1_gen_clk_div_o(s_cfg1_gen_clk_div),
		.cfg_i2s_1_bits_word_o(s_cfg1_bits_word)
	);
	udma_i2s_multich #(
		.NUM_CHANNELS(NUM_CHANNELS),
		.BUFFER_WIDTH(4)
	) u_i2s_multich(
		.sys_clk_i(sys_clk_i),
		.periph_clk_i(periph_clk_i),
		.rstn_i(rstn_i),
		.dft_test_mode_i(dft_test_mode_i),
		.dft_cg_enable_i(dft_cg_enable_i),
		.ext_sd_i(s_ext_sd),
		.ext_sck_i(ext_sck_i),
		.ext_ws_i(ext_ws_i),
		.ext_ws_o(ext_ws_o),
		.ext_sck0_o(ext_sck0_o),
		.ext_ws0_o(ext_ws0_o),
		.ext_sck1_o(ext_sck1_o),
		.ext_ws1_o(ext_ws1_o),
		.fifo_data_o(s_fifo_data),
		.fifo_data_valid_o(s_fifo_valid),
		.fifo_data_ready_i(s_fifo_ready),
		.cfg_ch_mode_i(s_cfg_ch_mode),
		.cfg_pdm_en_i(s_cfg_pdm_en),
		.cfg_pdm_usefilter_i(s_cfg_pdm_usefilter),
		.cfg_pdm_update_i(s_cfg_pdm_update),
		.cfg_pdm_decimation_i(s_cfg_pdm_decimation),
		.cfg_pdm_shift_i(s_cfg_pdm_shift),
		.cfg_useddr_i(s_cfg_useddr),
		.cfg_snap_cam_i(s_cfg_snap_cam),
		.cfg_lsb_first_i(s_cfg_lsb_first),
		.cfg_ext_bits_word_i(s_cfg_ext_bits_word),
		.cfg0_gen_clk_en_i(s_cfg0_gen_clk_en),
		.cfg0_gen_clk_en_o(s_cfg0_gen_clk_end),
		.cfg0_gen_clk_div_i(s_cfg0_gen_clk_div),
		.cfg0_bits_word_i(s_cfg0_bits_word),
		.cfg1_gen_clk_en_i(s_cfg1_gen_clk_en),
		.cfg1_gen_clk_en_o(s_cfg1_gen_clk_end),
		.cfg1_gen_clk_div_i(s_cfg1_gen_clk_div),
		.cfg1_bits_word_i(s_cfg1_bits_word),
		.fifo_err_o(),
		.fifo_err_clr_i(1'sb0)
	);
endmodule
