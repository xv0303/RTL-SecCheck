module register_file_1w_64b_multi_port_read_32b (
	clk,
	rst_n,
	ReadEnable,
	ReadAddr,
	ReadData,
	WriteEnable,
	WriteAddr,
	WriteData
);
	parameter WADDR_WIDTH = 5;
	parameter WDATA_WIDTH = 64;
	parameter RDATA_WIDTH = 32;
	parameter RADDR_WIDTH = WADDR_WIDTH + $clog2(WDATA_WIDTH / RDATA_WIDTH);
	parameter N_READ = 4;
	parameter N_WRITE = 1;
	parameter W_N_ROWS = 2 ** WADDR_WIDTH;
	input wire clk;
	input wire rst_n;
	input wire [N_READ - 1:0] ReadEnable;
	input wire [(N_READ * RADDR_WIDTH) - 1:0] ReadAddr;
	output wire [(N_READ * RDATA_WIDTH) - 1:0] ReadData;
	input wire WriteEnable;
	input wire [WADDR_WIDTH - 1:0] WriteAddr;
	input wire [WDATA_WIDTH - 1:0] WriteData;
	wire [(N_READ * RDATA_WIDTH) - 1:0] ReadData_lo;
	wire [(N_READ * RDATA_WIDTH) - 1:0] ReadData_hi;
	reg [N_READ - 1:0] DEST;
	reg [31:0] j;
	genvar _gv_i_1;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			DEST <= 0;
		else
			for (j = 0; j < N_READ; j = j + 1)
				DEST[j] <= ReadAddr[j * RADDR_WIDTH];
	generate
		for (_gv_i_1 = 0; _gv_i_1 < N_READ; _gv_i_1 = _gv_i_1 + 1) begin : MUX
			localparam i = _gv_i_1;
			assign ReadData[i * RDATA_WIDTH+:RDATA_WIDTH] = (DEST[i] == 1'b0 ? ReadData_lo[i * RDATA_WIDTH+:RDATA_WIDTH] : ReadData_hi[i * RDATA_WIDTH+:RDATA_WIDTH]);
		end
		for (_gv_i_1 = 0; _gv_i_1 < N_READ; _gv_i_1 = _gv_i_1 + 1) begin : CUT
			localparam i = _gv_i_1;
			if (W_N_ROWS == 1) begin : genblk1
				register_file_1r_1w_1row #(
					.ADDR_WIDTH(WADDR_WIDTH),
					.DATA_WIDTH(RDATA_WIDTH),
					.BLOCK_RAM(1)
				) bram_cut_lo(
					.clk(clk),
					.rst_n(rst_n),
					.ReadEnable(ReadEnable[i]),
					.ReadAddr(ReadAddr[(i * RADDR_WIDTH) + ((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : ((RADDR_WIDTH - 1) + ((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : 3 - RADDR_WIDTH)) - 1)-:((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : 3 - RADDR_WIDTH)]),
					.ReadData(ReadData_lo[i * RDATA_WIDTH+:RDATA_WIDTH]),
					.WriteAddr(WriteAddr),
					.WriteEnable(WriteEnable),
					.WriteData(WriteData[31:0])
				);
				register_file_1r_1w_1row #(
					.ADDR_WIDTH(WADDR_WIDTH),
					.DATA_WIDTH(RDATA_WIDTH),
					.BLOCK_RAM(1)
				) bram_cut_hi(
					.clk(clk),
					.rst_n(rst_n),
					.ReadEnable(ReadEnable[i]),
					.ReadAddr(ReadAddr[(i * RADDR_WIDTH) + ((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : ((RADDR_WIDTH - 1) + ((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : 3 - RADDR_WIDTH)) - 1)-:((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : 3 - RADDR_WIDTH)]),
					.ReadData(ReadData_hi[i * RDATA_WIDTH+:RDATA_WIDTH]),
					.WriteAddr(WriteAddr),
					.WriteEnable(WriteEnable),
					.WriteData(WriteData[63:32])
				);
			end
			else begin : genblk1
				register_file_1r_1w #(
					.ADDR_WIDTH(WADDR_WIDTH),
					.DATA_WIDTH(RDATA_WIDTH),
					.BLOCK_RAM(1)
				) bram_cut_lo(
					.clk(clk),
					.rst_n(rst_n),
					.ReadEnable(ReadEnable[i]),
					.ReadAddr(ReadAddr[(i * RADDR_WIDTH) + ((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : ((RADDR_WIDTH - 1) + ((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : 3 - RADDR_WIDTH)) - 1)-:((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : 3 - RADDR_WIDTH)]),
					.ReadData(ReadData_lo[i * RDATA_WIDTH+:RDATA_WIDTH]),
					.WriteAddr(WriteAddr),
					.WriteEnable(WriteEnable),
					.WriteData(WriteData[31:0])
				);
				register_file_1r_1w #(
					.ADDR_WIDTH(WADDR_WIDTH),
					.DATA_WIDTH(RDATA_WIDTH),
					.BLOCK_RAM(1)
				) bram_cut_hi(
					.clk(clk),
					.rst_n(rst_n),
					.ReadEnable(ReadEnable[i]),
					.ReadAddr(ReadAddr[(i * RADDR_WIDTH) + ((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : ((RADDR_WIDTH - 1) + ((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : 3 - RADDR_WIDTH)) - 1)-:((RADDR_WIDTH - 1) >= 1 ? RADDR_WIDTH - 1 : 3 - RADDR_WIDTH)]),
					.ReadData(ReadData_hi[i * RDATA_WIDTH+:RDATA_WIDTH]),
					.WriteAddr(WriteAddr),
					.WriteEnable(WriteEnable),
					.WriteData(WriteData[63:32])
				);
			end
		end
	endgenerate
endmodule
