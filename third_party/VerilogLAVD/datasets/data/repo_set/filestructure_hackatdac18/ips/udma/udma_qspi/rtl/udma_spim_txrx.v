module udma_spim_txrx (
	clk_i,
	rstn_i,
	cfg_cpol_i,
	cfg_cpha_i,
	tx_start_i,
	tx_size_i,
	tx_qpi_i,
	tx_customsize_i,
	tx_done_o,
	tx_data_i,
	tx_data_valid_i,
	tx_data_ready_o,
	rx_start_i,
	rx_size_i,
	rx_qpi_i,
	rx_customsize_i,
	rx_done_o,
	rx_data_o,
	rx_data_valid_o,
	rx_data_ready_i,
	spi_clk_o,
	spi_mode_o,
	spi_sdo0_o,
	spi_sdo1_o,
	spi_sdo2_o,
	spi_sdo3_o,
	spi_sdi0_i,
	spi_sdi1_i,
	spi_sdi2_i,
	spi_sdi3_i
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rstn_i;
	input wire cfg_cpol_i;
	input wire cfg_cpha_i;
	input wire tx_start_i;
	input wire [15:0] tx_size_i;
	input wire tx_qpi_i;
	input wire tx_customsize_i;
	output reg tx_done_o;
	input wire [31:0] tx_data_i;
	input wire tx_data_valid_i;
	output reg tx_data_ready_o;
	input wire rx_start_i;
	input wire [15:0] rx_size_i;
	input wire rx_qpi_i;
	input wire rx_customsize_i;
	output reg rx_done_o;
	output reg [31:0] rx_data_o;
	output reg rx_data_valid_o;
	input wire rx_data_ready_i;
	output wire spi_clk_o;
	output reg [1:0] spi_mode_o;
	output reg spi_sdo0_o;
	output reg spi_sdo1_o;
	output reg spi_sdo2_o;
	output reg spi_sdo3_o;
	input wire spi_sdi0_i;
	input wire spi_sdi1_i;
	input wire spi_sdi2_i;
	input wire spi_sdi3_i;
	reg [3:0] tx_state;
	reg [3:0] tx_state_next;
	reg [3:0] rx_state;
	reg [3:0] rx_state_next;
	reg [4:0] r_tx_counter_lo;
	reg [4:0] r_tx_counter_last;
	reg [10:0] r_tx_counter_hi;
	reg [4:0] s_tx_counter_lo;
	reg [10:0] s_tx_counter_hi;
	reg [4:0] r_rx_counter_lo;
	reg [4:0] r_rx_counter_last;
	reg [10:0] r_rx_counter_hi;
	reg [4:0] s_rx_counter_lo;
	reg [10:0] s_rx_counter_hi;
	reg [31:0] s_tx_shift_reg;
	reg [31:0] r_tx_shift_reg;
	reg [31:0] s_rx_shift_reg;
	reg [31:0] r_rx_shift_reg;
	wire [4:0] s_in_shift;
	reg s_tx_clken;
	reg s_rx_clken;
	reg r_rx_clken;
	reg r_tx_is_last;
	reg r_rx_is_last;
	reg s_tx_is_last;
	reg s_rx_is_last;
	reg s_sample_tx_in;
	reg s_sample_rx_in;
	reg s_tx_driving;
	wire s_spi_sdo0;
	wire s_spi_sdo1;
	wire s_spi_sdo2;
	wire s_spi_sdo3;
	reg [1:0] s_tx_mode;
	reg [1:0] s_rx_mode;
	wire [1:0] s_spi_mode;
	wire s_tx_lo_done;
	wire s_rx_lo_done;
	reg s_rx_idle;
	reg s_tx_idle;
	wire s_is_ful;
	reg r_is_ful;
	wire s_spi_clk;
	wire s_spi_clk_inv;
	wire s_clken;
	reg r_customsize;
	reg [4:0] s_tx_counter_bits;
	reg [4:0] r_tx_counter_bits;
	reg [4:0] s_rx_counter_bits;
	reg [4:0] r_rx_counter_bits;
	wire s_spi_clk_cpha0;
	wire s_clk_inv;
	wire s_spi_clk_cpha1;
	assign s_spi_sdo0 = (s_tx_driving ? (tx_qpi_i ? (r_customsize ? r_tx_shift_reg[28] : r_tx_shift_reg[4]) : (r_customsize ? r_tx_shift_reg[31] : r_tx_shift_reg[7])) : 1'b0);
	assign s_spi_sdo1 = (s_tx_driving & tx_qpi_i ? (r_customsize ? r_tx_shift_reg[29] : r_tx_shift_reg[5]) : 1'b0);
	assign s_spi_sdo2 = (s_tx_driving & tx_qpi_i ? (r_customsize ? r_tx_shift_reg[30] : r_tx_shift_reg[6]) : 1'b0);
	assign s_spi_sdo3 = (s_tx_driving & tx_qpi_i ? (r_customsize ? r_tx_shift_reg[31] : r_tx_shift_reg[7]) : 1'b0);
	assign s_clken = (s_is_ful ? s_tx_clken : s_tx_clken | s_rx_clken);
	assign s_in_shift = tx_size_i[4:0];
	assign s_spi_mode = (s_tx_driving ? s_tx_mode : s_rx_mode);
	assign s_tx_lo_done = (tx_qpi_i ? r_tx_counter_lo == 3 : r_tx_counter_lo == 0);
	assign s_rx_lo_done = (rx_qpi_i ? r_rx_counter_lo == 3 : r_rx_counter_lo == 0);
	assign s_is_ful = (tx_start_i & rx_start_i) | r_is_ful;
	pulp_clock_gating u_outclkgte_cpol(
		.clk_i(clk_i),
		.en_i(s_clken),
		.test_en_i(1'b0),
		.clk_o(s_spi_clk_cpha0)
	);
	pulp_clock_inverter u_clkinv_cpha(
		.clk_i(clk_i),
		.clk_o(s_clk_inv)
	);
	pulp_clock_gating u_outclkgte_cpha(
		.clk_i(s_clk_inv),
		.en_i(s_clken),
		.test_en_i(1'b0),
		.clk_o(s_spi_clk_cpha1)
	);
	pulp_clock_mux2 u_clockmux_cpha(
		.clk0_i(s_spi_clk_cpha0),
		.clk1_i(s_spi_clk_cpha1),
		.clk_sel_i(cfg_cpha_i),
		.clk_o(s_spi_clk)
	);
	pulp_clock_inverter u_clkinv_cpol(
		.clk_i(s_spi_clk),
		.clk_o(s_spi_clk_inv)
	);
	pulp_clock_mux2 u_clockmux_cpol(
		.clk0_i(s_spi_clk),
		.clk1_i(s_spi_clk_inv),
		.clk_sel_i(cfg_cpol_i),
		.clk_o(spi_clk_o)
	);
	always @(*) begin : proc_TX_SM
		if (_sv2v_0)
			;
		tx_state_next = tx_state;
		s_tx_clken = 1'b0;
		s_sample_tx_in = 1'b0;
		s_tx_counter_lo = r_tx_counter_lo;
		s_tx_counter_hi = r_tx_counter_hi;
		s_tx_counter_bits = r_tx_counter_bits;
		tx_done_o = 1'b0;
		s_tx_shift_reg = r_tx_shift_reg;
		tx_data_ready_o = 1'b0;
		s_tx_driving = 1'b0;
		s_tx_mode = 2'b11;
		s_tx_idle = 1'b0;
		s_tx_is_last = r_tx_is_last;
		case (tx_state)
			4'd0: begin
				s_tx_counter_bits = 'h0;
				if (tx_start_i) begin
					if (tx_size_i[15:5] == 0)
						s_tx_is_last = 1'b1;
					else
						s_tx_is_last = 1'b0;
					s_tx_driving = 1'b1;
					s_sample_tx_in = 1'b1;
					if (tx_data_valid_i) begin
						tx_data_ready_o = 1'b1;
						tx_state_next = 4'd1;
						s_tx_shift_reg = tx_data_i;
					end
					else
						tx_state_next = 4'd2;
				end
				else
					s_tx_idle = 1'b1;
			end
			4'd1: begin
				s_tx_driving = 1'b1;
				s_tx_clken = 1'b1;
				s_tx_mode = (tx_qpi_i ? 2'b10 : 2'b00);
				if (s_tx_lo_done && (r_tx_counter_hi == 0)) begin
					if (!r_customsize) begin
						if (tx_qpi_i) begin
							if (r_tx_counter_bits == 3'h1)
								s_tx_counter_bits = 'h0;
							else
								s_tx_counter_bits = r_tx_counter_bits + 1;
						end
						else if (r_tx_counter_bits == 3'h7)
							s_tx_counter_bits = 'h0;
						else
							s_tx_counter_bits = r_tx_counter_bits + 1;
					end
					if (r_tx_is_last) begin
						s_tx_is_last = 1'b0;
						tx_done_o = 1'b1;
						if (tx_start_i) begin
							s_sample_tx_in = 1'b1;
							if (tx_data_valid_i) begin
								tx_data_ready_o = 1'b1;
								tx_state_next = 4'd1;
								s_tx_shift_reg = tx_data_i;
							end
							else
								tx_state_next = 4'd2;
						end
						else
							tx_state_next = 4'd0;
					end
					else begin
						s_tx_counter_lo = r_tx_counter_last;
						s_tx_is_last = 1'b1;
						if (tx_data_valid_i) begin
							tx_data_ready_o = 1'b1;
							tx_state_next = 4'd1;
							s_tx_shift_reg = tx_data_i;
						end
						else
							tx_state_next = 4'd2;
					end
				end
				else if (s_tx_lo_done) begin
					s_tx_counter_hi = r_tx_counter_hi - 1;
					s_tx_counter_lo = 5'h1f;
					if (!r_customsize) begin
						if (tx_qpi_i) begin
							if (r_tx_counter_bits == 3'h1)
								s_tx_counter_bits = 'h0;
							else
								s_tx_counter_bits = r_tx_counter_bits + 1;
						end
						else if (r_tx_counter_bits == 3'h7)
							s_tx_counter_bits = 'h0;
						else
							s_tx_counter_bits = r_tx_counter_bits + 1;
					end
					if (tx_data_valid_i) begin
						tx_data_ready_o = 1'b1;
						tx_state_next = 4'd1;
						s_tx_shift_reg = tx_data_i;
					end
					else
						tx_state_next = 4'd2;
				end
				else begin
					s_tx_counter_lo = (tx_qpi_i ? r_tx_counter_lo - 5'd4 : r_tx_counter_lo - 5'd1);
					if (r_customsize)
						s_tx_shift_reg = (tx_qpi_i ? {r_tx_shift_reg[27:0], 4'b0000} : {r_tx_shift_reg[30:0], 1'b0});
					else if (tx_qpi_i) begin
						if (r_tx_counter_bits == 3'h1) begin
							s_tx_counter_bits = 'h0;
							s_tx_shift_reg = {8'h00, r_tx_shift_reg[31:8]};
						end
						else begin
							s_tx_counter_bits = r_tx_counter_bits + 1;
							s_tx_shift_reg = {r_tx_shift_reg[31:8], r_tx_shift_reg[3:0], 4'h0};
						end
					end
					else if (r_tx_counter_bits == 3'h7) begin
						s_tx_counter_bits = 'h0;
						s_tx_shift_reg = {8'h00, r_tx_shift_reg[31:8]};
					end
					else begin
						s_tx_counter_bits = r_tx_counter_bits + 1;
						s_tx_shift_reg = {r_tx_shift_reg[31:8], r_tx_shift_reg[6:0], 1'b0};
					end
				end
			end
			4'd2: begin
				s_tx_driving = 1'b1;
				s_tx_mode = (tx_qpi_i ? 2'b10 : 2'b00);
				if (tx_data_valid_i) begin
					tx_data_ready_o = 1'b1;
					tx_state_next = 4'd1;
					s_tx_shift_reg = tx_data_i;
				end
			end
		endcase
	end
	always @(*) begin : proc_RX_SM
		if (_sv2v_0)
			;
		rx_state_next = rx_state;
		s_rx_clken = 1'b0;
		rx_done_o = 1'b0;
		rx_data_o = 'h0;
		rx_data_valid_o = 1'b0;
		s_rx_mode = 2'b11;
		s_sample_rx_in = 1'b0;
		s_rx_counter_lo = r_rx_counter_lo;
		s_rx_counter_hi = r_rx_counter_hi;
		s_rx_counter_bits = r_rx_counter_bits;
		s_rx_shift_reg = r_rx_shift_reg;
		s_rx_idle = 1'b0;
		s_rx_is_last = r_rx_is_last;
		case (rx_state)
			4'd0:
				if (rx_start_i) begin
					s_rx_mode = (rx_qpi_i ? 2'b11 : 2'b01);
					s_sample_rx_in = 1'b1;
					rx_state_next = 4'd1;
					s_rx_shift_reg = r_rx_shift_reg;
					s_rx_counter_bits = 'h0;
					if (rx_size_i[15:5] == 0)
						s_rx_is_last = 1'b1;
					else
						s_rx_is_last = 1'b0;
				end
				else
					s_rx_idle = 1'b1;
			4'd1: begin
				s_rx_mode = (rx_qpi_i ? 2'b11 : 2'b01);
				s_rx_clken = 1'b1;
				if (!s_is_ful || (s_is_ful && s_tx_clken)) begin
					if (r_customsize)
						s_rx_shift_reg = (rx_qpi_i ? {r_rx_shift_reg[27:0], spi_sdi3_i, spi_sdi2_i, spi_sdi1_i, spi_sdi0_i} : {r_rx_shift_reg[30:0], spi_sdi0_i});
					else if (rx_qpi_i) begin
						case (r_rx_counter_bits)
							5'd0: s_rx_shift_reg = {r_rx_shift_reg[31:8], spi_sdi3_i, spi_sdi2_i, spi_sdi1_i, spi_sdi0_i, r_rx_shift_reg[3:0]};
							5'd1: s_rx_shift_reg = {r_rx_shift_reg[31:4], spi_sdi3_i, spi_sdi2_i, spi_sdi1_i, spi_sdi0_i};
							5'd2: s_rx_shift_reg = {r_rx_shift_reg[31:16], spi_sdi3_i, spi_sdi2_i, spi_sdi1_i, spi_sdi0_i, r_rx_shift_reg[11:0]};
							5'd3: s_rx_shift_reg = {r_rx_shift_reg[31:12], spi_sdi3_i, spi_sdi2_i, spi_sdi1_i, spi_sdi0_i, r_rx_shift_reg[7:0]};
							5'd4: s_rx_shift_reg = {r_rx_shift_reg[31:24], spi_sdi3_i, spi_sdi2_i, spi_sdi1_i, spi_sdi0_i, r_rx_shift_reg[19:0]};
							5'd5: s_rx_shift_reg = {r_rx_shift_reg[31:20], spi_sdi3_i, spi_sdi2_i, spi_sdi1_i, spi_sdi0_i, r_rx_shift_reg[15:0]};
							5'd6: s_rx_shift_reg = {spi_sdi3_i, spi_sdi2_i, spi_sdi1_i, spi_sdi0_i, r_rx_shift_reg[27:0]};
							5'd7: s_rx_shift_reg = {r_rx_shift_reg[31:28], spi_sdi3_i, spi_sdi2_i, spi_sdi1_i, spi_sdi0_i, r_rx_shift_reg[23:0]};
						endcase
						if (r_rx_counter_bits == 7)
							s_rx_counter_bits = 0;
						else
							s_rx_counter_bits = r_rx_counter_bits + 1;
					end
					else begin
						case (r_rx_counter_bits)
							5'd0: s_rx_shift_reg = {r_rx_shift_reg[31:8], spi_sdi0_i, r_rx_shift_reg[6:0]};
							5'd1: s_rx_shift_reg = {r_rx_shift_reg[31:7], spi_sdi0_i, r_rx_shift_reg[5:0]};
							5'd2: s_rx_shift_reg = {r_rx_shift_reg[31:6], spi_sdi0_i, r_rx_shift_reg[4:0]};
							5'd3: s_rx_shift_reg = {r_rx_shift_reg[31:5], spi_sdi0_i, r_rx_shift_reg[3:0]};
							5'd4: s_rx_shift_reg = {r_rx_shift_reg[31:4], spi_sdi0_i, r_rx_shift_reg[2:0]};
							5'd5: s_rx_shift_reg = {r_rx_shift_reg[31:3], spi_sdi0_i, r_rx_shift_reg[1:0]};
							5'd6: s_rx_shift_reg = {r_rx_shift_reg[31:2], spi_sdi0_i, r_rx_shift_reg[0]};
							5'd7: s_rx_shift_reg = {r_rx_shift_reg[31:1], spi_sdi0_i};
							5'd8: s_rx_shift_reg = {r_rx_shift_reg[31:16], spi_sdi0_i, r_rx_shift_reg[14:0]};
							5'd9: s_rx_shift_reg = {r_rx_shift_reg[31:15], spi_sdi0_i, r_rx_shift_reg[13:0]};
							5'd10: s_rx_shift_reg = {r_rx_shift_reg[31:14], spi_sdi0_i, r_rx_shift_reg[12:0]};
							5'd11: s_rx_shift_reg = {r_rx_shift_reg[31:13], spi_sdi0_i, r_rx_shift_reg[11:0]};
							5'd12: s_rx_shift_reg = {r_rx_shift_reg[31:12], spi_sdi0_i, r_rx_shift_reg[10:0]};
							5'd13: s_rx_shift_reg = {r_rx_shift_reg[31:11], spi_sdi0_i, r_rx_shift_reg[9:0]};
							5'd14: s_rx_shift_reg = {r_rx_shift_reg[31:10], spi_sdi0_i, r_rx_shift_reg[8:0]};
							5'd15: s_rx_shift_reg = {r_rx_shift_reg[31:9], spi_sdi0_i, r_rx_shift_reg[7:0]};
							5'd16: s_rx_shift_reg = {r_rx_shift_reg[31:24], spi_sdi0_i, r_rx_shift_reg[22:0]};
							5'd17: s_rx_shift_reg = {r_rx_shift_reg[31:23], spi_sdi0_i, r_rx_shift_reg[21:0]};
							5'd18: s_rx_shift_reg = {r_rx_shift_reg[31:22], spi_sdi0_i, r_rx_shift_reg[20:0]};
							5'd19: s_rx_shift_reg = {r_rx_shift_reg[31:21], spi_sdi0_i, r_rx_shift_reg[19:0]};
							5'd20: s_rx_shift_reg = {r_rx_shift_reg[31:20], spi_sdi0_i, r_rx_shift_reg[18:0]};
							5'd21: s_rx_shift_reg = {r_rx_shift_reg[31:19], spi_sdi0_i, r_rx_shift_reg[17:0]};
							5'd22: s_rx_shift_reg = {r_rx_shift_reg[31:18], spi_sdi0_i, r_rx_shift_reg[16:0]};
							5'd23: s_rx_shift_reg = {r_rx_shift_reg[31:17], spi_sdi0_i, r_rx_shift_reg[15:0]};
							5'd24: s_rx_shift_reg = {spi_sdi0_i, r_rx_shift_reg[30:0]};
							5'd25: s_rx_shift_reg = {r_rx_shift_reg[31], spi_sdi0_i, r_rx_shift_reg[29:0]};
							5'd26: s_rx_shift_reg = {r_rx_shift_reg[31:30], spi_sdi0_i, r_rx_shift_reg[28:0]};
							5'd27: s_rx_shift_reg = {r_rx_shift_reg[31:29], spi_sdi0_i, r_rx_shift_reg[27:0]};
							5'd28: s_rx_shift_reg = {r_rx_shift_reg[31:28], spi_sdi0_i, r_rx_shift_reg[26:0]};
							5'd29: s_rx_shift_reg = {r_rx_shift_reg[31:27], spi_sdi0_i, r_rx_shift_reg[25:0]};
							5'd30: s_rx_shift_reg = {r_rx_shift_reg[31:26], spi_sdi0_i, r_rx_shift_reg[24:0]};
							5'd31: s_rx_shift_reg = {r_rx_shift_reg[31:25], spi_sdi0_i, r_rx_shift_reg[23:0]};
						endcase
						if (r_rx_counter_bits == 5'd31)
							s_rx_counter_bits = 0;
						else
							s_rx_counter_bits = r_rx_counter_bits + 1;
					end
					s_rx_counter_lo = (rx_qpi_i ? r_rx_counter_lo - 5'd4 : r_rx_counter_lo - 5'd1);
					if (r_rx_clken) begin
						if (s_rx_lo_done) begin
							rx_data_o = s_rx_shift_reg;
							rx_data_valid_o = 1'b1;
						end
						if (s_rx_lo_done && (r_rx_counter_hi == 0)) begin
							if (r_rx_is_last) begin
								s_rx_is_last = 1'b0;
								rx_done_o = 1'b1;
								if (rx_start_i) begin
									s_sample_rx_in = 1'b1;
									rx_state_next = 4'd1;
								end
								else
									rx_state_next = 4'd0;
							end
							else begin
								s_rx_counter_lo = r_rx_counter_last;
								s_rx_is_last = 1'b1;
							end
						end
						else if (s_rx_lo_done) begin
							s_rx_counter_hi = r_rx_counter_hi - 1;
							s_rx_counter_lo = 5'h1f;
						end
						else
							s_rx_counter_lo = (rx_qpi_i ? r_rx_counter_lo - 5'd4 : r_rx_counter_lo - 5'd1);
					end
				end
			end
		endcase
	end
	always @(posedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0) begin
			rx_state <= 4'd0;
			tx_state <= 4'd0;
		end
		else begin
			rx_state <= rx_state_next;
			tx_state <= tx_state_next;
		end
	always @(posedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0) begin
			r_rx_is_last <= 1'b0;
			r_tx_is_last <= 1'b0;
		end
		else begin
			r_rx_is_last <= s_rx_is_last;
			r_tx_is_last <= s_tx_is_last;
		end
	always @(posedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0) begin
			r_tx_shift_reg <= 'h0;
			r_rx_shift_reg <= 'h0;
			r_tx_counter_bits <= 'h0;
			r_rx_counter_bits <= 'h0;
			r_tx_counter_last <= 'h0;
			r_rx_counter_last <= 'h0;
			r_tx_counter_lo <= 'h0;
			r_tx_counter_hi <= 'h0;
			r_rx_counter_lo <= 'h0;
			r_rx_counter_hi <= 'h0;
			r_rx_clken <= 1'b0;
			r_is_ful <= 1'b0;
			r_customsize <= 1'b0;
		end
		else begin
			r_rx_clken <= s_rx_clken;
			r_rx_shift_reg <= s_rx_shift_reg;
			r_tx_shift_reg <= s_tx_shift_reg;
			r_rx_counter_bits <= s_rx_counter_bits;
			r_tx_counter_bits <= s_tx_counter_bits;
			if (tx_start_i && rx_start_i)
				r_is_ful <= 1'b1;
			else if (s_tx_idle && s_rx_idle)
				r_is_ful <= 1'b0;
			if (s_sample_tx_in || s_sample_rx_in)
				r_customsize <= tx_customsize_i | rx_customsize_i;
			if (s_sample_tx_in) begin
				if (tx_size_i[15:5] == 0) begin
					r_tx_counter_lo <= tx_size_i[4:0];
					r_tx_counter_last <= 'h0;
					r_tx_counter_hi <= 'h0;
				end
				else begin
					r_tx_counter_lo <= 5'h1f;
					r_tx_counter_last <= tx_size_i[4:0];
					r_tx_counter_hi <= tx_size_i[15:5] - 1;
				end
			end
			else begin
				r_tx_counter_lo <= s_tx_counter_lo;
				r_tx_counter_hi <= s_tx_counter_hi;
			end
			if (s_sample_rx_in) begin
				if (rx_size_i[15:5] == 0) begin
					r_rx_counter_lo <= rx_size_i[4:0];
					r_rx_counter_last <= 'h0;
					r_rx_counter_hi <= 'h0;
				end
				else begin
					r_rx_counter_lo <= 5'h1f;
					r_rx_counter_last <= rx_size_i[4:0];
					r_rx_counter_hi <= rx_size_i[15:5] - 1;
				end
			end
			else begin
				r_rx_counter_lo <= s_rx_counter_lo;
				r_rx_counter_hi <= s_rx_counter_hi;
			end
		end
	always @(negedge clk_i or negedge rstn_i)
		if (rstn_i == 1'b0) begin
			spi_sdo0_o <= 1'b0;
			spi_sdo1_o <= 1'b0;
			spi_sdo2_o <= 1'b0;
			spi_sdo3_o <= 1'b0;
			spi_mode_o <= 2'b01;
		end
		else begin
			spi_sdo0_o <= s_spi_sdo0;
			if (tx_qpi_i) begin
				spi_sdo1_o <= s_spi_sdo1;
				spi_sdo2_o <= s_spi_sdo2;
				spi_sdo3_o <= s_spi_sdo3;
			end
			spi_mode_o <= s_spi_mode;
		end
	initial _sv2v_0 = 0;
endmodule
