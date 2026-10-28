module cv32e40p_obi_interface (
	clk,
	rst_n,
	trans_valid_i,
	trans_ready_o,
	trans_addr_i,
	trans_we_i,
	trans_be_i,
	trans_wdata_i,
	trans_atop_i,
	resp_valid_o,
	resp_rdata_o,
	resp_err_o,
	obi_req_o,
	obi_gnt_i,
	obi_addr_o,
	obi_we_o,
	obi_be_o,
	obi_wdata_o,
	obi_atop_o,
	obi_rdata_i,
	obi_rvalid_i,
	obi_err_i
);
	reg _sv2v_0;
	parameter TRANS_STABLE = 0;
	input wire clk;
	input wire rst_n;
	input wire trans_valid_i;
	output wire trans_ready_o;
	input wire [31:0] trans_addr_i;
	input wire trans_we_i;
	input wire [3:0] trans_be_i;
	input wire [31:0] trans_wdata_i;
	input wire [5:0] trans_atop_i;
	output wire resp_valid_o;
	output wire [31:0] resp_rdata_o;
	output wire resp_err_o;
	output reg obi_req_o;
	input wire obi_gnt_i;
	output reg [31:0] obi_addr_o;
	output reg obi_we_o;
	output reg [3:0] obi_be_o;
	output reg [31:0] obi_wdata_o;
	output reg [5:0] obi_atop_o;
	input wire [31:0] obi_rdata_i;
	input wire obi_rvalid_i;
	input wire obi_err_i;
	reg state_q;
	reg next_state;
	assign resp_valid_o = obi_rvalid_i;
	assign resp_rdata_o = obi_rdata_i;
	assign resp_err_o = obi_err_i;
	generate
		if (TRANS_STABLE) begin : gen_trans_stable
			wire [1:1] sv2v_tmp_E8019;
			assign sv2v_tmp_E8019 = trans_valid_i;
			always @(*) obi_req_o = sv2v_tmp_E8019;
			wire [32:1] sv2v_tmp_2DFD9;
			assign sv2v_tmp_2DFD9 = trans_addr_i;
			always @(*) obi_addr_o = sv2v_tmp_2DFD9;
			wire [1:1] sv2v_tmp_367C5;
			assign sv2v_tmp_367C5 = trans_we_i;
			always @(*) obi_we_o = sv2v_tmp_367C5;
			wire [4:1] sv2v_tmp_738B5;
			assign sv2v_tmp_738B5 = trans_be_i;
			always @(*) obi_be_o = sv2v_tmp_738B5;
			wire [32:1] sv2v_tmp_F8E9B;
			assign sv2v_tmp_F8E9B = trans_wdata_i;
			always @(*) obi_wdata_o = sv2v_tmp_F8E9B;
			wire [6:1] sv2v_tmp_E7AA9;
			assign sv2v_tmp_E7AA9 = trans_atop_i;
			always @(*) obi_atop_o = sv2v_tmp_E7AA9;
			assign trans_ready_o = obi_gnt_i;
			wire [1:1] sv2v_tmp_7058D;
			assign sv2v_tmp_7058D = 1'd0;
			always @(*) state_q = sv2v_tmp_7058D;
			wire [1:1] sv2v_tmp_B3134;
			assign sv2v_tmp_B3134 = 1'd0;
			always @(*) next_state = sv2v_tmp_B3134;
		end
		else begin : gen_no_trans_stable
			reg [31:0] obi_addr_q;
			reg obi_we_q;
			reg [3:0] obi_be_q;
			reg [31:0] obi_wdata_q;
			reg [5:0] obi_atop_q;
			always @(*) begin
				if (_sv2v_0)
					;
				next_state = state_q;
				case (state_q)
					1'd0:
						if (obi_req_o && !obi_gnt_i)
							next_state = 1'd1;
					1'd1:
						if (obi_gnt_i)
							next_state = 1'd0;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				if (state_q == 1'd0) begin
					obi_req_o = trans_valid_i;
					obi_addr_o = trans_addr_i;
					obi_we_o = trans_we_i;
					obi_be_o = trans_be_i;
					obi_wdata_o = trans_wdata_i;
					obi_atop_o = trans_atop_i;
				end
				else begin
					obi_req_o = 1'b1;
					obi_addr_o = obi_addr_q;
					obi_we_o = obi_we_q;
					obi_be_o = obi_be_q;
					obi_wdata_o = obi_wdata_q;
					obi_atop_o = obi_atop_q;
				end
			end
			always @(posedge clk or negedge rst_n)
				if (rst_n == 1'b0) begin
					state_q <= 1'd0;
					obi_addr_q <= 32'b00000000000000000000000000000000;
					obi_we_q <= 1'b0;
					obi_be_q <= 4'b0000;
					obi_wdata_q <= 32'b00000000000000000000000000000000;
					obi_atop_q <= 6'b000000;
				end
				else begin
					state_q <= next_state;
					if ((state_q == 1'd0) && (next_state == 1'd1)) begin
						obi_addr_q <= obi_addr_o;
						obi_we_q <= obi_we_o;
						obi_be_q <= obi_be_o;
						obi_wdata_q <= obi_wdata_o;
						obi_atop_q <= obi_atop_o;
					end
				end
			assign trans_ready_o = state_q == 1'd0;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
