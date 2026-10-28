module register_file_1r_1w_all (
	clk,
	ReadEnable,
	ReadAddr,
	ReadData,
	WriteEnable,
	WriteAddr,
	WriteData,
	WriteBE,
	MemContent
);
	reg _sv2v_0;
	parameter ADDR_WIDTH = 5;
	parameter DATA_WIDTH = 32;
	parameter NUM_BYTE = DATA_WIDTH / 8;
	input wire clk;
	input wire ReadEnable;
	input wire [ADDR_WIDTH - 1:0] ReadAddr;
	output wire [DATA_WIDTH - 1:0] ReadData;
	input wire WriteEnable;
	input wire [ADDR_WIDTH - 1:0] WriteAddr;
	input wire [(NUM_BYTE * 8) - 1:0] WriteData;
	input wire [NUM_BYTE - 1:0] WriteBE;
	output wire [((2 ** ADDR_WIDTH) * DATA_WIDTH) - 1:0] MemContent;
	localparam NUM_WORDS = 2 ** ADDR_WIDTH;
	reg [ADDR_WIDTH - 1:0] RAddrRegxDP;
	reg [NUM_WORDS - 1:0] RAddrOneHotxD;
	reg [(NUM_BYTE * 8) - 1:0] MemContentxDP [0:NUM_WORDS - 1];
	reg [(NUM_WORDS * NUM_BYTE) - 1:0] WAddrOneHotxD;
	wire [(NUM_WORDS * NUM_BYTE) - 1:0] ClocksxC;
	reg [(NUM_BYTE * 8) - 1:0] WDataIntxD;
	wire clk_int;
	reg [31:0] i;
	reg [31:0] j;
	reg [31:0] k;
	reg [31:0] l;
	reg [31:0] m;
	genvar _gv_x_1;
	genvar _gv_y_1;
	cluster_clock_gating CG_WE_GLOBAL(
		.clk_o(clk_int),
		.en_i(WriteEnable),
		.test_en_i(1'b0),
		.clk_i(clk)
	);
	always @(posedge clk) begin : p_RAddrReg
		if (ReadEnable)
			RAddrRegxDP <= ReadAddr;
	end
	always @(*) begin : p_RAD
		if (_sv2v_0)
			;
		RAddrOneHotxD = 1'sb0;
		RAddrOneHotxD[RAddrRegxDP] = 1'b1;
	end
	assign ReadData = MemContentxDP[RAddrRegxDP];
	always @(*) begin : p_WAD
		if (_sv2v_0)
			;
		for (i = 0; i < NUM_WORDS; i = i + 1)
			begin : p_WordIter
				for (j = 0; j < NUM_BYTE; j = j + 1)
					begin : p_ByteIter
						if (((WriteEnable == 1'b1) && (WriteBE[j] == 1'b1)) && (WriteAddr == i))
							WAddrOneHotxD[(i * NUM_BYTE) + j] = 1'b1;
						else
							WAddrOneHotxD[(i * NUM_BYTE) + j] = 1'b0;
					end
			end
	end
	generate
		for (_gv_x_1 = 0; _gv_x_1 < NUM_WORDS; _gv_x_1 = _gv_x_1 + 1) begin : CG_CELL_WORD_ITER
			localparam x = _gv_x_1;
			for (_gv_y_1 = 0; _gv_y_1 < NUM_BYTE; _gv_y_1 = _gv_y_1 + 1) begin : CG_CELL_BYTE_ITER
				localparam y = _gv_y_1;
				cluster_clock_gating CG_Inst(
					.clk_o(ClocksxC[(x * NUM_BYTE) + y]),
					.en_i(WAddrOneHotxD[(x * NUM_BYTE) + y]),
					.test_en_i(1'b0),
					.clk_i(clk_int)
				);
			end
		end
	endgenerate
	always @(posedge clk) begin : sample_waddr
		for (m = 0; m < NUM_BYTE; m = m + 1)
			if (WriteEnable & WriteBE[m])
				WDataIntxD[m * 8+:8] <= WriteData[m * 8+:8];
	end
	always @(*) begin : latch_wdata
		if (_sv2v_0)
			;
		for (k = 0; k < NUM_WORDS; k = k + 1)
			begin : w_WordIter
				for (l = 0; l < NUM_BYTE; l = l + 1)
					begin : w_ByteIter
						if (ClocksxC[(k * NUM_BYTE) + l] == 1'b1)
							MemContentxDP[k][l * 8+:8] = WDataIntxD[l * 8+:8];
					end
			end
	end
	genvar _gv_p_1;
	generate
		for (_gv_p_1 = 0; _gv_p_1 < NUM_WORDS; _gv_p_1 = _gv_p_1 + 1) begin : MemContentOut_Iter
			localparam p = _gv_p_1;
			assign MemContent[p * DATA_WIDTH+:DATA_WIDTH] = MemContentxDP[p];
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
