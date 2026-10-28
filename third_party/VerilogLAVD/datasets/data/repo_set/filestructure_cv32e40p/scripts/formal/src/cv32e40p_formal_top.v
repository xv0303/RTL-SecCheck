module cv32e40p_formal_top (
	clk_i,
	rst_ni,
	pulp_clock_en_i,
	scan_cg_en_i,
	boot_addr_i,
	mtvec_addr_i,
	dm_halt_addr_i,
	hart_id_i,
	dm_exception_addr_i,
	instr_req_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_o,
	instr_rdata_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	data_rdata_i,
	irq_i,
	irq_ack_o,
	irq_id_o,
	debug_req_i,
	debug_havereset_o,
	debug_running_o,
	debug_halted_o,
	fetch_enable_i,
	core_sleep_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire pulp_clock_en_i;
	input wire scan_cg_en_i;
	input wire [31:0] boot_addr_i;
	input wire [31:0] mtvec_addr_i;
	input wire [31:0] dm_halt_addr_i;
	input wire [31:0] hart_id_i;
	input wire [31:0] dm_exception_addr_i;
	output wire instr_req_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	output wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [31:0] data_wdata_o;
	input wire [31:0] data_rdata_i;
	input wire [31:0] irq_i;
	output wire irq_ack_o;
	output wire [4:0] irq_id_o;
	input wire debug_req_i;
	output wire debug_havereset_o;
	output wire debug_running_o;
	output wire debug_halted_o;
	input wire fetch_enable_i;
	output wire core_sleep_o;
	parameter COREV_PULP = 0;
	parameter FPU = 0;
	cv32e40p_top #(
		.COREV_PULP(COREV_PULP),
		.FPU(FPU)
	) u_cv32e40p_top(.*);
endmodule
