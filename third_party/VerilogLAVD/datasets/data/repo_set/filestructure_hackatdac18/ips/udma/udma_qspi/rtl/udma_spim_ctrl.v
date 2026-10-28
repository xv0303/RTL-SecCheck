module udma_spim_ctrl (
	clk_i,
	rstn_i,
	eot_o,
	event_i,
	cfg_cpol_o,
	cfg_cpha_o,
	cfg_clkdiv_data_o,
	cfg_clkdiv_valid_o,
	cfg_clkdiv_ack_i,
	tx_start_o,
	tx_size_o,
	tx_customsize_o,
	tx_qpi_o,
	tx_done_i,
	tx_data_o,
	tx_data_valid_o,
	tx_data_ready_i,
	rx_start_o,
	rx_size_o,
	rx_customsize_o,
	rx_qpi_o,
	rx_done_i,
	rx_data_i,
	rx_data_valid_i,
	rx_data_ready_o,
	udma_tx_data_i,
	udma_tx_data_valid_i,
	udma_tx_data_ready_o,
	udma_rx_data_o,
	udma_rx_data_valid_o,
	udma_rx_data_ready_i,
	spi_csn0_o,
	spi_csn1_o,
	spi_csn2_o,
	spi_csn3_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rstn_i;
	output reg eot_o;
	input wire [3:0] event_i;
	output wire cfg_cpol_o;
	output wire cfg_cpha_o;
	output wire [7:0] cfg_clkdiv_data_o;
	output wire cfg_clkdiv_valid_o;
	input wire cfg_clkdiv_ack_i;
	output reg tx_start_o;
	output reg [15:0] tx_size_o;
	output reg tx_customsize_o;
	output reg tx_qpi_o;
	input wire tx_done_i;
	output reg [31:0] tx_data_o;
	output reg tx_data_valid_o;
	input wire tx_data_ready_i;
	output reg rx_start_o;
	output reg [15:0] rx_size_o;
	output reg rx_customsize_o;
	output reg rx_qpi_o;
	input wire rx_done_i;
	input wire [31:0] rx_data_i;
	input wire rx_data_valid_i;
	output reg rx_data_ready_o;
	input wire [31:0] udma_tx_data_i;
	input wire udma_tx_data_valid_i;
	output reg udma_tx_data_ready_o;
	output reg [31:0] udma_rx_data_o;
	output reg udma_rx_data_valid_o;
	input wire udma_rx_data_ready_i;
	output reg spi_csn0_o;
	output reg spi_csn1_o;
	output reg spi_csn2_o;
	output reg spi_csn3_o;
	reg [2:0] state;
	reg [2:0] state_next;
	reg [3:0] r_rptstate;
	reg [3:0] s_rptstate_next;
	wire s_cfg_cpol;
	wire s_cfg_cpha;
	reg r_cfg_cpol;
	reg r_cfg_cpha;
	wire [7:0] s_cfg_clkdiv;
	reg [7:0] r_cfg_clkdiv;
	reg s_update_cfg;
	reg r_update_cfg;
	reg s_update_qpi;
	reg s_update_cs;
	reg s_update_evt;
	reg s_update_chk;
	reg s_clear_cs;
	reg s_event;
	wire [1:0] s_evt_sel;
	reg [1:0] r_evt_sel;
	reg is_cmd_cfg;
	reg is_cmd_sot;
	reg is_cmd_snc;
	reg is_cmd_sna;
	reg is_cmd_dum;
	reg is_cmd_wai;
	reg is_cmd_txd;
	reg is_cmd_rxd;
	reg is_cmd_rxc;
	reg is_cmd_rpt;
	reg is_cmd_rpe;
	reg is_cmd_eot;
	reg is_cmd_ful;
	reg is_cmd_wcy;
	wire [3:0] s_cmd;
	wire [1:0] s_cs;
	wire s_cfg_custom;
	wire s_cfg_qpi;
	wire [1:0] s_cfg_cs;
	wire [15:0] s_cfg_check;
	wire [15:0] s_size_long;
	wire [15:0] s_cmd_data;
	wire [4:0] s_size;
	wire s_gen_eot;
	reg s_qpi;
	reg r_qpi;
	reg [15:0] r_chk;
	reg [1:0] r_chk_type;
	wire [1:0] s_cfg_chk_type;
	reg s_is_dummy;
	reg r_is_dummy;
	reg s_update_rpt;
	reg r_rpt_cfg;
	reg [15:0] r_rpt_num;
	reg [15:0] s_rpt_num;
	reg s_rpt_update_cs;
	reg [1:0] r_rpt_cs;
	reg [1:0] s_rpt_cs;
	reg s_rpt_update_cmd;
	reg r_rpt_do_cmd;
	reg s_rpt_do_cmd;
	reg [20:0] r_rpt_cmd;
	reg [20:0] s_rpt_cmd;
	reg s_rpt_update_rx_chk;
	reg r_rpt_do_rx_chk;
	reg s_rpt_do_rx_chk;
	reg [20:0] r_rpt_rx_chk;
	reg [20:0] s_rpt_rx_chk;
	reg s_rpt_update_addr;
	reg r_rpt_do_addr;
	reg s_rpt_do_addr;
	reg [37:0] r_rpt_addr;
	reg [37:0] s_rpt_addr;
	reg s_rpt_update_dummy;
	reg r_rpt_do_dummy;
	reg s_rpt_do_dummy;
	reg [4:0] r_rpt_dummy;
	reg [4:0] s_rpt_dummy;
	reg r_rpt_do_wait;
	reg s_rpt_do_wait;
	reg s_rpt_update_read;
	reg r_rpt_do_read;
	reg s_rpt_do_read;
	reg [17:0] r_rpt_read;
	reg [17:0] s_rpt_read;
	reg s_rpt_update_write;
	reg r_rpt_do_write;
	reg s_rpt_do_write;
	reg [17:0] r_rpt_write;
	reg [17:0] s_rpt_write;
	reg s_rpt_do_ful;
	reg r_rpt_do_ful;
	reg s_rpt_update_ful;
	reg [15:0] s_rpt_ful;
	reg [15:0] r_rpt_ful;
	reg s_is_ful;
	reg r_is_ful;
	wire s_done;
	reg r_tx_done;
	reg r_rx_done;
	reg s_is_repeating;
	reg r_is_repeating;
	reg s_update_chk_result;
	reg s_chk_result;
	reg r_chk_result;
	wire [7:0] s_wait_cycle;
	assign s_cmd = udma_tx_data_i[31:28];
	assign s_cfg_cpol = udma_tx_data_i[9];
	assign s_cfg_cpha = udma_tx_data_i[8];
	assign s_cfg_clkdiv = udma_tx_data_i[7:0];
	assign s_cfg_cs = udma_tx_data_i[1:0];
	assign s_size = udma_tx_data_i[20:16];
	assign s_size_long = udma_tx_data_i[15:0];
	assign s_cfg_qpi = udma_tx_data_i[27];
	assign s_cfg_custom = udma_tx_data_i[26];
	assign s_cmd_data = udma_tx_data_i[15:0];
	assign s_gen_eot = udma_tx_data_i[0];
	assign s_cfg_check = udma_tx_data_i[15:0];
	assign s_cfg_chk_type = udma_tx_data_i[25:24];
	assign s_evt_sel = udma_tx_data_i[1:0];
	assign s_wait_cycle = udma_tx_data_i[7:0];
	assign cfg_cpol_o = r_cfg_cpol;
	assign cfg_cpha_o = r_cfg_cpha;
	assign cfg_clkdiv_data_o = r_cfg_clkdiv;
	assign s_done = (r_is_ful ? (tx_done_i | r_tx_done) & (rx_done_i | r_rx_done) : tx_done_i | rx_done_i);
	edge_propagator_tx i_edgeprop(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.valid_i(r_update_cfg),
		.ack_i(cfg_clkdiv_ack_i),
		.valid_o(cfg_clkdiv_valid_o)
	);
	reg [1:0] r_cnt_state;
	reg [1:0] s_cnt_state_next;
	reg s_cnt_done;
	reg s_cnt_start;
	reg s_cnt_update;
	wire s_cnt_clr;
	reg [7:0] s_cnt_target;
	reg [7:0] r_cnt_target;
	reg [7:0] r_cnt;
	reg [7:0] s_cnt_next;
	always @(posedge clk_i or negedge rstn_i)
		if (~rstn_i) begin
			r_cnt_state <= 2'd0;
			r_cnt <= 'h0;
			r_cnt_target <= 'h0;
		end
		else begin
			if (s_cnt_start)
				r_cnt_target <= s_cnt_target;
			if (s_cnt_start || s_cnt_done)
				r_cnt_state <= s_cnt_state_next;
			if (s_cnt_update)
				r_cnt <= s_cnt_next;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		s_cnt_update = 1'b0;
		s_cnt_state_next = r_cnt_state;
		s_cnt_done = 1'b0;
		s_cnt_next = r_cnt;
		case (r_cnt_state)
			2'd0:
				if (s_cnt_start)
					s_cnt_state_next = 2'd1;
			2'd1: begin
				s_cnt_update = 1'b1;
				if (r_cnt_target == r_cnt) begin
					s_cnt_next = 'h0;
					s_cnt_done = 1'b1;
					if (~s_cnt_start)
						s_cnt_state_next = 2'd0;
				end
				else
					s_cnt_next = r_cnt + 1;
			end
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		is_cmd_cfg = 1'b0;
		is_cmd_sot = 1'b0;
		is_cmd_snc = 1'b0;
		is_cmd_sna = 1'b0;
		is_cmd_dum = 1'b0;
		is_cmd_wai = 1'b0;
		is_cmd_txd = 1'b0;
		is_cmd_rxd = 1'b0;
		is_cmd_rxc = 1'b0;
		is_cmd_rpt = 1'b0;
		is_cmd_eot = 1'b0;
		is_cmd_rpe = 1'b0;
		is_cmd_ful = 1'b0;
		is_cmd_wcy = 1'b0;
		case (s_cmd)
			4'b0000: is_cmd_cfg = 1'b1;
			4'b0001: is_cmd_sot = 1'b1;
			4'b0010: is_cmd_snc = 1'b1;
			4'b0011: is_cmd_sna = 1'b1;
			4'b0100: is_cmd_dum = 1'b1;
			4'b0101: is_cmd_wai = 1'b1;
			4'b0110: is_cmd_txd = 1'b1;
			4'b0111: is_cmd_rxd = 1'b1;
			4'b1011: is_cmd_rxc = 1'b1;
			4'b1000: is_cmd_rpt = 1'b1;
			4'b1010: is_cmd_rpe = 1'b1;
			4'b1001: is_cmd_eot = 1'b1;
			4'b1100: is_cmd_ful = 1'b1;
			4'b1101: is_cmd_wcy = 1'b1;
		endcase
	end
	always @(*) begin : proc_s_event
		if (_sv2v_0)
			;
		s_event = 1'b0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 4; i = i + 1)
				if (r_evt_sel == i)
					s_event = event_i[i];
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		state_next = state;
		s_rptstate_next = r_rptstate;
		udma_tx_data_ready_o = 1'b0;
		udma_rx_data_o = 'h0;
		udma_rx_data_valid_o = 1'b0;
		rx_data_ready_o = 1'b0;
		s_update_chk = 1'b0;
		s_update_cfg = 1'b0;
		s_update_cs = 1'b0;
		s_update_qpi = 1'b0;
		s_update_evt = 1'b0;
		s_clear_cs = 1'b0;
		tx_size_o = 'h0;
		rx_size_o = 'h0;
		tx_customsize_o = 1'b0;
		rx_customsize_o = 1'b0;
		tx_qpi_o = r_qpi;
		rx_qpi_o = r_qpi;
		tx_start_o = 1'b0;
		rx_start_o = 1'b0;
		tx_data_o = 'h0;
		tx_data_valid_o = 1'b0;
		eot_o = 1'b0;
		s_is_dummy = r_is_dummy;
		s_qpi = r_qpi;
		s_rpt_num = r_rpt_num;
		s_update_rpt = 1'b0;
		s_is_repeating = r_is_repeating;
		s_is_ful = r_is_ful;
		s_update_chk_result = 1'b0;
		s_chk_result = 1'b0;
		s_rpt_update_cs = 1'b0;
		s_rpt_update_cmd = 1'b0;
		s_rpt_update_addr = 1'b0;
		s_rpt_update_dummy = 1'b0;
		s_rpt_update_write = 1'b0;
		s_rpt_update_read = 1'b0;
		s_rpt_update_rx_chk = 1'b0;
		s_rpt_update_ful = 1'b0;
		s_cnt_start = 1'b0;
		s_cnt_target = 'h0;
		s_rpt_cs = r_rpt_cs;
		s_rpt_cmd = r_rpt_cmd;
		s_rpt_addr = r_rpt_addr;
		s_rpt_read = r_rpt_read;
		s_rpt_write = r_rpt_write;
		s_rpt_ful = r_rpt_ful;
		s_rpt_dummy = r_rpt_dummy;
		s_rpt_rx_chk = r_rpt_rx_chk;
		s_rpt_do_cmd = r_rpt_do_cmd;
		s_rpt_do_addr = r_rpt_do_addr;
		s_rpt_do_dummy = r_rpt_do_dummy;
		s_rpt_do_write = r_rpt_do_write;
		s_rpt_do_read = r_rpt_do_read;
		s_rpt_do_rx_chk = r_rpt_do_rx_chk;
		s_rpt_do_wait = r_rpt_do_wait;
		s_rpt_do_ful = r_rpt_do_ful;
		case (state)
			3'd0: begin
				s_is_ful = 1'b0;
				s_is_repeating = 1'b0;
				if (udma_tx_data_valid_i) begin
					udma_tx_data_ready_o = 1'b1;
					if (is_cmd_cfg)
						s_update_cfg = 1'b1;
					else if (is_cmd_sot) begin
						if (r_rpt_cfg) begin
							s_rpt_update_cs = 1'b1;
							s_rpt_cs = s_cs;
						end
						else
							s_update_cs = 1'b1;
					end
					else if (is_cmd_snc) begin
						if (r_rpt_cfg) begin
							s_rpt_do_cmd = 1'b1;
							s_rpt_update_cmd = 1'b1;
							s_rpt_cmd = {s_cfg_qpi, s_size[3:0], s_cmd_data};
							state_next = 3'd0;
						end
						else begin
							s_update_qpi = 1'b1;
							tx_start_o = 1'b1;
							tx_customsize_o = 1'b1;
							tx_qpi_o = s_cfg_qpi;
							s_qpi = s_cfg_qpi;
							tx_size_o = {11'h000, s_size};
							state_next = 3'd1;
							tx_data_valid_o = 1'b1;
							tx_data_o = {s_cmd_data, 16'h0000};
						end
					end
					else if (is_cmd_wai) begin
						s_update_evt = 1'b1;
						if (r_rpt_cfg) begin
							state_next = 3'd0;
							s_rpt_do_wait = 1'b1;
						end
						else
							state_next = 3'd3;
					end
					else if (is_cmd_wcy) begin
						s_cnt_start = 1'b1;
						s_cnt_target = s_wait_cycle;
						state_next = 3'd6;
					end
					else if (is_cmd_sna) begin
						if (r_rpt_cfg) begin
							s_rpt_do_addr = 1'b1;
							s_rpt_update_addr = 1'b1;
							s_rpt_addr = {s_cfg_qpi, s_size[4:0], 32'h00000000};
							state_next = 3'd4;
						end
						else begin
							s_update_qpi = 1'b1;
							tx_start_o = 1'b1;
							tx_customsize_o = 1'b1;
							tx_qpi_o = s_cfg_qpi;
							s_qpi = s_cfg_qpi;
							tx_size_o = {11'h000, s_size};
							state_next = 3'd1;
						end
					end
					else if (is_cmd_dum) begin
						if (r_rpt_cfg) begin
							s_rpt_do_dummy = 1'b1;
							s_rpt_update_dummy = 1'b1;
							s_rpt_dummy = s_size;
							state_next = 3'd0;
						end
						else begin
							s_update_qpi = 1'b1;
							rx_start_o = 1'b1;
							rx_customsize_o = 1'b0;
							rx_qpi_o = s_cfg_qpi;
							s_qpi = s_cfg_qpi;
							rx_size_o = {11'h000, s_size};
							state_next = 3'd1;
							s_is_dummy = 1'b1;
						end
					end
					else if (is_cmd_txd) begin
						if (r_rpt_cfg) begin
							s_rpt_do_write = 1'b1;
							s_rpt_update_write = 1'b1;
							s_rpt_write = {s_cfg_custom, s_cfg_qpi, s_size_long};
							state_next = 3'd0;
						end
						else begin
							s_update_qpi = 1'b1;
							tx_start_o = 1'b1;
							tx_customsize_o = s_cfg_custom;
							tx_qpi_o = s_cfg_qpi;
							s_qpi = s_cfg_qpi;
							tx_size_o = s_size_long;
							state_next = 3'd1;
						end
					end
					else if (is_cmd_rxd) begin
						if (r_rpt_cfg) begin
							s_rpt_do_read = 1'b1;
							s_rpt_update_read = 1'b1;
							s_rpt_read = {s_cfg_custom, s_cfg_qpi, s_size_long};
							state_next = 3'd0;
						end
						else begin
							s_update_qpi = 1'b1;
							rx_start_o = 1'b1;
							rx_customsize_o = s_cfg_custom;
							rx_qpi_o = s_cfg_qpi;
							s_qpi = s_cfg_qpi;
							rx_size_o = s_size_long;
							state_next = 3'd1;
						end
					end
					else if (is_cmd_ful) begin
						if (r_rpt_cfg) begin
							s_rpt_do_ful = 1'b1;
							s_rpt_update_ful = 1'b1;
							s_rpt_ful = s_size_long;
							state_next = 3'd0;
						end
						else begin
							s_is_ful = 1'b1;
							s_update_qpi = 1'b1;
							rx_start_o = 1'b1;
							s_qpi = 1'b0;
							rx_qpi_o = 1'b0;
							rx_size_o = s_size_long;
							tx_start_o = 1'b1;
							tx_customsize_o = s_cfg_custom;
							tx_qpi_o = 1'b0;
							tx_size_o = s_size_long;
							state_next = 3'd1;
						end
					end
					else if (is_cmd_rxc) begin
						if (r_rpt_cfg) begin
							s_rpt_do_rx_chk = 1'b1;
							s_rpt_update_rx_chk = 1'b1;
							s_rpt_rx_chk = {s_cfg_custom, s_cfg_qpi, s_size[3:0]};
							s_update_chk = 1'b1;
							state_next = 3'd0;
						end
						else
							state_next = 3'd0;
					end
					else if (is_cmd_rpt || is_cmd_rpe) begin
						s_update_rpt = 1'b1;
						if (is_cmd_rpt) begin
							state_next = 3'd0;
							s_rpt_num = s_size_long;
						end
						else
							state_next = 3'd5;
					end
					else if (is_cmd_eot) begin
						eot_o = s_gen_eot;
						state_next = 3'd7;
					end
				end
			end
			3'd4:
				if (udma_tx_data_valid_i) begin
					udma_tx_data_ready_o = 1'b1;
					s_rpt_update_addr = 1'b1;
					s_rpt_addr = {r_rpt_addr[37:32], udma_tx_data_i};
					state_next = 3'd0;
				end
			3'd5: begin
				s_is_repeating = 1'b1;
				s_rptstate_next = r_rptstate;
				state_next = 3'd5;
				if (r_rpt_num == 0) begin
					s_is_repeating = 1'b0;
					state_next = 3'd0;
				end
				else
					case (r_rptstate)
						4'd0: begin
							s_update_cs = 1'b1;
							s_rptstate_next = 4'd1;
						end
						4'd1: begin
							if (r_rpt_do_cmd) begin
								s_update_qpi = 1'b1;
								tx_start_o = 1'b1;
								tx_customsize_o = 1'b1;
								tx_qpi_o = r_rpt_cmd[20];
								tx_size_o = {12'h000, r_rpt_cmd[19:16]};
								state_next = 3'd1;
								tx_data_valid_o = 1'b1;
								tx_data_o = {r_rpt_cmd[15:0], 16'h0000};
							end
							s_rptstate_next = 4'd2;
						end
						4'd2: begin
							if (r_rpt_do_addr) begin
								s_update_qpi = 1'b1;
								tx_start_o = 1'b1;
								tx_customsize_o = 1'b1;
								tx_qpi_o = r_rpt_addr[37];
								tx_size_o = {11'h000, r_rpt_addr[36:32]};
								state_next = 3'd1;
								tx_data_valid_o = 1'b1;
								tx_data_o = {r_rpt_addr[31:0]};
							end
							s_rptstate_next = 4'd3;
						end
						4'd3: begin
							if (r_rpt_do_dummy) begin
								s_update_qpi = 1'b1;
								rx_start_o = 1'b1;
								rx_customsize_o = 1'b0;
								rx_qpi_o = 1'b0;
								rx_size_o = {11'h000, r_rpt_dummy};
								state_next = 3'd1;
								s_is_dummy = 1'b1;
							end
							s_rptstate_next = 4'd4;
						end
						4'd4: begin
							if (r_rpt_do_write) begin
								s_update_qpi = 1'b1;
								tx_start_o = 1'b1;
								tx_customsize_o = r_rpt_write[17];
								tx_qpi_o = r_rpt_write[16];
								tx_size_o = r_rpt_write[15:0];
								state_next = 3'd1;
							end
							s_rptstate_next = (r_rpt_do_rx_chk ? 4'd6 : 4'd5);
						end
						4'd5: begin
							if (r_rpt_do_read) begin
								s_update_qpi = 1'b1;
								rx_start_o = 1'b1;
								rx_customsize_o = r_rpt_read[17];
								rx_qpi_o = r_rpt_read[16];
								rx_size_o = r_rpt_read[15:0];
								state_next = 3'd1;
							end
							s_rptstate_next = 4'd7;
						end
						4'd6: begin
							if (r_rpt_do_rx_chk) begin
								s_update_qpi = 1'b1;
								rx_start_o = 1'b1;
								rx_customsize_o = r_rpt_rx_chk[5];
								rx_qpi_o = r_rpt_rx_chk[4];
								rx_size_o = {12'h000, r_rpt_rx_chk[3:0]};
								state_next = 3'd2;
							end
							s_rptstate_next = 4'd7;
						end
						4'd7: s_rptstate_next = 4'd8;
						4'd8: begin
							s_clear_cs = 1'b1;
							s_rptstate_next = 4'd0;
							s_rpt_num = r_rpt_num - 1;
							if (r_chk_result)
								state_next = 3'd0;
							else if (r_rpt_do_wait)
								state_next = 3'd3;
						end
						default: s_rptstate_next = 4'd0;
					endcase
			end
			3'd1: begin
				if (s_done) begin
					if (r_is_repeating)
						state_next = 3'd5;
					else
						state_next = 3'd0;
					s_is_dummy = 1'b0;
				end
				tx_data_o = udma_tx_data_i;
				tx_data_valid_o = udma_tx_data_valid_i;
				udma_tx_data_ready_o = tx_data_ready_i;
				udma_rx_data_o = rx_data_i;
				udma_rx_data_valid_o = (r_is_dummy ? 1'b0 : rx_data_valid_i);
				rx_data_ready_o = udma_rx_data_ready_i;
			end
			3'd2: begin
				if (rx_done_i) begin
					if (r_is_repeating)
						state_next = 3'd5;
					else
						state_next = 3'd0;
					s_is_dummy = 1'b0;
				end
				if (rx_data_valid_i) begin
					s_update_chk_result = 1'b1;
					case (r_chk_type)
						2'b00:
							if (rx_data_i[15:0] == r_chk)
								s_chk_result = 1'b1;
						2'b01:
							if ((rx_data_i[15:0] & r_chk) == r_chk)
								s_chk_result = 1'b1;
						2'b10:
							if ((~rx_data_i[15:0] & ~r_chk) == ~r_chk)
								s_chk_result = 1'b1;
						default: s_chk_result = 1'b0;
					endcase
				end
				rx_data_ready_o = 1'b1;
			end
			3'd3:
				if (s_event) begin
					if (r_is_repeating)
						state_next = 3'd5;
					else
						state_next = 3'd0;
				end
			3'd6:
				if (s_cnt_done)
					state_next = 3'd0;
			3'd7: begin
				s_clear_cs = 1'b1;
				state_next = 3'd0;
			end
			default: state_next = 3'd0;
		endcase
	end
	always @(posedge clk_i or negedge rstn_i) begin : proc_r_chk_result
		if (~rstn_i)
			r_chk_result <= 0;
		else if (s_update_chk_result)
			r_chk_result <= s_chk_result;
	end
	always @(posedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0) begin
			state <= 3'd0;
			r_rptstate <= 4'd0;
		end
		else begin
			state <= state_next;
			r_rptstate <= s_rptstate_next;
		end
	always @(posedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0) begin
			r_cfg_cpol <= 1'b0;
			r_cfg_cpha <= 1'b0;
			r_cfg_clkdiv <= 'h0;
		end
		else if (s_update_cfg) begin
			r_cfg_cpol <= s_cfg_cpol;
			r_cfg_cpha <= s_cfg_cpha;
			r_cfg_clkdiv <= s_cfg_clkdiv;
		end
	always @(posedge clk_i or negedge rstn_i) begin : proc_r_update_cfg
		if (~rstn_i)
			r_update_cfg <= 0;
		else
			r_update_cfg <= s_update_cfg;
	end
	always @(posedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0) begin
			r_qpi <= 1'b0;
			r_is_dummy <= 1'b0;
			r_evt_sel <= 'h0;
			r_is_ful <= 1'b0;
			r_tx_done <= 1'b0;
			r_rx_done <= 1'b0;
			r_chk_type <= 0;
			r_chk <= 0;
		end
		else begin
			r_is_ful <= s_is_ful;
			r_tx_done <= tx_done_i;
			r_rx_done <= rx_done_i;
			if (s_update_chk) begin
				r_chk_type <= s_cfg_chk_type;
				r_chk <= s_cfg_check;
			end
			if (s_update_qpi)
				r_qpi <= s_qpi;
			if (s_update_evt)
				r_evt_sel <= s_evt_sel;
			r_is_dummy <= s_is_dummy;
		end
	always @(posedge clk_i or negedge rstn_i) begin : proc_rpt
		if (~rstn_i) begin
			r_rpt_cmd <= 0;
			r_rpt_addr <= 0;
			r_rpt_dummy <= 0;
			r_rpt_write <= 0;
			r_rpt_read <= 0;
			r_rpt_ful <= 0;
			r_rpt_do_cmd <= 0;
			r_rpt_do_addr <= 0;
			r_rpt_do_dummy <= 0;
			r_rpt_do_write <= 0;
			r_rpt_do_read <= 0;
			r_rpt_do_wait <= 0;
			r_rpt_do_rx_chk <= 0;
			r_rpt_do_ful <= 0;
			r_rpt_num <= 0;
			r_rpt_cfg <= 0;
			r_is_repeating <= 0;
			r_rpt_rx_chk <= 0;
			r_rpt_cs <= 0;
		end
		else begin
			r_rpt_num <= s_rpt_num;
			r_is_repeating <= s_is_repeating;
			if (s_update_rpt) begin
				if (is_cmd_rpt)
					r_rpt_cfg <= 1'b1;
				else
					r_rpt_cfg <= 1'b0;
			end
			if (s_rpt_update_cs)
				r_rpt_cs <= s_rpt_cs;
			if (s_rpt_update_cmd)
				r_rpt_cmd <= s_rpt_cmd;
			if (s_rpt_update_addr)
				r_rpt_addr <= s_rpt_addr;
			if (s_rpt_update_dummy)
				r_rpt_dummy <= s_rpt_dummy;
			if (s_rpt_update_write)
				r_rpt_write <= s_rpt_write;
			if (s_rpt_update_read)
				r_rpt_read <= s_rpt_read;
			if (s_rpt_update_ful)
				r_rpt_ful <= s_rpt_ful;
			if (s_rpt_update_rx_chk)
				r_rpt_rx_chk <= s_rpt_rx_chk;
			r_rpt_do_cmd <= s_rpt_do_cmd;
			r_rpt_do_addr <= s_rpt_do_addr;
			r_rpt_do_dummy <= s_rpt_do_dummy;
			r_rpt_do_write <= s_rpt_do_write;
			r_rpt_do_read <= s_rpt_do_read;
			r_rpt_do_wait <= s_rpt_do_wait;
			r_rpt_do_rx_chk <= s_rpt_do_rx_chk;
			r_rpt_do_ful <= s_rpt_do_ful;
		end
	end
	assign s_cs = (s_is_repeating | r_is_repeating ? r_rpt_cs : s_cfg_cs);
	always @(posedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0) begin
			spi_csn0_o <= 1'b1;
			spi_csn1_o <= 1'b1;
			spi_csn2_o <= 1'b1;
			spi_csn3_o <= 1'b1;
		end
		else if (s_update_cs)
			case (s_cs)
				2'b00: spi_csn0_o <= 1'b0;
				2'b01: spi_csn1_o <= 1'b0;
				2'b10: spi_csn2_o <= 1'b0;
				2'b11: spi_csn3_o <= 1'b0;
			endcase
		else if (s_clear_cs) begin
			spi_csn0_o <= 1'b1;
			spi_csn1_o <= 1'b1;
			spi_csn2_o <= 1'b1;
			spi_csn3_o <= 1'b1;
		end
	initial _sv2v_0 = 0;
endmodule
