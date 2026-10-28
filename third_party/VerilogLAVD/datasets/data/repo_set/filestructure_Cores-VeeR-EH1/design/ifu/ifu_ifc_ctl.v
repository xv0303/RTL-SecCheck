module ifu_ifc_ctl (
	clk,
	free_clk,
	active_clk,
	clk_override,
	rst_l,
	scan_mode,
	ic_hit_f2,
	ic_crit_wd_rdy,
	ifu_ic_mb_empty,
	ifu_fb_consume1,
	ifu_fb_consume2,
	dec_tlu_flush_noredir_wb,
	dec_tlu_dbg_halted,
	dec_tlu_pmu_fw_halted,
	exu_flush_final,
	exu_flush_path_final,
	ifu_bp_kill_next_f2,
	ifu_bp_btb_target_f2,
	ic_dma_active,
	ic_write_stall,
	dma_iccm_stall_any,
	dec_tlu_mrac_ff,
	ifc_fetch_uncacheable_f1,
	ifc_fetch_addr_f1,
	ifc_fetch_addr_f2,
	ifc_fetch_req_f1,
	ifc_fetch_req_f1_raw,
	ifc_fetch_req_f2,
	ifu_pmu_fetch_stall,
	ifc_iccm_access_f1,
	ifc_region_acc_fault_f1,
	ifc_dma_access_ok
);
	input wire clk;
	input wire free_clk;
	input wire active_clk;
	input wire clk_override;
	input wire rst_l;
	input wire scan_mode;
	input wire ic_hit_f2;
	input wire ic_crit_wd_rdy;
	input wire ifu_ic_mb_empty;
	input wire ifu_fb_consume1;
	input wire ifu_fb_consume2;
	input wire dec_tlu_flush_noredir_wb;
	input wire dec_tlu_dbg_halted;
	input wire dec_tlu_pmu_fw_halted;
	input wire exu_flush_final;
	input wire [31:1] exu_flush_path_final;
	input wire ifu_bp_kill_next_f2;
	input wire [31:1] ifu_bp_btb_target_f2;
	input wire ic_dma_active;
	input wire ic_write_stall;
	input wire dma_iccm_stall_any;
	input wire [31:0] dec_tlu_mrac_ff;
	output wire ifc_fetch_uncacheable_f1;
	output wire [31:1] ifc_fetch_addr_f1;
	output wire [31:1] ifc_fetch_addr_f2;
	output wire ifc_fetch_req_f1;
	output wire ifc_fetch_req_f1_raw;
	output wire ifc_fetch_req_f2;
	output wire ifu_pmu_fetch_stall;
	output wire ifc_iccm_access_f1;
	output wire ifc_region_acc_fault_f1;
	output wire ifc_dma_access_ok;
	wire [31:1] fetch_addr_bf;
	wire [31:1] miss_addr;
	wire [31:1] ifc_fetch_addr_f1_raw;
	wire [31:1] fetch_addr_next;
	wire [31:1] miss_addr_ns;
	wire [4:0] cacheable_select;
	wire [3:0] fb_write_f1;
	wire [3:0] fb_write_ns;
	wire ifc_fetch_req_bf;
	wire overflow_nc;
	wire fb_full_f1_ns;
	wire fb_full_f1;
	wire fb_right;
	wire fb_right2;
	wire fb_right3;
	wire fb_left;
	wire wfm;
	wire fetch_ns;
	wire idle;
	wire fetch_req_f2_ns;
	wire missff_en;
	wire fetch_crit_word;
	wire ic_crit_wd_rdy_d1;
	wire fetch_crit_word_d1;
	wire fetch_crit_word_d2;
	wire reset_delayed;
	wire reset_detect;
	wire reset_detected;
	wire sel_last_addr_bf;
	wire sel_miss_addr_bf;
	wire sel_btb_addr_bf;
	wire sel_next_addr_bf;
	wire miss_f2;
	wire miss_a;
	wire flush_fb;
	wire dma_iccm_stall_any_f;
	wire dec_tlu_halted_f;
	wire mb_empty_mod;
	wire goto_idle;
	wire leave_idle;
	wire ic_crit_wd_rdy_mod;
	wire miss_sel_flush;
	wire miss_sel_f2;
	wire miss_sel_f1;
	wire miss_sel_bf;
	wire fetch_bf_en;
	wire ifc_fetch_req_f2_raw;
	wire ifc_f2_clk;
	rvoclkhdr ifu_fa2_cgc(
		.en(ifc_fetch_req_f1 | clk_override),
		.l1clk(ifc_f2_clk),
		.*
	);
	wire [1:0] state;
	wire [1:0] next_state;
	wire dma_stall;
	assign dma_stall = ic_dma_active | dma_iccm_stall_any_f;
	rvdff #(2) reset_ff(
		.*,
		.clk(free_clk),
		.din({1'b1, reset_detect}),
		.dout({reset_detect, reset_detected})
	);
	assign reset_delayed = reset_detect ^ reset_detected;
	rvdff #(3) ran_ff(
		.*,
		.clk(free_clk),
		.din({dma_iccm_stall_any, dec_tlu_dbg_halted | dec_tlu_pmu_fw_halted, miss_f2}),
		.dout({dma_iccm_stall_any_f, dec_tlu_halted_f, miss_a})
	);
	assign ic_crit_wd_rdy_mod = ic_crit_wd_rdy & ~(fetch_crit_word_d2 & ~ifc_fetch_req_f2);
	assign fetch_crit_word = ((ic_crit_wd_rdy_mod & ~ic_crit_wd_rdy_d1) & ~exu_flush_final) & ~ic_write_stall;
	assign missff_en = ((((exu_flush_final | (~ic_hit_f2 & ifc_fetch_req_f2)) | ifu_bp_kill_next_f2) | fetch_crit_word_d1) | ifu_bp_kill_next_f2) | ((ifc_fetch_req_f2 & ~ifc_fetch_req_f1) & ~fetch_crit_word_d2);
	assign miss_sel_flush = exu_flush_final & ((((wfm | idle) & ~fetch_crit_word_d1) | dma_stall) | ic_write_stall);
	assign miss_sel_f2 = (~exu_flush_final & ~ic_hit_f2) & ifc_fetch_req_f2;
	assign miss_sel_f1 = ((((~exu_flush_final & ~miss_sel_f2) & ~ifc_fetch_req_f1) & ifc_fetch_req_f2) & ~fetch_crit_word_d2) & ~ifu_bp_kill_next_f2;
	assign miss_sel_bf = (~miss_sel_f2 & ~miss_sel_f1) & ~miss_sel_flush;
	assign miss_addr_ns[31:1] = ((({31 {miss_sel_flush}} & exu_flush_path_final[31:1]) | ({31 {miss_sel_f2}} & ifc_fetch_addr_f2[31:1])) | ({31 {miss_sel_f1}} & ifc_fetch_addr_f1[31:1])) | ({31 {miss_sel_bf}} & fetch_addr_bf[31:1]);
	rvdffe #(31) faddmiss_ff(
		.*,
		.en(missff_en),
		.din(miss_addr_ns[31:1]),
		.dout(miss_addr[31:1])
	);
	assign sel_last_addr_bf = ((~miss_sel_flush & ~ifc_fetch_req_f1) & ifc_fetch_req_f2) & ~ifu_bp_kill_next_f2;
	assign sel_miss_addr_bf = ((~miss_sel_flush & ~ifu_bp_kill_next_f2) & ~ifc_fetch_req_f1) & ~ifc_fetch_req_f2;
	assign sel_btb_addr_bf = ~miss_sel_flush & ifu_bp_kill_next_f2;
	assign sel_next_addr_bf = ~miss_sel_flush & ifc_fetch_req_f1;
	assign fetch_addr_bf[31:1] = (((({31 {miss_sel_flush}} & exu_flush_path_final[31:1]) | ({31 {sel_miss_addr_bf}} & miss_addr[31:1])) | ({31 {sel_btb_addr_bf}} & {ifu_bp_btb_target_f2[31:1]})) | ({31 {sel_last_addr_bf}} & {ifc_fetch_addr_f1[31:1]})) | ({31 {sel_next_addr_bf}} & {fetch_addr_next[31:1]});
	assign {overflow_nc, fetch_addr_next[31:1]} = {{1'b0, ifc_fetch_addr_f1[31:4]} + 29'b00000000000000000000000000001, 3'b000};
	assign ifc_fetch_req_bf = fetch_ns | fetch_crit_word;
	assign fetch_bf_en = fetch_ns | fetch_crit_word;
	assign miss_f2 = ifc_fetch_req_f2 & ~ic_hit_f2;
	assign mb_empty_mod = (((ifu_ic_mb_empty | exu_flush_final) & ~dma_stall) & ~miss_f2) & ~miss_a;
	assign goto_idle = exu_flush_final & dec_tlu_flush_noredir_wb;
	assign leave_idle = (exu_flush_final & ~dec_tlu_flush_noredir_wb) & idle;
	assign next_state[1] = ((((~state[1] & state[0]) & ~reset_delayed) & miss_f2) & ~goto_idle) | (((state[1] & ~reset_delayed) & ~mb_empty_mod) & ~goto_idle);
	assign next_state[0] = ((~goto_idle & leave_idle) | (state[0] & ~goto_idle)) | reset_delayed;
	assign flush_fb = exu_flush_final;
	assign fb_right = (((~ifu_fb_consume1 & ~ifu_fb_consume2) & miss_f2) | (((ifu_fb_consume1 & ~ifu_fb_consume2) & ~ifc_fetch_req_f1) & ~miss_f2)) | ((ifu_fb_consume2 & ifc_fetch_req_f1) & ~miss_f2);
	assign fb_right2 = ((ifu_fb_consume1 & ~ifu_fb_consume2) & miss_f2) | (ifu_fb_consume2 & ~ifc_fetch_req_f1);
	assign fb_right3 = ifu_fb_consume2 & miss_f2;
	assign fb_left = (ifc_fetch_req_f1 & ~(ifu_fb_consume1 | ifu_fb_consume2)) & ~miss_f2;
	assign fb_write_ns[3:0] = (((((({4 {flush_fb & ~ifc_fetch_req_f1}} & 4'b0001) | ({4 {flush_fb & ifc_fetch_req_f1}} & 4'b0010)) | ({4 {~flush_fb & fb_right}} & {1'b0, fb_write_f1[3:1]})) | ({4 {~flush_fb & fb_right2}} & {2'b00, fb_write_f1[3:2]})) | ({4 {~flush_fb & fb_right3}} & {3'b000, fb_write_f1[3]})) | ({4 {~flush_fb & fb_left}} & {fb_write_f1[2:0], 1'b0})) | ({4 {(((~flush_fb & ~fb_right) & ~fb_right2) & ~fb_left) & ~fb_right3}} & fb_write_f1[3:0]);
	assign fb_full_f1_ns = fb_write_ns[3];
	assign idle = state[1:0] == 2'b00;
	assign wfm = state[1:0] == 2'b11;
	assign fetch_ns = next_state[1:0] == 2'b01;
	rvdff #(2) fsm_ff(
		.*,
		.clk(active_clk),
		.din({next_state[1:0]}),
		.dout({state[1:0]})
	);
	rvdff #(5) fbwrite_ff(
		.*,
		.clk(active_clk),
		.din({fb_full_f1_ns, fb_write_ns[3:0]}),
		.dout({fb_full_f1, fb_write_f1[3:0]})
	);
	assign ifu_pmu_fetch_stall = wfm | (ifc_fetch_req_f1_raw & ((fb_full_f1 & ~((ifu_fb_consume2 | ifu_fb_consume1) | exu_flush_final)) | dma_stall));
	assign ifc_fetch_req_f1 = ((((ifc_fetch_req_f1_raw & ~ifu_bp_kill_next_f2) & ~(fb_full_f1 & ~((ifu_fb_consume2 | ifu_fb_consume1) | exu_flush_final))) & ~dma_stall) & ~ic_write_stall) & ~dec_tlu_flush_noredir_wb;
	assign fetch_req_f2_ns = ifc_fetch_req_f1 & ~miss_f2;
	rvdff #(2) req_ff(
		.*,
		.clk(active_clk),
		.din({ifc_fetch_req_bf, fetch_req_f2_ns}),
		.dout({ifc_fetch_req_f1_raw, ifc_fetch_req_f2_raw})
	);
	assign ifc_fetch_req_f2 = ifc_fetch_req_f2_raw & ~exu_flush_final;
	rvdffe #(31) faddrf1_ff(
		.*,
		.en(fetch_bf_en),
		.din(fetch_addr_bf[31:1]),
		.dout(ifc_fetch_addr_f1_raw[31:1])
	);
	rvdff #(31) faddrf2_ff(
		.*,
		.clk(ifc_f2_clk),
		.din(ifc_fetch_addr_f1[31:1]),
		.dout(ifc_fetch_addr_f2[31:1])
	);
	assign ifc_fetch_addr_f1[31:1] = ({31 {exu_flush_final}} & exu_flush_path_final[31:1]) | ({31 {~exu_flush_final}} & ifc_fetch_addr_f1_raw[31:1]);
	rvdff #(3) iccrit_ff(
		.*,
		.clk(active_clk),
		.din({ic_crit_wd_rdy_mod, fetch_crit_word, fetch_crit_word_d1}),
		.dout({ic_crit_wd_rdy_d1, fetch_crit_word_d1, fetch_crit_word_d2})
	);
	assign ifc_iccm_access_f1 = 1'b0;
	assign ifc_dma_access_ok = 1'b0;
	assign ifc_region_acc_fault_f1 = 1'b0;
	assign cacheable_select[4:0] = {ifc_fetch_addr_f1[31:28], 1'b0};
	assign ifc_fetch_uncacheable_f1 = ~dec_tlu_mrac_ff[cacheable_select];
endmodule
