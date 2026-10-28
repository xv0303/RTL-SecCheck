module amo_shim (
	clk_i,
	rst_ni,
	in_req_i,
	in_gnt_o,
	in_add_i,
	in_amo_i,
	in_wen_i,
	in_wdata_i,
	in_be_i,
	in_rdata_o,
	out_req_o,
	out_add_o,
	out_wen_o,
	out_wdata_o,
	out_be_o,
	out_rdata_i
);
	reg _sv2v_0;
	parameter [31:0] AddrMemWidth = 32;
	input wire clk_i;
	input wire rst_ni;
	input wire in_req_i;
	output reg in_gnt_o;
	input wire [AddrMemWidth - 1:0] in_add_i;
	input wire [3:0] in_amo_i;
	input wire in_wen_i;
	input wire [63:0] in_wdata_i;
	input wire [7:0] in_be_i;
	output reg [63:0] in_rdata_o;
	output reg out_req_o;
	output reg [AddrMemWidth - 1:0] out_add_o;
	output reg out_wen_o;
	output reg [63:0] out_wdata_o;
	output reg [7:0] out_be_o;
	input wire [63:0] out_rdata_i;
	reg state_q;
	reg [3:0] amo_op_q;
	reg load_amo;
	reg [AddrMemWidth - 1:0] addr_q;
	wire [31:0] amo_operand_a;
	reg [31:0] amo_operand_b_q;
	reg upper_word_q;
	reg [31:0] swap_value_q;
	reg [31:0] amo_result;
	reg [AddrMemWidth - 1:0] reserv_q;
	reg [AddrMemWidth - 1:0] reserv_d;
	reg reserv_valid_q;
	reg reserv_valid_d;
	wire sc_ok;
	assign amo_operand_a = (upper_word_q ? out_rdata_i[63:32] : out_rdata_i[31:0]);
	assign sc_ok = reserv_valid_q && (reserv_q == addr_q);
	always @(*) begin
		if (_sv2v_0)
			;
		out_req_o = in_req_i;
		in_gnt_o = in_req_i;
		out_add_o = in_add_i;
		out_wen_o = in_wen_i;
		out_wdata_o = in_wdata_i;
		out_be_o = in_be_i;
		in_rdata_o = out_rdata_i;
		load_amo = 1'b0;
		reserv_d = reserv_q;
		reserv_valid_d = reserv_valid_q;
		(* full_case, parallel_case *)
		case (state_q)
			1'd0:
				if (in_req_i && (in_amo_i == 4'hb)) begin
					reserv_d = in_add_i;
					reserv_valid_d = 1'b1;
				end
				else if (in_req_i && (in_amo_i != 4'h0)) begin
					load_amo = 1'b1;
					out_wen_o = 1'b0;
				end
			1'd1: begin
				in_gnt_o = 1'b0;
				if (amo_op_q != 4'hb) begin
					out_req_o = 1'b1;
					out_add_o = addr_q;
					out_wen_o = 1'b1;
					out_be_o = (upper_word_q ? 8'b11110000 : 8'b00001111);
					out_wdata_o = (upper_word_q ? {amo_result, 32'b00000000000000000000000000000000} : {32'b00000000000000000000000000000000, amo_result});
				end
				if (amo_op_q == 4'hc) begin
					in_rdata_o = (upper_word_q ? {{31 {1'b0}}, ~sc_ok, 32'b00000000000000000000000000000000} : {{63 {1'b0}}, ~sc_ok});
					reserv_valid_d = 1'b0;
				end
				else
					in_rdata_o = (upper_word_q ? {amo_operand_a, 32'b00000000000000000000000000000000} : {32'b00000000000000000000000000000000, amo_operand_a});
			end
			default:
				;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			state_q <= 1'd0;
			amo_op_q <= 4'b0000;
			addr_q <= 1'sb0;
			amo_operand_b_q <= 1'sb0;
			swap_value_q <= 1'sb0;
			upper_word_q <= 1'sb0;
			reserv_q <= 1'sb0;
			reserv_valid_q <= 1'sb0;
		end
		else begin
			reserv_q <= reserv_d;
			reserv_valid_q <= reserv_valid_d;
			if (load_amo) begin
				amo_op_q <= in_amo_i;
				addr_q <= in_add_i;
				amo_operand_b_q <= (in_be_i[0] ? in_wdata_i[31:0] : in_wdata_i[63:32]);
				swap_value_q <= (in_be_i[0] ? in_wdata_i[63:32] : in_wdata_i[63:32]);
				state_q <= 1'd1;
				upper_word_q <= in_be_i[4];
			end
			else begin
				amo_op_q <= 4'h0;
				state_q <= 1'd0;
			end
		end
	wire [33:0] adder_sum;
	reg [32:0] adder_operand_a;
	reg [32:0] adder_operand_b;
	assign adder_sum = adder_operand_a + adder_operand_b;
	function automatic signed [32:0] sv2v_cast_33_signed;
		input reg signed [32:0] inp;
		sv2v_cast_33_signed = inp;
	endfunction
	function automatic [32:0] sv2v_cast_33;
		input reg [32:0] inp;
		sv2v_cast_33 = inp;
	endfunction
	always @(*) begin : amo_alu
		if (_sv2v_0)
			;
		adder_operand_a = sv2v_cast_33_signed($signed(amo_operand_a));
		adder_operand_b = sv2v_cast_33_signed($signed(amo_operand_b_q));
		amo_result = amo_operand_b_q;
		(* full_case, parallel_case *)
		case (amo_op_q)
			4'h1:
				;
			4'hb:
				;
			4'h2: amo_result = adder_sum[31:0];
			4'h3: amo_result = amo_operand_a & amo_operand_b_q;
			4'h4: amo_result = amo_operand_a | amo_operand_b_q;
			4'h5: amo_result = amo_operand_a ^ amo_operand_b_q;
			4'h6: begin
				adder_operand_b = -$signed(amo_operand_b_q);
				amo_result = (adder_sum[32] ? amo_operand_b_q : amo_operand_a);
			end
			4'h8: begin
				adder_operand_b = -$signed(amo_operand_b_q);
				amo_result = (adder_sum[32] ? amo_operand_a : amo_operand_b_q);
			end
			4'h7: begin
				adder_operand_a = sv2v_cast_33($unsigned(amo_operand_a));
				adder_operand_b = -$unsigned(amo_operand_b_q);
				amo_result = (adder_sum[32] ? amo_operand_b_q : amo_operand_a);
			end
			4'h9: begin
				adder_operand_a = sv2v_cast_33($unsigned(amo_operand_a));
				adder_operand_b = -$unsigned(amo_operand_b_q);
				amo_result = (adder_sum[32] ? amo_operand_a : amo_operand_b_q);
			end
			4'ha: begin
				adder_operand_b = -$signed(amo_operand_b_q);
				if (adder_sum == {34 {1'sb0}})
					amo_result = swap_value_q;
				else
					amo_result = (upper_word_q ? out_rdata_i[63:32] : out_rdata_i[31:0]);
			end
			4'hc:
				if (sc_ok)
					amo_result = amo_operand_b_q;
				else
					amo_result = (upper_word_q ? out_rdata_i[63:32] : out_rdata_i[31:0]);
			default: amo_result = 1'sb0;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
