module udma_ctrl (
	clk_i,
	rstn_i,
	cfg_data_i,
	cfg_addr_i,
	cfg_valid_i,
	cfg_rwn_i,
	cfg_data_o,
	cfg_ready_o,
	rst_value_o,
	cg_value_o,
	cg_core_o,
	cfg_filter_mode_o,
	cfg_filter_start_o,
	cfg_filter_tx_start_addr_o,
	cfg_filter_tx_datasize_o,
	cfg_filter_tx_mode_o,
	cfg_filter_tx_len0_o,
	cfg_filter_tx_len1_o,
	cfg_filter_tx_len2_o,
	cfg_filter_rx_start_addr_o,
	cfg_filter_rx_datasize_o,
	cfg_filter_rx_mode_o,
	cfg_filter_rx_len0_o,
	cfg_filter_rx_len1_o,
	cfg_filter_rx_len2_o,
	cfg_au_use_signed_o,
	cfg_au_bypass_o,
	cfg_au_mode_o,
	cfg_au_shift_o,
	cfg_au_reg0_o,
	cfg_au_reg1_o,
	cfg_bincu_threshold_o,
	cfg_bincu_counter_o,
	event_valid_i,
	event_data_i,
	event_ready_o,
	event_o
);
	reg _sv2v_0;
	parameter L2_AWIDTH_NOAL = 15;
	parameter TRANS_SIZE = 15;
	input wire clk_i;
	input wire rstn_i;
	input wire [31:0] cfg_data_i;
	input wire [4:0] cfg_addr_i;
	input wire cfg_valid_i;
	input wire cfg_rwn_i;
	output reg [31:0] cfg_data_o;
	output wire cfg_ready_o;
	output wire [15:0] rst_value_o;
	output wire [15:0] cg_value_o;
	output wire cg_core_o;
	output wire [2:0] cfg_filter_mode_o;
	output wire cfg_filter_start_o;
	output wire [(2 * L2_AWIDTH_NOAL) - 1:0] cfg_filter_tx_start_addr_o;
	output wire [3:0] cfg_filter_tx_datasize_o;
	output wire [3:0] cfg_filter_tx_mode_o;
	output wire [(2 * TRANS_SIZE) - 1:0] cfg_filter_tx_len0_o;
	output wire [(2 * TRANS_SIZE) - 1:0] cfg_filter_tx_len1_o;
	output wire [(2 * TRANS_SIZE) - 1:0] cfg_filter_tx_len2_o;
	output wire [L2_AWIDTH_NOAL - 1:0] cfg_filter_rx_start_addr_o;
	output wire [1:0] cfg_filter_rx_datasize_o;
	output wire [1:0] cfg_filter_rx_mode_o;
	output wire [TRANS_SIZE - 1:0] cfg_filter_rx_len0_o;
	output wire [TRANS_SIZE - 1:0] cfg_filter_rx_len1_o;
	output wire [TRANS_SIZE - 1:0] cfg_filter_rx_len2_o;
	output wire cfg_au_use_signed_o;
	output wire cfg_au_bypass_o;
	output wire [3:0] cfg_au_mode_o;
	output wire [4:0] cfg_au_shift_o;
	output wire [31:0] cfg_au_reg0_o;
	output wire [31:0] cfg_au_reg1_o;
	output wire [31:0] cfg_bincu_threshold_o;
	output wire [TRANS_SIZE - 1:0] cfg_bincu_counter_o;
	input wire event_valid_i;
	input wire [7:0] event_data_i;
	output wire event_ready_o;
	output reg [3:0] event_o;
	reg [15:0] r_cg;
	reg [15:0] r_rst;
	reg [31:0] r_cmp_evt;
	reg [(2 * L2_AWIDTH_NOAL) - 1:0] r_filter_tx_start_addr;
	reg [3:0] r_filter_tx_datasize;
	reg [3:0] r_filter_tx_mode;
	reg [(2 * TRANS_SIZE) - 1:0] r_filter_tx_len0;
	reg [(2 * TRANS_SIZE) - 1:0] r_filter_tx_len1;
	reg [(2 * TRANS_SIZE) - 1:0] r_filter_tx_len2;
	reg [L2_AWIDTH_NOAL - 1:0] r_filter_rx_start_addr;
	reg [1:0] r_filter_rx_datasize;
	reg [1:0] r_filter_rx_mode;
	reg [TRANS_SIZE - 1:0] r_filter_rx_len0;
	reg [TRANS_SIZE - 1:0] r_filter_rx_len1;
	reg [TRANS_SIZE - 1:0] r_filter_rx_len2;
	reg r_au_use_signed;
	reg r_au_bypass;
	reg [3:0] r_au_mode;
	reg [4:0] r_au_shift;
	reg [31:0] r_au_reg0;
	reg [31:0] r_au_reg1;
	reg [31:0] r_bincu_threshold;
	reg [TRANS_SIZE - 1:0] r_bincu_counter;
	reg [2:0] r_filter_mode;
	reg r_filter_start;
	wire [4:0] s_wr_addr;
	wire [4:0] s_rd_addr;
	assign s_wr_addr = (cfg_valid_i & ~cfg_rwn_i ? cfg_addr_i : 5'h00);
	assign s_rd_addr = (cfg_valid_i & cfg_rwn_i ? cfg_addr_i : 5'h00);
	assign cfg_filter_tx_start_addr_o = r_filter_tx_start_addr;
	assign cfg_filter_tx_datasize_o = r_filter_tx_datasize;
	assign cfg_filter_tx_mode_o = r_filter_tx_mode;
	assign cfg_filter_tx_len0_o = r_filter_tx_len0;
	assign cfg_filter_tx_len1_o = r_filter_tx_len1;
	assign cfg_filter_tx_len2_o = r_filter_tx_len2;
	assign cfg_filter_rx_start_addr_o = r_filter_rx_start_addr;
	assign cfg_filter_rx_datasize_o = r_filter_rx_datasize;
	assign cfg_filter_rx_mode_o = r_filter_rx_mode;
	assign cfg_filter_rx_len0_o = r_filter_rx_len0;
	assign cfg_filter_rx_len1_o = r_filter_rx_len1;
	assign cfg_filter_rx_len2_o = r_filter_rx_len2;
	assign cfg_filter_mode_o = r_filter_mode;
	assign cfg_filter_start_o = r_filter_start;
	assign cfg_au_use_signed_o = r_au_use_signed;
	assign cfg_au_bypass_o = r_au_bypass;
	assign cfg_au_mode_o = r_au_mode;
	assign cfg_au_shift_o = r_au_shift;
	assign cfg_au_reg0_o = r_au_reg0;
	assign cfg_au_reg1_o = r_au_reg1;
	assign cfg_bincu_counter_o = r_bincu_counter;
	assign cfg_bincu_threshold_o = r_bincu_threshold;
	assign cg_value_o = r_cg;
	assign cg_core_o = |r_cg;
	assign rst_value_o = r_rst;
	assign event_ready_o = 1'b1;
	always @(*) begin : proc_event_o
		if (_sv2v_0)
			;
		event_o = 4'h0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 4; i = i + 1)
				event_o[i] = event_valid_i & (event_data_i == r_cmp_evt[i * 8+:8]);
		end
	end
	always @(posedge clk_i or negedge rstn_i)
		if (~rstn_i) begin
			r_cg <= 'h0;
			r_cmp_evt <= 'h0;
			r_rst <= 'h0;
			r_filter_tx_start_addr[0+:L2_AWIDTH_NOAL] <= 0;
			r_filter_tx_datasize[0+:2] <= 0;
			r_filter_tx_mode[0+:2] <= 0;
			r_filter_tx_len0[0+:TRANS_SIZE] <= 0;
			r_filter_tx_len1[0+:TRANS_SIZE] <= 0;
			r_filter_tx_len2[0+:TRANS_SIZE] <= 0;
			r_filter_tx_start_addr[L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL] <= 0;
			r_filter_tx_datasize[2+:2] <= 0;
			r_filter_tx_mode[2+:2] <= 0;
			r_filter_tx_len0[TRANS_SIZE+:TRANS_SIZE] <= 0;
			r_filter_tx_len1[TRANS_SIZE+:TRANS_SIZE] <= 0;
			r_filter_tx_len2[TRANS_SIZE+:TRANS_SIZE] <= 0;
			r_filter_rx_start_addr <= 0;
			r_filter_rx_datasize <= 0;
			r_filter_rx_mode <= 0;
			r_filter_rx_len0 <= 0;
			r_filter_rx_len1 <= 0;
			r_filter_rx_len2 <= 0;
			r_au_use_signed <= 0;
			r_au_bypass <= 0;
			r_au_mode <= 0;
			r_au_shift <= 0;
			r_au_reg0 <= 0;
			r_au_reg1 <= 0;
			r_bincu_threshold <= 0;
			r_bincu_counter <= 0;
			r_filter_mode <= 0;
			r_filter_start <= 0;
		end
		else begin
			if (((cfg_valid_i && !cfg_rwn_i) && (s_wr_addr == 5'b11001)) && cfg_data_i[0])
				r_filter_start = 1'b1;
			else
				r_filter_start = 1'b0;
			if (cfg_valid_i & ~cfg_rwn_i)
				case (s_wr_addr)
					5'b00000: r_cg <= cfg_data_i[15:0];
					5'b00010: r_rst <= cfg_data_i[15:0];
					5'b00001: begin
						r_cmp_evt[0+:8] <= cfg_data_i[7:0];
						r_cmp_evt[8+:8] <= cfg_data_i[15:8];
						r_cmp_evt[16+:8] <= cfg_data_i[23:16];
						r_cmp_evt[24+:8] <= cfg_data_i[31:24];
					end
					5'b00100: r_filter_tx_start_addr[0+:L2_AWIDTH_NOAL] <= cfg_data_i[L2_AWIDTH_NOAL - 1:0];
					5'b00101: begin
						r_filter_tx_datasize[0+:2] <= cfg_data_i[1:0];
						r_filter_tx_mode[0+:2] <= cfg_data_i[9:8];
					end
					5'b00110: r_filter_tx_len0[0+:TRANS_SIZE] <= cfg_data_i[TRANS_SIZE - 1:0];
					5'b00111: r_filter_tx_len1[0+:TRANS_SIZE] <= cfg_data_i[TRANS_SIZE - 1:0];
					5'b01000: r_filter_tx_len2[0+:TRANS_SIZE] <= cfg_data_i[TRANS_SIZE - 1:0];
					5'b01001: r_filter_tx_start_addr[L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL] <= cfg_data_i[L2_AWIDTH_NOAL - 1:0];
					5'b01010: begin
						r_filter_tx_datasize[2+:2] <= cfg_data_i[1:0];
						r_filter_tx_mode[2+:2] <= cfg_data_i[9:8];
					end
					5'b01011: r_filter_tx_len0[TRANS_SIZE+:TRANS_SIZE] <= cfg_data_i[TRANS_SIZE - 1:0];
					5'b01100: r_filter_tx_len1[TRANS_SIZE+:TRANS_SIZE] <= cfg_data_i[TRANS_SIZE - 1:0];
					5'b01101: r_filter_rx_len2[1] <= cfg_data_i[TRANS_SIZE - 1:0];
					5'b01110: r_filter_rx_start_addr <= cfg_data_i[L2_AWIDTH_NOAL - 1:0];
					5'b01111: begin
						r_filter_rx_datasize <= cfg_data_i[1:0];
						r_filter_rx_mode <= cfg_data_i[9:8];
					end
					5'b10000: r_filter_rx_len0 <= cfg_data_i[15:0];
					5'b10001: r_filter_rx_len1 <= cfg_data_i[15:0];
					5'b10010: r_filter_rx_len2 <= cfg_data_i[15:0];
					5'b10011: begin
						r_au_use_signed <= cfg_data_i[0];
						r_au_bypass <= cfg_data_i[1];
						r_au_mode <= cfg_data_i[11:8];
						r_au_shift <= cfg_data_i[20:16];
					end
					5'b10100: r_au_reg0 <= cfg_data_i;
					5'b10101: r_au_reg1 <= cfg_data_i;
					5'b10110: r_bincu_threshold <= cfg_data_i;
					5'b10111: r_bincu_counter <= cfg_data_i[TRANS_SIZE - 1:0];
					5'b11000: r_filter_mode <= cfg_data_i[2:0];
				endcase
		end
	always @(*) begin
		if (_sv2v_0)
			;
		cfg_data_o = 32'h00000000;
		case (s_rd_addr)
			5'b00000: cfg_data_o[15:0] = r_cg;
			5'b00010: cfg_data_o[15:0] = r_rst;
			5'b00001: cfg_data_o = {r_cmp_evt[24+:8], r_cmp_evt[16+:8], r_cmp_evt[8+:8], r_cmp_evt[0+:8]};
			5'b00100: cfg_data_o[L2_AWIDTH_NOAL - 1:0] = r_filter_tx_start_addr[0+:L2_AWIDTH_NOAL];
			5'b00101: begin
				cfg_data_o[9:8] = r_filter_tx_mode[0+:2];
				cfg_data_o[1:0] = r_filter_tx_datasize[0+:2];
			end
			5'b00110: cfg_data_o[TRANS_SIZE - 1:0] = r_filter_tx_len0[0+:TRANS_SIZE];
			5'b00111: cfg_data_o[TRANS_SIZE - 1:0] = r_filter_tx_len1[0+:TRANS_SIZE];
			5'b01000: cfg_data_o[TRANS_SIZE - 1:0] = r_filter_tx_len2[0+:TRANS_SIZE];
			5'b01001: cfg_data_o[L2_AWIDTH_NOAL - 1:0] = r_filter_tx_start_addr[L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL];
			5'b01010: begin
				cfg_data_o[1:0] = r_filter_tx_datasize[2+:2];
				cfg_data_o[9:8] = r_filter_tx_mode[2+:2];
			end
			5'b01011: cfg_data_o[TRANS_SIZE - 1:0] = r_filter_tx_len0[TRANS_SIZE+:TRANS_SIZE];
			5'b01100: cfg_data_o[TRANS_SIZE - 1:0] = r_filter_tx_len1[TRANS_SIZE+:TRANS_SIZE];
			5'b01101: cfg_data_o[TRANS_SIZE - 1:0] = r_filter_rx_len2[1];
			5'b01110: cfg_data_o[L2_AWIDTH_NOAL - 1:0] = r_filter_rx_start_addr[1];
			5'b01111: begin
				cfg_data_o[1:0] = r_filter_rx_datasize[1];
				cfg_data_o[9:8] = r_filter_rx_mode[1];
			end
			5'b10000: cfg_data_o[15:0] = r_filter_rx_len0[1];
			5'b10001: cfg_data_o[15:0] = r_filter_rx_len1[1];
			5'b10010: cfg_data_o[15:0] = r_filter_rx_len2[1];
			5'b10011: begin
				cfg_data_o[0] = r_au_use_signed;
				cfg_data_o[1] = r_au_bypass;
				cfg_data_o[11:8] = r_au_mode;
				cfg_data_o[20:16] = r_au_shift;
			end
			5'b10100: cfg_data_o = r_au_reg0;
			5'b10101: cfg_data_o = r_au_reg1;
			5'b10110: cfg_data_o = r_bincu_threshold;
			5'b10111: cfg_data_o[TRANS_SIZE - 1:0] = r_bincu_counter;
			5'b11000: cfg_data_o[2:0] = r_filter_mode;
			default: cfg_data_o = 'h0;
		endcase
	end
	assign cfg_ready_o = 1'b1;
	initial _sv2v_0 = 0;
endmodule
