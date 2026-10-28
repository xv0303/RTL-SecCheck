module xilinx_pll (
	clk_o,
	ref_clk_i,
	cfg_lock_o,
	cfg_req_i,
	cfg_ack_o,
	cfg_add_i,
	cfg_data_i,
	cfg_r_data_o,
	cfg_wrn_i,
	rstn_glob_i,
	test_mode_i,
	shift_enable_i
);
	output wire clk_o;
	input wire ref_clk_i;
	output wire cfg_lock_o;
	input wire cfg_req_i;
	output wire cfg_ack_o;
	input wire [1:0] cfg_add_i;
	input wire [31:0] cfg_data_i;
	output wire [31:0] cfg_r_data_o;
	input wire cfg_wrn_i;
	input wire rstn_glob_i;
	input wire test_mode_i;
	input wire shift_enable_i;
endmodule
