module udma_i2s_reg_if (
	clk_i,
	rstn_i,
	cfg_data_i,
	cfg_addr_i,
	cfg_valid_i,
	cfg_rwn_i,
	cfg_data_o,
	cfg_ready_o,
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
	cfg_i2s_ch_mode_o,
	cfg_i2s_snap_cam_o,
	cfg_i2s_useddr_o,
	cfg_i2s_update_o,
	cfg_i2s_decimation_o,
	cfg_i2s_shift_o,
	cfg_i2s_pdm_en_o,
	cfg_i2s_pdm_usefilter_o,
	cfg_i2s_lsb_first_o,
	cfg_i2s_ext_bits_word_o,
	cfg_i2s_0_gen_clk_en_o,
	cfg_i2s_0_gen_clk_en_i,
	cfg_i2s_0_gen_clk_div_o,
	cfg_i2s_0_bits_word_o,
	cfg_i2s_1_gen_clk_en_o,
	cfg_i2s_1_gen_clk_en_i,
	cfg_i2s_1_gen_clk_div_o,
	cfg_i2s_1_bits_word_o
);
	reg _sv2v_0;
	parameter L2_AWIDTH_NOAL = 12;
	parameter TRANS_SIZE = 16;
	parameter NUM_CHANNELS = 4;
	input wire clk_i;
	input wire rstn_i;
	input wire [31:0] cfg_data_i;
	input wire [4:0] cfg_addr_i;
	input wire cfg_valid_i;
	input wire cfg_rwn_i;
	output reg [31:0] cfg_data_o;
	output wire cfg_ready_o;
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
	output reg [(NUM_CHANNELS * 2) - 1:0] cfg_i2s_ch_mode_o;
	output reg [NUM_CHANNELS - 1:0] cfg_i2s_snap_cam_o;
	output reg [NUM_CHANNELS - 1:0] cfg_i2s_useddr_o;
	output reg [NUM_CHANNELS - 1:0] cfg_i2s_update_o;
	output reg [(NUM_CHANNELS * 10) - 1:0] cfg_i2s_decimation_o;
	output reg [(NUM_CHANNELS * 3) - 1:0] cfg_i2s_shift_o;
	output reg [NUM_CHANNELS - 1:0] cfg_i2s_pdm_en_o;
	output reg [NUM_CHANNELS - 1:0] cfg_i2s_pdm_usefilter_o;
	output reg [NUM_CHANNELS - 1:0] cfg_i2s_lsb_first_o;
	output wire [4:0] cfg_i2s_ext_bits_word_o;
	output wire cfg_i2s_0_gen_clk_en_o;
	input wire cfg_i2s_0_gen_clk_en_i;
	output wire [15:0] cfg_i2s_0_gen_clk_div_o;
	output wire [4:0] cfg_i2s_0_bits_word_o;
	output wire cfg_i2s_1_gen_clk_en_o;
	input wire cfg_i2s_1_gen_clk_en_i;
	output wire [15:0] cfg_i2s_1_gen_clk_div_o;
	output wire [4:0] cfg_i2s_1_bits_word_o;
	localparam MAX_CHANNELS = 4;
	reg [L2_AWIDTH_NOAL - 1:0] r_rx_ch0_startaddr;
	reg [TRANS_SIZE - 1:0] r_rx_ch0_size;
	reg [1:0] r_rx_ch0_datasize;
	reg r_rx_ch0_continuous;
	reg r_rx_ch0_en;
	reg r_rx_ch0_clr;
	reg [L2_AWIDTH_NOAL - 1:0] r_rx_ch1_startaddr;
	reg [TRANS_SIZE - 1:0] r_rx_ch1_size;
	reg [1:0] r_rx_ch1_datasize;
	reg r_rx_ch1_continuous;
	reg r_rx_ch1_en;
	reg r_rx_ch1_clr;
	reg [7:0] r_i2s_ch_mode;
	reg [3:0] r_i2s_snap_cam;
	reg [3:0] r_i2s_useddr;
	reg [3:0] r_i2s_update;
	reg [39:0] r_i2s_decimation;
	reg [11:0] r_i2s_shift;
	reg [3:0] r_i2s_pdm_en;
	reg [3:0] r_i2s_pdm_usefilter;
	reg [3:0] r_i2s_lsb_first;
	reg [4:0] r_i2s_ext_bits_word;
	reg r_i2s_cfg0_clk_en;
	reg [15:0] r_i2s_cfg0_clk_div;
	reg [4:0] r_i2s_cfg0_bits_word;
	reg r_i2s_cfg1_clk_en;
	reg [15:0] r_i2s_cfg1_clk_div;
	reg [4:0] r_i2s_cfg1_bits_word;
	wire [4:0] s_wr_addr;
	wire [4:0] s_rd_addr;
	assign s_wr_addr = (cfg_valid_i & ~cfg_rwn_i ? cfg_addr_i : 5'h00);
	assign s_rd_addr = (cfg_valid_i & cfg_rwn_i ? cfg_addr_i : 5'h00);
	assign cfg_rx_ch0_startaddr_o = r_rx_ch0_startaddr;
	assign cfg_rx_ch0_size_o = r_rx_ch0_size;
	assign cfg_rx_ch0_datasize_o = r_rx_ch0_datasize;
	assign cfg_rx_ch0_continuous_o = r_rx_ch0_continuous;
	assign cfg_rx_ch0_en_o = r_rx_ch0_en;
	assign cfg_rx_ch0_clr_o = r_rx_ch0_clr;
	assign cfg_rx_ch1_startaddr_o = r_rx_ch1_startaddr;
	assign cfg_rx_ch1_size_o = r_rx_ch1_size;
	assign cfg_rx_ch1_datasize_o = r_rx_ch1_datasize;
	assign cfg_rx_ch1_continuous_o = r_rx_ch1_continuous;
	assign cfg_rx_ch1_en_o = r_rx_ch1_en;
	assign cfg_rx_ch1_clr_o = r_rx_ch1_clr;
	always @(*) begin : proc_outs
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < NUM_CHANNELS; i = i + 1)
				begin
					cfg_i2s_ch_mode_o[i * 2+:2] = r_i2s_ch_mode[i * 2+:2];
					cfg_i2s_useddr_o[i] = r_i2s_useddr[i];
					cfg_i2s_update_o[i] = r_i2s_update[i];
					cfg_i2s_decimation_o[i * 10+:10] = r_i2s_decimation[i * 10+:10];
					cfg_i2s_shift_o[i * 3+:3] = r_i2s_shift[i * 3+:3];
					cfg_i2s_pdm_en_o[i] = r_i2s_pdm_en[i];
					cfg_i2s_pdm_usefilter_o[i] = r_i2s_pdm_usefilter[i];
					cfg_i2s_snap_cam_o[i] = r_i2s_snap_cam[i];
					cfg_i2s_lsb_first_o[i] = r_i2s_lsb_first[i];
				end
		end
	end
	assign cfg_i2s_ext_bits_word_o = r_i2s_ext_bits_word;
	assign cfg_i2s_0_gen_clk_en_o = r_i2s_cfg0_clk_en;
	assign cfg_i2s_0_gen_clk_div_o = r_i2s_cfg0_clk_div;
	assign cfg_i2s_0_bits_word_o = r_i2s_cfg0_bits_word;
	assign cfg_i2s_1_gen_clk_en_o = r_i2s_cfg1_clk_en;
	assign cfg_i2s_1_gen_clk_div_o = r_i2s_cfg1_clk_div;
	assign cfg_i2s_1_bits_word_o = r_i2s_cfg1_bits_word;
	always @(posedge clk_i or negedge rstn_i)
		if (~rstn_i) begin
			r_rx_ch0_startaddr <= 'h0;
			r_rx_ch0_size <= 'h0;
			r_rx_ch0_datasize <= 'h2;
			r_rx_ch0_continuous <= 'h0;
			r_rx_ch0_en = 'h0;
			r_rx_ch0_clr = 'h0;
			r_rx_ch1_startaddr <= 'h0;
			r_rx_ch1_size <= 'h0;
			r_rx_ch1_datasize <= 'h2;
			r_rx_ch1_continuous <= 'h0;
			r_rx_ch1_en = 'h0;
			r_rx_ch1_clr = 'h0;
			r_i2s_ch_mode <= 'h0;
			r_i2s_useddr <= 'h0;
			r_i2s_update = 'h0;
			r_i2s_decimation <= 'h0;
			r_i2s_shift <= 'h0;
			r_i2s_pdm_en <= 'h0;
			r_i2s_pdm_usefilter <= 'h0;
			r_i2s_snap_cam <= 'h0;
			r_i2s_lsb_first <= 'h0;
			r_i2s_ext_bits_word <= 'h0;
			r_i2s_cfg0_clk_en <= 'h0;
			r_i2s_cfg0_clk_div <= 'h0;
			r_i2s_cfg0_bits_word <= 'h0;
			r_i2s_cfg1_clk_en <= 'h0;
			r_i2s_cfg1_clk_div <= 'h0;
			r_i2s_cfg1_bits_word <= 'h0;
		end
		else begin
			r_rx_ch0_en = 'h0;
			r_rx_ch0_clr = 'h0;
			r_rx_ch1_en = 'h0;
			r_rx_ch1_clr = 'h0;
			r_i2s_update[0] = 1'b0;
			r_i2s_update[1] = 1'b0;
			if (cfg_valid_i & ~cfg_rwn_i)
				case (s_wr_addr)
					5'b00000: r_rx_ch0_startaddr <= cfg_data_i[L2_AWIDTH_NOAL - 1:0];
					5'b00001: r_rx_ch0_size <= cfg_data_i[TRANS_SIZE - 1:0];
					5'b00010: begin
						r_rx_ch0_clr = cfg_data_i[5];
						r_rx_ch0_en = cfg_data_i[4];
						r_rx_ch0_datasize <= cfg_data_i[2:1];
						r_rx_ch0_continuous <= cfg_data_i[0];
					end
					5'b00100: r_rx_ch1_startaddr <= cfg_data_i[L2_AWIDTH_NOAL - 1:0];
					5'b00101: r_rx_ch1_size <= cfg_data_i[TRANS_SIZE - 1:0];
					5'b00110: begin
						r_rx_ch1_clr = cfg_data_i[5];
						r_rx_ch1_en = cfg_data_i[4];
						r_rx_ch1_datasize <= cfg_data_i[2:1];
						r_rx_ch1_continuous <= cfg_data_i[0];
					end
					5'b01011: begin
						r_i2s_ch_mode[0+:2] <= cfg_data_i[25:24];
						r_i2s_useddr[0] <= cfg_data_i[16];
						r_i2s_pdm_en[0] <= cfg_data_i[12];
						r_i2s_pdm_usefilter[0] <= cfg_data_i[8];
						r_i2s_lsb_first[0] <= cfg_data_i[4];
						r_i2s_snap_cam[0] <= cfg_data_i[0];
						r_i2s_ch_mode[2+:2] <= cfg_data_i[27:26];
						r_i2s_useddr[1] <= cfg_data_i[17];
						r_i2s_pdm_en[1] <= cfg_data_i[13];
						r_i2s_pdm_usefilter[1] <= cfg_data_i[9];
						r_i2s_lsb_first[1] <= cfg_data_i[5];
						r_i2s_snap_cam[1] <= cfg_data_i[1];
						r_i2s_ch_mode[4+:2] <= cfg_data_i[29:28];
						r_i2s_useddr[2] <= cfg_data_i[18];
						r_i2s_pdm_en[2] <= cfg_data_i[14];
						r_i2s_pdm_usefilter[2] <= cfg_data_i[10];
						r_i2s_lsb_first[2] <= cfg_data_i[6];
						r_i2s_snap_cam[2] <= cfg_data_i[2];
						r_i2s_ch_mode[6+:2] <= cfg_data_i[31:30];
						r_i2s_useddr[3] <= cfg_data_i[19];
						r_i2s_pdm_en[3] <= cfg_data_i[15];
						r_i2s_pdm_usefilter[3] <= cfg_data_i[11];
						r_i2s_lsb_first[3] <= cfg_data_i[7];
						r_i2s_snap_cam[3] <= cfg_data_i[3];
					end
					5'b01100: begin
						r_i2s_update[0] = 1'b1;
						r_i2s_decimation[0+:10] <= cfg_data_i[9:0];
						r_i2s_shift[0+:3] <= cfg_data_i[18:16];
					end
					5'b01101: begin
						r_i2s_update[1] = 1'b1;
						r_i2s_decimation[10+:10] <= cfg_data_i[9:0];
						r_i2s_shift[3+:3] <= cfg_data_i[18:16];
					end
					5'b01000: r_i2s_ext_bits_word <= cfg_data_i[4:0];
					5'b01001: begin
						r_i2s_cfg0_clk_en <= cfg_data_i[8];
						r_i2s_cfg0_clk_div <= cfg_data_i[31:16];
						r_i2s_cfg0_bits_word <= cfg_data_i[4:0];
					end
					5'b01010: begin
						r_i2s_cfg1_clk_en <= cfg_data_i[8];
						r_i2s_cfg1_clk_div <= cfg_data_i[31:16];
						r_i2s_cfg1_bits_word <= cfg_data_i[4:0];
					end
				endcase
		end
	always @(*) begin
		if (_sv2v_0)
			;
		cfg_data_o = 32'h00000000;
		case (s_rd_addr)
			5'b00000: cfg_data_o = cfg_rx_ch0_curr_addr_i;
			5'b00001: cfg_data_o[TRANS_SIZE - 1:0] = cfg_rx_ch0_bytes_left_i;
			5'b00010: cfg_data_o = {26'h0000000, cfg_rx_ch0_pending_i, cfg_rx_ch0_en_i, 1'b0, r_rx_ch0_datasize, r_rx_ch0_continuous};
			5'b00100: cfg_data_o = cfg_rx_ch1_curr_addr_i;
			5'b00101: cfg_data_o[TRANS_SIZE - 1:0] = cfg_rx_ch1_bytes_left_i;
			5'b00110: cfg_data_o = {26'h0000000, cfg_rx_ch1_pending_i, cfg_rx_ch1_en_i, 1'b0, r_rx_ch1_datasize, r_rx_ch1_continuous};
			5'b01011: cfg_data_o = {r_i2s_ch_mode, 4'h0, r_i2s_useddr, r_i2s_pdm_en, r_i2s_pdm_usefilter, r_i2s_lsb_first, r_i2s_snap_cam};
			5'b01100: cfg_data_o = {13'h0000, r_i2s_shift[0+:3], 6'h00, r_i2s_decimation[0+:10]};
			5'b01101: cfg_data_o = {13'h0000, r_i2s_shift[3+:3], 6'h00, r_i2s_decimation[10+:10]};
			5'b01000: cfg_data_o = {27'h0000000, r_i2s_ext_bits_word};
			5'b01001: cfg_data_o = {r_i2s_cfg0_clk_div, 7'h00, cfg_i2s_0_gen_clk_en_i, 3'h0, r_i2s_cfg0_bits_word};
			5'b01010: cfg_data_o = {r_i2s_cfg1_clk_div, 7'h00, cfg_i2s_1_gen_clk_en_i, 3'h0, r_i2s_cfg1_bits_word};
			default: cfg_data_o = 'h0;
		endcase
	end
	assign cfg_ready_o = 1'b1;
	initial _sv2v_0 = 0;
endmodule
