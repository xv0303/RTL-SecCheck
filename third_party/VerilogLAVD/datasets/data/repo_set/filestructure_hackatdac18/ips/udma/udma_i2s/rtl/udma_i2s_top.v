module udma_i2s_top (
	clk_i,
	rstn_i,
	ext_sd_i,
	ext_sck_i,
	ext_ws_i,
	ext_ws_o,
	ext_sck0_o,
	ext_ws0_o,
	ext_sck1_o,
	ext_ws1_o,
	fifo_data_o,
	fifo_data_valid_o,
	fifo_data_ready_i,
	fifo_err_o,
	fifo_err_clr_i,
	cfg_ch_mode_i,
	cfg_pdm_en_i,
	cfg_pdm_usefilter_i,
	cfg_pdm_decimation_i,
	cfg_pdm_shift_i,
	cfg_useddr_i,
	cfg_snap_cam_i,
	cfg_lsb_first_i,
	cfg_ext_bits_word_i,
	cfg0_gen_clk_en_i,
	cfg0_gen_clk_div_i,
	cfg0_bits_word_i,
	cfg1_gen_clk_en_i,
	cfg1_gen_clk_div_i,
	cfg1_bits_word_i
);
	reg _sv2v_0;
	parameter NUM_CHANNELS = 4;
	parameter BUFFER_WIDTH = 4;
	input wire clk_i;
	input wire rstn_i;
	input wire [NUM_CHANNELS - 1:0] ext_sd_i;
	input wire ext_sck_i;
	input wire ext_ws_i;
	output wire ext_ws_o;
	output wire ext_sck0_o;
	output wire ext_ws0_o;
	output wire ext_sck1_o;
	output wire ext_ws1_o;
	output wire [(NUM_CHANNELS * 32) - 1:0] fifo_data_o;
	output wire [NUM_CHANNELS - 1:0] fifo_data_valid_o;
	input wire [NUM_CHANNELS - 1:0] fifo_data_ready_i;
	output wire [NUM_CHANNELS - 1:0] fifo_err_o;
	input wire [NUM_CHANNELS - 1:0] fifo_err_clr_i;
	input wire [(NUM_CHANNELS * 2) - 1:0] cfg_ch_mode_i;
	input wire [NUM_CHANNELS - 1:0] cfg_pdm_en_i;
	input wire [NUM_CHANNELS - 1:0] cfg_pdm_usefilter_i;
	input wire [(NUM_CHANNELS * 10) - 1:0] cfg_pdm_decimation_i;
	input wire [(NUM_CHANNELS * 3) - 1:0] cfg_pdm_shift_i;
	input wire [NUM_CHANNELS - 1:0] cfg_useddr_i;
	input wire [NUM_CHANNELS - 1:0] cfg_snap_cam_i;
	input wire [NUM_CHANNELS - 1:0] cfg_lsb_first_i;
	input wire [4:0] cfg_ext_bits_word_i;
	input wire cfg0_gen_clk_en_i;
	input wire [15:0] cfg0_gen_clk_div_i;
	input wire [4:0] cfg0_bits_word_i;
	input wire cfg1_gen_clk_en_i;
	input wire [15:0] cfg1_gen_clk_div_i;
	input wire [4:0] cfg1_bits_word_i;
	genvar _gv_i_1;
	integer j;
	wire s_ws_gen_ext_en;
	wire s_ws_gen_ext;
	wire s_int_sck0;
	wire s_ws_gen_cfg0;
	wire s_int_sck1;
	wire s_ws_gen_cfg1;
	reg [(NUM_CHANNELS * 2) - 1:0] s_channel_sel;
	reg [NUM_CHANNELS - 1:0] s_clkintsel;
	wire [NUM_CHANNELS - 1:0] s_clkint;
	wire [NUM_CHANNELS - 1:0] s_sck;
	reg [NUM_CHANNELS - 1:0] s_clksel;
	reg [NUM_CHANNELS - 1:0] s_ws;
	wire [(NUM_CHANNELS * 32) - 1:0] s_fifo_data;
	wire [NUM_CHANNELS - 1:0] s_fifo_data_valid;
	wire [NUM_CHANNELS - 1:0] s_fifo_data_ready;
	wire [(NUM_CHANNELS * 32) - 1:0] s_dc_data_async;
	wire [(NUM_CHANNELS * BUFFER_WIDTH) - 1:0] s_dc_writetoken;
	wire [(NUM_CHANNELS * BUFFER_WIDTH) - 1:0] s_dc_readpointer;
	i2s_ws_gen u_ws_gen_ext(
		.sck_i(ext_sck_i),
		.rstn_i(rstn_i),
		.ws_o(s_ws_gen_ext),
		.cfg_ws_en_i(1'b1),
		.cfg_data_size_i(cfg_ext_bits_word_i)
	);
	assign ext_ws_o = s_ws_gen_ext;
	i2s_clk_gen u_clkgen_cfg0(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.sck_o(s_int_sck0),
		.cfg_clk_en_i(cfg0_gen_clk_en_i),
		.cfg_semiperiod_cycles_i(cfg0_gen_clk_div_i)
	);
	assign ext_sck0_o = s_int_sck0;
	i2s_ws_gen u_ws_gen_cfg0(
		.sck_i(s_int_sck0),
		.rstn_i(rstn_i),
		.ws_o(s_ws_gen_cfg0),
		.cfg_ws_en_i(cfg0_gen_clk_en_i),
		.cfg_data_size_i(cfg0_bits_word_i)
	);
	assign ext_ws0_o = s_ws_gen_cfg0;
	i2s_clk_gen u_clkgen_cfg1(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.sck_o(s_int_sck1),
		.cfg_clk_en_i(cfg1_gen_clk_en_i),
		.cfg_semiperiod_cycles_i(cfg1_gen_clk_div_i)
	);
	assign ext_sck1_o = s_int_sck1;
	i2s_ws_gen u_ws_gen_cfg1(
		.sck_i(s_int_sck1),
		.rstn_i(rstn_i),
		.ws_o(s_ws_gen_cfg1),
		.cfg_ws_en_i(cfg1_gen_clk_en_i),
		.cfg_data_size_i(cfg1_bits_word_i)
	);
	assign ext_ws1_o = s_ws_gen_cfg1;
	always @(*) begin
		if (_sv2v_0)
			;
		for (j = 0; j < NUM_CHANNELS; j = j + 1)
			begin
				s_channel_sel[j * 2+:2] = cfg_ch_mode_i[j * 2+:2];
				case (s_channel_sel[j * 2+:2])
					2'b00: begin
						s_clkintsel[j] = 1'b0;
						s_clksel[j] = 1'b1;
						s_ws[j] = s_ws_gen_cfg0;
					end
					2'b01: begin
						s_clkintsel[j] = 1'b1;
						s_clksel[j] = 1'b1;
						s_ws[j] = s_ws_gen_cfg1;
					end
					2'b10: begin
						s_clkintsel[j] = 1'b0;
						s_clksel[j] = 1'b0;
						s_ws[j] = s_ws_gen_ext;
					end
					2'b11: begin
						s_clkintsel[j] = 1'b0;
						s_clksel[j] = 1'b0;
						s_ws[j] = ext_ws_i;
					end
				endcase
			end
	end
	generate
		for (_gv_i_1 = 0; _gv_i_1 < NUM_CHANNELS; _gv_i_1 = _gv_i_1 + 1) begin : genblk1
			localparam i = _gv_i_1;
			pulp_clock_mux2 u_clkselint(
				.clk0_i(s_int_sck0),
				.clk1_i(s_int_sck1),
				.clk_sel_i(s_clkintsel[i]),
				.clk_o(s_clkint[i])
			);
			pulp_clock_mux2 u_clksel(
				.clk0_i(ext_sck_i),
				.clk1_i(s_clkint[i]),
				.clk_sel_i(s_clksel[i]),
				.clk_o(s_sck[i])
			);
		end
		for (_gv_i_1 = 0; _gv_i_1 < NUM_CHANNELS; _gv_i_1 = _gv_i_1 + 1) begin : genblk2
			localparam i = _gv_i_1;
			i2s_rx_channel u_channel(
				.sck_i(s_sck[i]),
				.rstn_i(rstn_i),
				.sd_i(ext_sd_i[i]),
				.ws_i(s_ws[i]),
				.fifo_data_o(s_fifo_data[i * 32+:32]),
				.fifo_data_valid_o(s_fifo_data_valid[i]),
				.fifo_data_ready_i(s_fifo_data_ready[i]),
				.fifo_err_o(),
				.fifo_err_clr_i(),
				.cfg_pdm_en_i(cfg_pdm_en_i[i]),
				.cfg_pdm_usefilter_i(cfg_pdm_usefilter_i[i]),
				.cfg_decimation_i(cfg_pdm_decimation_i[i * 10+:10]),
				.cfg_shift_i(cfg_pdm_shift_i[i * 3+:3]),
				.cfg_snap_cam_i(cfg_snap_cam_i[i]),
				.cfg_lsb_first_i(cfg_lsb_first_i[i]),
				.cfg_pdm_ddr_i(cfg_useddr_i[i])
			);
		end
		for (_gv_i_1 = 0; _gv_i_1 < NUM_CHANNELS; _gv_i_1 = _gv_i_1 + 1) begin : genblk3
			localparam i = _gv_i_1;
			dc_token_ring_fifo_dout #(
				32,
				BUFFER_WIDTH
			) u_dc_out(
				.clk(clk_i),
				.rstn(rstn_i),
				.data(fifo_data_o[i * 32+:32]),
				.valid(fifo_data_valid_o[i]),
				.ready(fifo_data_ready_i[i]),
				.write_token(s_dc_writetoken[i * BUFFER_WIDTH+:BUFFER_WIDTH]),
				.read_pointer(s_dc_readpointer[i * BUFFER_WIDTH+:BUFFER_WIDTH]),
				.data_async(s_dc_data_async[i * 32+:32])
			);
		end
		for (_gv_i_1 = 0; _gv_i_1 < NUM_CHANNELS; _gv_i_1 = _gv_i_1 + 1) begin : genblk4
			localparam i = _gv_i_1;
			dc_token_ring_fifo_din #(
				32,
				BUFFER_WIDTH
			) u_dc_in(
				.clk(s_sck[i]),
				.rstn(rstn_i),
				.data(s_fifo_data[i * 32+:32]),
				.valid(s_fifo_data_valid[i]),
				.ready(s_fifo_data_ready[i]),
				.write_token(s_dc_writetoken[i * BUFFER_WIDTH+:BUFFER_WIDTH]),
				.read_pointer(s_dc_readpointer[i * BUFFER_WIDTH+:BUFFER_WIDTH]),
				.data_async(s_dc_data_async[i * 32+:32])
			);
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
