module insn_assert (
	clk_i,
	rst_ni,
	instr_req_o,
	instr_gnt_i,
	instr_rvalid_i
);
	input wire clk_i;
	input wire rst_ni;
	input wire instr_req_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	reg signed [31:0] s_outstanding_cnt;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			s_outstanding_cnt <= 0;
		else if ((instr_req_o & instr_gnt_i) & instr_rvalid_i)
			s_outstanding_cnt <= s_outstanding_cnt;
		else if (instr_req_o & instr_gnt_i)
			s_outstanding_cnt <= s_outstanding_cnt + 1;
		else if (instr_rvalid_i)
			s_outstanding_cnt <= s_outstanding_cnt - 1;
endmodule
