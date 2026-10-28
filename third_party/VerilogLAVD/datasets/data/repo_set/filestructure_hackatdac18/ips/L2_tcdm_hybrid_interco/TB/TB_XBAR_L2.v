module TB_XBAR_L2;
	parameter N_CH0 = 5;
	parameter N_CH1 = 4;
	parameter N_SLAVE = 4;
	parameter N_BRIDGES = 2;
	parameter ID_WIDTH = N_CH0 + N_CH1;
	parameter AUX_WIDTH = 5;
	parameter ADDR_WIDTH = 32;
	parameter DATA_WIDTH = 32;
	parameter BE_WIDTH = DATA_WIDTH / 8;
	parameter ADDR_MEM_WIDTH = 12;
	reg clk;
	reg rst_n;
	reg [(N_CH0 + N_CH1) - 1:0] fetch_enable;
	wire [(N_CH0 + N_CH1) - 1:0] data_req_TGEN;
	wire [((N_CH0 + N_CH1) * ADDR_WIDTH) - 1:0] data_add_TGEN;
	wire [(N_CH0 + N_CH1) - 1:0] data_wen_TGEN;
	wire [((N_CH0 + N_CH1) * DATA_WIDTH) - 1:0] data_wdata_TGEN;
	wire [((N_CH0 + N_CH1) * BE_WIDTH) - 1:0] data_be_TGEN;
	wire [((N_CH0 + N_CH1) * AUX_WIDTH) - 1:0] data_aux_TGEN;
	wire [(N_CH0 + N_CH1) - 1:0] data_gnt_TGEN;
	wire [(N_CH0 + N_CH1) - 1:0] data_err_TGEN;
	wire [(N_CH0 + N_CH1) - 1:0] data_r_valid_TGEN;
	wire [((N_CH0 + N_CH1) * DATA_WIDTH) - 1:0] data_r_rdata_TGEN;
	wire [((N_CH0 + N_CH1) * AUX_WIDTH) - 1:0] data_r_aux_TGEN;
	wire [N_SLAVE - 1:0] data_req_MEM;
	wire [(N_SLAVE * ADDR_MEM_WIDTH) - 1:0] data_add_MEM;
	wire [N_SLAVE - 1:0] data_wen_MEM;
	wire [(N_SLAVE * DATA_WIDTH) - 1:0] data_wdata_MEM;
	wire [(N_SLAVE * BE_WIDTH) - 1:0] data_be_MEM;
	wire [(N_SLAVE * AUX_WIDTH) - 1:0] data_aux_MEM;
	wire [(N_SLAVE * ID_WIDTH) - 1:0] data_ID_MEM;
	wire [N_SLAVE - 1:0] data_gnt_MEM;
	wire [N_SLAVE - 1:0] data_r_valid_MEM;
	wire [N_SLAVE - 1:0] data_r_gnt_MEM;
	wire [(N_SLAVE * DATA_WIDTH) - 1:0] data_r_rdata_MEM;
	wire [(N_SLAVE * AUX_WIDTH) - 1:0] data_r_aux_MEM;
	wire [(N_SLAVE * ID_WIDTH) - 1:0] data_r_ID_MEM;
	wire [N_BRIDGES - 1:0] data_req_BRIDGE;
	wire [(N_BRIDGES * ADDR_WIDTH) - 1:0] data_add_BRIDGE;
	wire [N_BRIDGES - 1:0] data_wen_BRIDGE;
	wire [(N_BRIDGES * DATA_WIDTH) - 1:0] data_wdata_BRIDGE;
	wire [(N_BRIDGES * BE_WIDTH) - 1:0] data_be_BRIDGE;
	wire [(N_BRIDGES * AUX_WIDTH) - 1:0] data_aux_BRIDGE;
	wire [(N_BRIDGES * ID_WIDTH) - 1:0] data_ID_BRIDGE;
	wire [N_BRIDGES - 1:0] data_gnt_BRIDGE;
	wire [N_BRIDGES - 1:0] data_r_valid_BRIDGE;
	wire [N_BRIDGES - 1:0] data_r_gnt_BRIDGE;
	wire [(N_BRIDGES * DATA_WIDTH) - 1:0] data_r_rdata_BRIDGE;
	wire [(N_BRIDGES * AUX_WIDTH) - 1:0] data_r_aux_BRIDGE;
	wire [(N_BRIDGES * ID_WIDTH) - 1:0] data_r_ID_BRIDGE;
	XBAR_L2 #(
		.N_CH0(N_CH0),
		.N_CH1(N_CH1),
		.N_SLAVE(N_SLAVE),
		.N_BRIDGES(N_BRIDGES),
		.ID_WIDTH(ID_WIDTH),
		.AUX_WIDTH(AUX_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.BE_WIDTH(BE_WIDTH),
		.ADDR_MEM_WIDTH(ADDR_MEM_WIDTH)
	) DUT_i(
		.data_req_i(data_req_TGEN),
		.data_add_i(data_add_TGEN),
		.data_wen_i(data_wen_TGEN),
		.data_wdata_i(data_wdata_TGEN),
		.data_be_i(data_be_TGEN),
		.data_aux_i(data_aux_TGEN),
		.data_gnt_o(data_gnt_TGEN),
		.data_err_o(data_err_TGEN),
		.data_r_valid_o(data_r_valid_TGEN),
		.data_r_rdata_o(data_r_rdata_TGEN),
		.data_r_aux_o(data_r_aux_TGEN),
		.data_req_o(data_req_MEM),
		.data_add_o(data_add_MEM),
		.data_wen_o(data_wen_MEM),
		.data_wdata_o(data_wdata_MEM),
		.data_be_o(data_be_MEM),
		.data_aux_o(data_aux_MEM),
		.data_ID_o(data_ID_MEM),
		.data_gnt_i(1'sb1),
		.data_r_valid_i(data_r_valid_MEM),
		.data_r_gnt_o(data_r_gnt_MEM),
		.data_r_rdata_i(data_r_rdata_MEM),
		.data_r_aux_i(data_r_aux_MEM),
		.data_r_ID_i(data_r_ID_MEM),
		.data_bridge_req_o(data_req_BRIDGE),
		.data_bridge_add_o(data_add_BRIDGE),
		.data_bridge_wen_o(data_wen_BRIDGE),
		.data_bridge_wdata_o(data_wdata_BRIDGE),
		.data_bridge_be_o(data_be_BRIDGE),
		.data_bridge_aux_o(data_aux_BRIDGE),
		.data_bridge_ID_o(data_ID_BRIDGE),
		.data_bridge_gnt_i(data_gnt_BRIDGE),
		.data_bridge_r_valid_i(data_r_valid_BRIDGE),
		.data_bridge_r_gnt_o(data_r_gnt_BRIDGE),
		.data_bridge_r_rdata_i(data_r_rdata_BRIDGE),
		.data_bridge_r_aux_i(data_r_aux_BRIDGE),
		.data_bridge_r_ID_i(data_r_ID_BRIDGE),
		.clk(clk),
		.rst_n(rst_n)
	);
	always #(1.0) clk = ~clk;
	initial begin
		rst_n = 1'b1;
		clk = 1'b0;
		fetch_enable = 1'sb0;
		@(negedge clk)
			;
		@(negedge clk)
			;
		@(negedge clk)
			;
		rst_n = 1'b0;
		@(negedge clk)
			;
		@(negedge clk)
			;
		@(negedge clk)
			;
		rst_n = 1'b1;
		@(negedge clk)
			;
		@(negedge clk)
			;
		@(negedge clk)
			;
		@(negedge clk)
			;
		fetch_enable[0] = 1'b1;
	end
	genvar _gv_i_1;
	genvar _gv_j_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < N_SLAVE; _gv_i_1 = _gv_i_1 + 1) begin : MEM_CUTS
			localparam i = _gv_i_1;
			L2_SP_RAM #(
				.DATA_WIDTH(DATA_WIDTH),
				.ADDR_WIDTH(ADDR_MEM_WIDTH),
				.BE_WIDTH(BE_WIDTH),
				.AUX_WIDTH(AUX_WIDTH),
				.ID_WIDTH(ID_WIDTH)
			) MEM_CUTS(
				.CLK(clk),
				.RSTN(rst_n),
				.CEN(~data_req_MEM[i]),
				.WEN(data_wen_MEM[i]),
				.A(data_add_MEM[i * ADDR_MEM_WIDTH+:ADDR_MEM_WIDTH]),
				.D(data_wdata_MEM[i * DATA_WIDTH+:DATA_WIDTH]),
				.BE(data_be_MEM[i * BE_WIDTH+:BE_WIDTH]),
				.Q(data_r_rdata_MEM[i * DATA_WIDTH+:DATA_WIDTH]),
				.id_i(data_ID_MEM[i * ID_WIDTH+:ID_WIDTH]),
				.r_id_o(data_r_ID_MEM[i * ID_WIDTH+:ID_WIDTH]),
				.aux_i(data_aux_MEM[i * AUX_WIDTH+:AUX_WIDTH]),
				.r_aux_o(data_r_aux_MEM[i * AUX_WIDTH+:AUX_WIDTH]),
				.r_valid_o(data_r_valid_MEM[i])
			);
		end
		for (_gv_i_1 = 0; _gv_i_1 < N_BRIDGES; _gv_i_1 = _gv_i_1 + 1) begin : BRIDGES
			localparam i = _gv_i_1;
			L2_SP_RAM_STALL #(
				.DATA_WIDTH(DATA_WIDTH),
				.ADDR_WIDTH(ADDR_WIDTH),
				.BE_WIDTH(BE_WIDTH),
				.AUX_WIDTH(AUX_WIDTH),
				.ID_WIDTH(ID_WIDTH)
			) BRIDGES(
				.CLK(clk),
				.RSTN(rst_n),
				.CEN(~data_req_BRIDGE[i]),
				.WEN(data_wen_BRIDGE[i]),
				.A(data_add_BRIDGE[i * ADDR_WIDTH+:ADDR_WIDTH]),
				.D(data_wdata_BRIDGE[i * DATA_WIDTH+:DATA_WIDTH]),
				.BE(data_be_BRIDGE[i * BE_WIDTH+:BE_WIDTH]),
				.Q(data_r_rdata_BRIDGE[i * DATA_WIDTH+:DATA_WIDTH]),
				.gnt_o(data_gnt_BRIDGE[i]),
				.r_gnt_i(data_r_gnt_BRIDGE[i]),
				.id_i(data_ID_BRIDGE[i * ID_WIDTH+:ID_WIDTH]),
				.r_id_o(data_r_ID_BRIDGE[i * ID_WIDTH+:ID_WIDTH]),
				.aux_i(data_aux_BRIDGE[i * AUX_WIDTH+:AUX_WIDTH]),
				.r_aux_o(data_r_aux_BRIDGE[i * AUX_WIDTH+:AUX_WIDTH]),
				.r_valid_o(data_r_valid_BRIDGE[i])
			);
		end
		for (_gv_i_1 = 0; _gv_i_1 < N_CH0; _gv_i_1 = _gv_i_1 + 1) begin : FC_MASTER
			localparam i = _gv_i_1;
			TGEN_32 #(
				.ID_WIDTH(ID_WIDTH),
				.AUX_WIDTH(AUX_WIDTH),
				.ADDR_WIDTH(ADDR_WIDTH),
				.DATA_WIDTH(DATA_WIDTH),
				.BE_WIDTH(BE_WIDTH)
			) FC_MASTER_i(
				.data_req_o(data_req_TGEN[i]),
				.data_gnt_i(data_gnt_TGEN[i]),
				.data_add_o(data_add_TGEN[i * ADDR_WIDTH+:ADDR_WIDTH]),
				.data_wen_o(data_wen_TGEN[i]),
				.data_wdata_o(data_wdata_TGEN[i * DATA_WIDTH+:DATA_WIDTH]),
				.data_be_o(data_be_TGEN[i * BE_WIDTH+:BE_WIDTH]),
				.data_aux_o(data_aux_TGEN[i * AUX_WIDTH+:AUX_WIDTH]),
				.data_err_i(data_err_TGEN[i]),
				.data_r_valid_i(data_r_valid_TGEN[i]),
				.data_r_rdata_i(data_r_rdata_TGEN[i * DATA_WIDTH+:DATA_WIDTH]),
				.data_r_aux_i(data_r_aux_TGEN[i * AUX_WIDTH+:AUX_WIDTH]),
				.clk(clk),
				.rst_n(rst_n),
				.fetch_enable_i(fetch_enable[i])
			);
		end
		for (_gv_i_1 = N_CH0; _gv_i_1 < (N_CH1 + N_CH0); _gv_i_1 = _gv_i_1 + 1) begin : AXI_MASTER
			localparam i = _gv_i_1;
			TGEN_32 #(
				.ID_WIDTH(ID_WIDTH),
				.AUX_WIDTH(AUX_WIDTH),
				.ADDR_WIDTH(ADDR_WIDTH),
				.DATA_WIDTH(DATA_WIDTH),
				.BE_WIDTH(BE_WIDTH)
			) AXI_MASTER_i(
				.data_req_o(data_req_TGEN[i]),
				.data_gnt_i(data_gnt_TGEN[i]),
				.data_add_o(data_add_TGEN[i * ADDR_WIDTH+:ADDR_WIDTH]),
				.data_wen_o(data_wen_TGEN[i]),
				.data_wdata_o(data_wdata_TGEN[i * DATA_WIDTH+:DATA_WIDTH]),
				.data_be_o(data_be_TGEN[i * BE_WIDTH+:BE_WIDTH]),
				.data_aux_o(data_aux_TGEN[i * AUX_WIDTH+:AUX_WIDTH]),
				.data_err_i(data_err_TGEN[i]),
				.data_r_valid_i(data_r_valid_TGEN[i]),
				.data_r_rdata_i(data_r_rdata_TGEN[i * DATA_WIDTH+:DATA_WIDTH]),
				.data_r_aux_i(data_r_aux_TGEN[i * AUX_WIDTH+:AUX_WIDTH]),
				.clk(clk),
				.rst_n(rst_n),
				.fetch_enable_i(fetch_enable[i])
			);
		end
	endgenerate
endmodule
