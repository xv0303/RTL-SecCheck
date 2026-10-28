module cv32e40p_tb_subsystem (
	clk_i,
	rst_ni,
	fetch_enable_i,
	tests_passed_o,
	tests_failed_o,
	exit_value_o,
	exit_valid_o
);
	parameter INSTR_RDATA_WIDTH = 32;
	parameter RAM_ADDR_WIDTH = 20;
	parameter BOOT_ADDR = 'h180;
	parameter PULP_XPULP = 0;
	parameter PULP_CLUSTER = 0;
	parameter FPU = 0;
	parameter FPU_ADDMUL_LAT = 0;
	parameter FPU_OTHERS_LAT = 0;
	parameter ZFINX = 0;
	parameter NUM_MHPMCOUNTERS = 1;
	parameter DM_HALTADDRESS = 32'h1a110800;
	input wire clk_i;
	input wire rst_ni;
	input wire fetch_enable_i;
	output wire tests_passed_o;
	output wire tests_failed_o;
	output wire [31:0] exit_value_o;
	output wire exit_valid_o;
	wire instr_req;
	wire instr_gnt;
	wire instr_rvalid;
	wire [31:0] instr_addr;
	wire [INSTR_RDATA_WIDTH - 1:0] instr_rdata;
	wire data_req;
	wire data_gnt;
	wire data_rvalid;
	wire [31:0] data_addr;
	wire data_we;
	wire [3:0] data_be;
	wire [31:0] data_rdata;
	wire [31:0] data_wdata;
	reg [5:0] data_atop = 6'b000000;
	wire debug_req_i;
	wire irq_ack;
	wire [4:0] irq_id_out;
	wire irq_software;
	wire irq_timer;
	wire irq_external;
	wire [15:0] irq_fast;
	wire core_sleep_o;
	assign debug_req_i = 1'b0;
	cv32e40p_top #(
		.PULP_XPULP(PULP_XPULP),
		.PULP_CLUSTER(PULP_CLUSTER),
		.FPU(FPU),
		.FPU_ADDMUL_LAT(FPU_ADDMUL_LAT),
		.FPU_OTHERS_LAT(FPU_OTHERS_LAT),
		.ZFINX(ZFINX),
		.NUM_MHPMCOUNTERS(NUM_MHPMCOUNTERS)
	) top_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.pulp_clock_en_i(1'b1),
		.scan_cg_en_i(1'b0),
		.boot_addr_i(BOOT_ADDR),
		.mtvec_addr_i(32'h00000000),
		.dm_halt_addr_i(DM_HALTADDRESS),
		.hart_id_i(32'h00000000),
		.dm_exception_addr_i(32'h00000000),
		.instr_addr_o(instr_addr),
		.instr_req_o(instr_req),
		.instr_rdata_i(instr_rdata),
		.instr_gnt_i(instr_gnt),
		.instr_rvalid_i(instr_rvalid),
		.data_addr_o(data_addr),
		.data_wdata_o(data_wdata),
		.data_we_o(data_we),
		.data_req_o(data_req),
		.data_be_o(data_be),
		.data_rdata_i(data_rdata),
		.data_gnt_i(data_gnt),
		.data_rvalid_i(data_rvalid),
		.irq_i({irq_fast, 4'b0000, irq_external, 3'b000, irq_timer, 3'b000, irq_software, 3'b000}),
		.irq_ack_o(irq_ack),
		.irq_id_o(irq_id_out),
		.debug_req_i(debug_req_i),
		.debug_havereset_o(),
		.debug_running_o(),
		.debug_halted_o(),
		.fetch_enable_i(fetch_enable_i),
		.core_sleep_o(core_sleep_o)
	);
	mm_ram #(
		.RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
		.INSTR_RDATA_WIDTH(INSTR_RDATA_WIDTH)
	) ram_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.instr_req_i(instr_req),
		.instr_addr_i(instr_addr[RAM_ADDR_WIDTH - 1:0]),
		.instr_rdata_o(instr_rdata),
		.instr_rvalid_o(instr_rvalid),
		.instr_gnt_o(instr_gnt),
		.data_req_i(data_req),
		.data_addr_i(data_addr),
		.data_we_i(data_we),
		.data_be_i(data_be),
		.data_wdata_i(data_wdata),
		.data_rdata_o(data_rdata),
		.data_rvalid_o(data_rvalid),
		.data_gnt_o(data_gnt),
		.data_atop_i(data_atop),
		.irq_id_i(irq_id_out),
		.irq_ack_i(irq_ack),
		.irq_software_o(irq_software),
		.irq_timer_o(irq_timer),
		.irq_external_o(irq_external),
		.irq_fast_o(irq_fast),
		.pc_core_id_i(top_i.core_i.pc_id),
		.tests_passed_o(tests_passed_o),
		.tests_failed_o(tests_failed_o),
		.exit_valid_o(exit_valid_o),
		.exit_value_o(exit_value_o)
	);
endmodule
