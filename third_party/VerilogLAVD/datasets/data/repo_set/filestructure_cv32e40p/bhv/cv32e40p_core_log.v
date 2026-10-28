module cv32e40p_core_log (
	clk_i,
	is_decoding_i,
	illegal_insn_dec_i,
	hart_id_i,
	pc_id_i
);
	parameter COREV_PULP = 1;
	parameter COREV_CLUSTER = 0;
	parameter FPU = 0;
	parameter ZFINX = 0;
	parameter NUM_MHPMCOUNTERS = 1;
	input wire clk_i;
	input wire is_decoding_i;
	input wire illegal_insn_dec_i;
	input wire [31:0] hart_id_i;
	input wire [31:0] pc_id_i;
	initial $display("[cv32e40p_core]: COREV_PULP = %d, COREV_CLUSTER = %d, FPU %d, ZFINX %d, NUM_MHPMCOUNTERS %d", COREV_PULP, COREV_CLUSTER, FPU, ZFINX, NUM_MHPMCOUNTERS);
	always @(negedge clk_i)
		if (is_decoding_i && illegal_insn_dec_i)
			$display("%t: Illegal instruction (core %0d) at PC 0x%h:", $time, hart_id_i[3:0], pc_id_i);
endmodule
