module i2s_rx (
	clk_i,
	rstn_i,
	ext_sd_i,
	ext_sck0_o,
	ext_ws0_o,
	ext_sck1_o,
	ext_ws1_o,
	fifo_data_o,
	fifo_data_valid_o,
	fifo_data_ready_i,
	fifo_err_o,
	fifo_err_clr_i,
	cfg_select_i,
	cfg_enable_i,
	cfg0_pdm_en_i,
	cfg0_pdm_ddr_i,
	cfg0_lsbfirst_i,
	cfg0_sample_word_i,
	cfg0_gen_clk_en_i,
	cfg0_gen_clk_div_i,
	cfg0_bits_word_i,
	cfg0_ws_time_i,
	cfg0_ws_value_i,
	cfg0_ws_fix_i,
	cfg1_pdm_en_i,
	cfg1_pdm_ddr_i,
	cfg1_lsbfirst_i,
	cfg1_sample_word_i,
	cfg1_gen_clk_en_i,
	cfg1_gen_clk_div_i,
	cfg1_bits_word_i,
	cfg1_ws_time_i,
	cfg1_ws_value_i,
	cfg1_ws_fix_i
);
	reg _sv2v_0;
	parameter NUM_CHANNELS = 1;
	input wire clk_i;
	input wire rstn_i;
	input wire [NUM_CHANNELS - 1:0] ext_sd_i;
	output wire ext_sck0_o;
	output reg ext_ws0_o;
	output wire ext_sck1_o;
	output reg ext_ws1_o;
	output wire [(NUM_CHANNELS * 32) - 1:0] fifo_data_o;
	output wire [NUM_CHANNELS - 1:0] fifo_data_valid_o;
	input wire [NUM_CHANNELS - 1:0] fifo_data_ready_i;
	input wire [NUM_CHANNELS - 1:0] fifo_err_o;
	output wire [NUM_CHANNELS - 1:0] fifo_err_clr_i;
	input wire [NUM_CHANNELS - 1:0] cfg_select_i;
	input wire [NUM_CHANNELS - 1:0] cfg_enable_i;
	input wire cfg0_pdm_en_i;
	input wire cfg0_pdm_ddr_i;
	input wire cfg0_lsbfirst_i;
	input wire cfg0_sample_word_i;
	input wire cfg0_gen_clk_en_i;
	input wire [10:0] cfg0_gen_clk_div_i;
	input wire [5:0] cfg0_bits_word_i;
	input wire [5:0] cfg0_ws_time_i;
	input wire cfg0_ws_value_i;
	input wire cfg0_ws_fix_i;
	input wire cfg1_pdm_en_i;
	input wire cfg1_pdm_ddr_i;
	input wire cfg1_lsbfirst_i;
	input wire cfg1_sample_word_i;
	input wire cfg1_gen_clk_en_i;
	input wire [10:0] cfg1_gen_clk_div_i;
	input wire [5:0] cfg1_bits_word_i;
	input wire [5:0] cfg1_ws_time_i;
	input wire cfg1_ws_value_i;
	input wire cfg1_ws_fix_i;
	genvar _gv_i_1;
	wire s_en_clkgen;
	wire s_fall0;
	wire s_rise0;
	wire s_fall1;
	wire s_rise1;
	reg [NUM_CHANNELS - 1:0] s_shift;
	reg [NUM_CHANNELS - 1:0] s_cfg_enable;
	reg [NUM_CHANNELS - 1:0] r_datavalid;
	reg [NUM_CHANNELS - 1:0] r_error;
	wire s_shift_fifow0;
	wire s_shift_fifow1;
	wire s_dataready0;
	wire s_dataready1;
	wire s_32bitsready0;
	wire s_32bitsready1;
	wire s_wordready0;
	wire s_wordready1;
	wire [5:0] s_bitcount;
	wire [5:0] s_bitcountword;
	wire [5:0] s_bitcountreg;
	reg s_shift0;
	reg s_shift1;
	reg [NUM_CHANNELS - 1:0] s_cfg_lsbfirst;
	wire s_bitcount1;
	wire s_bitcount0;
	wire s_bitcountword1;
	wire s_bitcountword0;
	wire s_bitcountreg0;
	wire s_bitcountreg1;
	assign s_shift_fifow0 = (cfg0_pdm_en_i || !cfg0_sample_word_i ? s_shift0 : 1'b0);
	assign s_dataready0 = (cfg0_pdm_en_i || !cfg0_sample_word_i ? s_32bitsready0 : s_wordready0);
	assign s_bitcount0 = (cfg0_pdm_en_i || !cfg0_sample_word_i ? s_bitcountword0 : s_bitcountreg0);
	assign s_shift_fifow1 = (cfg1_pdm_en_i || !cfg1_sample_word_i ? s_shift1 : 1'b0);
	assign s_dataready1 = (cfg1_pdm_en_i || !cfg1_sample_word_i ? s_32bitsready1 : s_wordready1);
	assign s_bitcount1 = (cfg1_pdm_en_i || !cfg1_sample_word_i ? s_bitcountword1 : s_bitcountreg1);
	wire s_cfg0_enable;
	assign s_cfg0_enable = |(cfg_enable_i & ~cfg_select_i);
	wire s_cfg1_enable;
	assign s_cfg1_enable = |(cfg_enable_i & cfg_select_i);
	wire cfg_gen0_clk_div_i;
	io_clk_gen #(.COUNTER_WIDTH(11)) i_clk_gen0(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.en_i(s_cfg0_enable),
		.clk_div_i(cfg_gen0_clk_div_i),
		.clk_o(ext_sck0_o),
		.fall_o(s_fall0),
		.rise_o(s_rise0)
	);
	io_event_counter #(.COUNTER_WIDTH(6)) i_bit_counter0(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.event_i(s_shift0),
		.counter_rst_i(~s_cfg0_enable),
		.counter_target_i(cfg0_bits_word_i),
		.counter_value_o(s_bitcountreg0),
		.counter_trig_o(s_wordready0)
	);
	io_event_counter #(.COUNTER_WIDTH(6)) i_fifow_counter0(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.event_i(s_shift_fifow0),
		.counter_rst_i(~s_cfg0_enable),
		.counter_target_i(6'd32),
		.counter_value_o(s_bitcountword0),
		.counter_trig_o(s_32bitsready0)
	);
	io_clk_gen #(.COUNTER_WIDTH(11)) i_clk_gen1(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.en_i(s_cfg1_enable),
		.clk_div_i(cfg1_gen_clk_div_i),
		.clk_o(ext_sck1_o),
		.fall_o(s_fall1),
		.rise_o(s_rise1)
	);
	io_event_counter #(.COUNTER_WIDTH(6)) i_bit_counter1(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.event_i(s_shift1),
		.counter_rst_i(~s_cfg1_enable),
		.counter_target_i(cfg1_bits_word_i),
		.counter_value_o(s_bitcountreg1),
		.counter_trig_o(s_wordready1)
	);
	io_event_counter #(.COUNTER_WIDTH(6)) i_fifow_counter1(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.event_i(s_shift_fifow1),
		.counter_rst_i(~s_cfg1_enable),
		.counter_target_i(6'd32),
		.counter_value_o(s_bitcountword1),
		.counter_trig_o(s_32bitsready1)
	);
	generate
		for (_gv_i_1 = 0; _gv_i_1 < NUM_CHANNELS; _gv_i_1 = _gv_i_1 + 1) begin : genblk1
			localparam i = _gv_i_1;
			io_shiftreg #(.DATA_WIDTH(32)) i_shiftreg(
				.clk_i(clk_i),
				.rstn_i(rstn_i),
				.data_i(32'h00000000),
				.data_o(fifo_data_o[i * 32+:32]),
				.serial_i(ext_sd_i[i]),
				.serial_o(),
				.load_i(~cfg_enable_i[i]),
				.shift_i(s_shift[i]),
				.lsbfirst_i(s_cfg_lsbfirst[i])
			);
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < NUM_CHANNELS; i = i + 1)
				if (cfg_select_i[i]) begin
					s_shift[i] = s_shift1 & cfg_enable_i[i];
					s_cfg_enable[i] = s_cfg1_enable;
					s_cfg_lsbfirst[i] = cfg1_lsbfirst_i;
				end
				else begin
					s_shift[i] = s_shift0 & cfg_enable_i[i];
					s_cfg_enable[i] = s_cfg0_enable;
					s_cfg_lsbfirst[i] = cfg0_lsbfirst_i;
				end
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (cfg0_pdm_en_i && cfg0_pdm_ddr_i)
			s_shift0 = s_fall0 | s_rise0;
		else
			s_shift0 = s_rise0;
		if (cfg1_pdm_en_i && cfg1_pdm_ddr_i)
			s_shift1 = s_fall1 | s_rise1;
		else
			s_shift1 = s_rise1;
	end
	always @(posedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0) begin
			r_datavalid <= 'h0;
			r_error <= 'h0;
		end
		else begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < NUM_CHANNELS; i = i + 1)
				begin
					if (fifo_err_clr_i[i])
						r_error[i] <= 1'b0;
					else if (((cfg_enable_i[i] && r_datavalid[i]) && ~fifo_data_ready_i[i]) && s_shift[i])
						r_error[i] <= 1'b1;
					if (cfg_enable_i[i]) begin
						if (r_datavalid[i]) begin
							if (fifo_data_ready_i[i]) begin
								if ((cfg_select_i[i] & ~s_dataready1) || (~cfg_select_i[i] & ~s_dataready0))
									r_datavalid[i] <= 1'b0;
							end
						end
						else if (cfg_select_i[i])
							r_datavalid[i] <= s_dataready1;
						else
							r_datavalid[i] <= s_dataready0;
					end
					else
						r_datavalid[i] <= 1'b0;
				end
		end
	always @(posedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0)
			ext_ws0_o <= 1'b0;
		else if (s_cfg0_enable) begin
			if (cfg0_ws_fix_i)
				ext_ws0_o <= cfg0_ws_value_i;
			else if ((s_bitcount0 == cfg0_ws_time_i) && s_fall0)
				ext_ws0_o <= ~ext_ws0_o;
		end
		else
			ext_ws0_o <= 1'b0;
	always @(posedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0)
			ext_ws1_o <= 1'b0;
		else if (s_cfg1_enable) begin
			if (cfg1_ws_fix_i)
				ext_ws1_o <= cfg1_ws_value_i;
			else if ((s_bitcount1 == cfg1_ws_time_i) && s_fall1)
				ext_ws1_o <= ~ext_ws1_o;
		end
		else
			ext_ws1_o <= 1'b0;
	assign fifo_data_valid_o = r_datavalid;
	initial _sv2v_0 = 0;
endmodule
