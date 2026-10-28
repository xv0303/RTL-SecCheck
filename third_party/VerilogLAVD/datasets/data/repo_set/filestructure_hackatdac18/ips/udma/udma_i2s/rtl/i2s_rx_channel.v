module i2s_rx_channel (
	sck_i,
	rstn_i,
	sd_i,
	ws_i,
	fifo_data_o,
	fifo_data_valid_o,
	fifo_data_ready_i,
	fifo_err_o,
	fifo_err_clr_i,
	cfg_update_i,
	cfg_decimation_i,
	cfg_shift_i,
	cfg_lsb_first_i,
	cfg_snap_cam_i,
	cfg_pdm_en_i,
	cfg_pdm_ddr_i,
	cfg_pdm_usefilter_i
);
	reg _sv2v_0;
	parameter CIC_N_STAGES = 5;
	parameter CIC_ACC_WIDTH = 51;
	input wire sck_i;
	input wire rstn_i;
	input wire sd_i;
	input wire ws_i;
	output wire [31:0] fifo_data_o;
	output wire fifo_data_valid_o;
	input wire fifo_data_ready_i;
	output reg fifo_err_o;
	input wire fifo_err_clr_i;
	input wire cfg_update_i;
	input wire [9:0] cfg_decimation_i;
	input wire [2:0] cfg_shift_i;
	input wire cfg_lsb_first_i;
	input wire cfg_snap_cam_i;
	input wire cfg_pdm_en_i;
	input wire cfg_pdm_ddr_i;
	input wire cfg_pdm_usefilter_i;
	reg [1:0] r_ws_sync;
	wire s_ws_edge;
	wire s_ws_redge;
	reg [31:0] r_shiftreg_pos;
	reg [32:0] r_shiftreg_neg;
	reg r_send_neg;
	reg [4:0] r_counter;
	wire s_cic_data_valid_pos;
	wire s_cic_data_valid_neg;
	wire s_cic_result_valid_pos;
	wire s_cic_result_valid_neg;
	wire [15:0] s_cic_result_pos;
	wire [15:0] s_cic_result_neg;
	reg r_sel_pos;
	reg r_fifo_data_filter_pos_valid;
	reg r_fifo_data_filter_neg_valid;
	reg [31:0] s_fifo_data;
	wire [31:0] s_fifo_data_filter;
	wire s_clk_inv;
	wire s_fifo_data_filter_valid;
	wire s_fifo_data_valid;
	pulp_clock_inverter i_clk_inv(
		.clk_i(sck_i),
		.clk_o(s_clk_inv)
	);
	varcic #(
		.STAGES(CIC_N_STAGES),
		.ACC_WIDTH(CIC_ACC_WIDTH)
	) i_cic_pos(
		.clk_i(sck_i),
		.rstn_i(rstn_i),
		.cfg_update_i(cfg_update_i),
		.cfg_decimation_i(cfg_decimation_i),
		.cfg_shift_i(cfg_shift_i),
		.data_i(sd_i),
		.data_valid_i(s_cic_data_valid_pos),
		.data_o(s_cic_result_pos),
		.data_valid_o(s_cic_result_valid_pos)
	);
	varcic #(
		.STAGES(CIC_N_STAGES),
		.ACC_WIDTH(CIC_ACC_WIDTH)
	) i_cic_neg(
		.clk_i(s_clk_inv),
		.rstn_i(rstn_i),
		.cfg_update_i(cfg_update_i),
		.cfg_decimation_i(cfg_decimation_i),
		.cfg_shift_i(cfg_shift_i),
		.data_i(sd_i),
		.data_valid_i(s_cic_data_valid_neg),
		.data_o(s_cic_result_neg),
		.data_valid_o(s_cic_result_valid_neg)
	);
	assign s_cic_data_valid_pos = cfg_pdm_en_i;
	assign s_cic_data_valid_neg = cfg_pdm_en_i & cfg_pdm_ddr_i;
	assign s_fifo_data_filter_valid = r_fifo_data_filter_pos_valid | r_fifo_data_filter_neg_valid;
	assign s_fifo_data_filter = (r_sel_pos ? s_cic_result_pos : s_cic_result_neg);
	always @(posedge sck_i or negedge rstn_i) begin : proc_valid_o
		if (~rstn_i) begin
			r_fifo_data_filter_pos_valid <= 0;
			r_fifo_data_filter_neg_valid <= 0;
			r_sel_pos <= 1'b1;
		end
		else if (cfg_pdm_usefilter_i) begin
			if (!s_fifo_data_filter_valid && (s_cic_result_valid_neg || s_cic_result_valid_pos)) begin
				r_fifo_data_filter_pos_valid <= s_cic_result_valid_pos;
				r_fifo_data_filter_neg_valid <= s_cic_result_valid_neg;
				if (s_cic_result_valid_pos)
					r_sel_pos <= 1'b1;
				else
					r_sel_pos <= 1'b0;
			end
			else if (s_fifo_data_filter_valid) begin
				if (fifo_data_ready_i) begin
					if (r_sel_pos) begin
						r_fifo_data_filter_pos_valid <= s_cic_result_valid_pos;
						if (r_fifo_data_filter_neg_valid || s_cic_result_valid_neg)
							r_sel_pos <= 1'b0;
						if (s_cic_result_valid_neg)
							r_fifo_data_filter_neg_valid <= 1'b1;
					end
					else begin
						r_fifo_data_filter_neg_valid <= s_cic_result_valid_neg;
						if (r_fifo_data_filter_pos_valid || s_cic_result_valid_pos)
							r_sel_pos <= 1'b1;
						if (s_cic_result_valid_pos)
							r_fifo_data_filter_pos_valid <= 1'b1;
					end
				end
				else begin
					if (s_cic_result_valid_neg)
						r_fifo_data_filter_neg_valid <= 1'b1;
					if (s_cic_result_valid_pos)
						r_fifo_data_filter_pos_valid <= 1'b1;
				end
			end
		end
		else begin
			r_fifo_data_filter_pos_valid <= 0;
			r_fifo_data_filter_neg_valid <= 0;
		end
	end
	always @(posedge sck_i or negedge rstn_i)
		if (rstn_i == 1'b0)
			r_send_neg <= 1'b0;
		else if (s_ws_edge & cfg_pdm_ddr_i)
			r_send_neg <= 1'b1;
		else
			r_send_neg <= 1'b0;
	always @(posedge sck_i or negedge rstn_i)
		if (rstn_i == 1'b0)
			r_shiftreg_pos <= 'h0;
		else if (!cfg_snap_cam_i || (cfg_snap_cam_i && !r_ws_sync[0])) begin
			if (cfg_lsb_first_i)
				r_shiftreg_pos[r_counter] <= sd_i;
			else
				r_shiftreg_pos <= {r_shiftreg_pos[30:0], sd_i};
		end
	always @(negedge sck_i or negedge rstn_i)
		if (rstn_i == 1'b0) begin
			r_counter <= 'h0;
			r_shiftreg_neg <= 'h0;
		end
		else begin
			if (s_ws_edge)
				r_counter <= 'h0;
			else
				r_counter <= r_counter + 1;
			if (cfg_pdm_ddr_i) begin
				if (cfg_lsb_first_i) begin
					r_shiftreg_neg[r_counter] <= sd_i;
					if (s_ws_edge)
						r_shiftreg_neg[32] <= r_shiftreg_neg[0];
				end
				else
					r_shiftreg_neg <= {r_shiftreg_neg[31:0], sd_i};
			end
		end
	always @(posedge sck_i or negedge rstn_i)
		if (rstn_i == 1'b0)
			r_ws_sync <= 'h0;
		else
			r_ws_sync <= {r_ws_sync[0], ws_i};
	always @(posedge sck_i or negedge rstn_i)
		if (rstn_i == 1'b0)
			fifo_err_o <= 1'b0;
		else if (fifo_err_clr_i)
			fifo_err_o <= 1'b0;
		else if (fifo_data_valid_o && !fifo_data_ready_i)
			fifo_err_o <= 1'b1;
	always @(*) begin
		if (_sv2v_0)
			;
		if (r_send_neg) begin
			if (cfg_lsb_first_i)
				s_fifo_data = {r_shiftreg_neg[31:1], r_shiftreg_neg[32]};
			else
				s_fifo_data = r_shiftreg_neg[32:1];
		end
		else
			s_fifo_data = r_shiftreg_pos;
	end
	assign s_ws_edge = r_ws_sync[0] ^ r_ws_sync[1];
	assign s_ws_redge = r_ws_sync[0] & ~r_ws_sync[1];
	assign s_fifo_data_valid = (cfg_snap_cam_i ? s_ws_redge : s_ws_edge | r_send_neg);
	assign fifo_data_o = (cfg_pdm_usefilter_i ? s_fifo_data_filter : s_fifo_data);
	assign fifo_data_valid_o = (cfg_pdm_usefilter_i ? s_fifo_data_filter_valid : s_fifo_data_valid);
	initial _sv2v_0 = 0;
endmodule
