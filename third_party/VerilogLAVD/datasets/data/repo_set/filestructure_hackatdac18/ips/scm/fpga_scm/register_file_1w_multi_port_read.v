module register_file_1w_multi_port_read (
	clk,
	test_en_i,
	rst_n,
	ReadEnable,
	ReadAddr,
	ReadData,
	WriteEnable,
	WriteAddr,
	WriteData
);
	parameter ADDR_WIDTH = 5;
	parameter DATA_WIDTH = 32;
	parameter N_READ = 2;
	parameter N_WRITE = 1;
	parameter W_N_ROWS = 2 ** ADDR_WIDTH;
	input wire clk;
	input wire test_en_i;
	input wire rst_n;
	input wire [N_READ - 1:0] ReadEnable;
	input wire [(N_READ * ADDR_WIDTH) - 1:0] ReadAddr;
	output wire [(N_READ * DATA_WIDTH) - 1:0] ReadData;
	input wire WriteEnable;
	input wire [ADDR_WIDTH - 1:0] WriteAddr;
	input wire [DATA_WIDTH - 1:0] WriteData;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < N_READ; _gv_i_1 = _gv_i_1 + 1) begin : CUT
			localparam i = _gv_i_1;
			if (W_N_ROWS == 1) begin : genblk1
				register_file_1r_1w_1row #(.DATA_WIDTH(DATA_WIDTH)) bram_cut(
					.clk(clk),
					.ReadEnable(ReadEnable[i]),
					.ReadData(ReadData[i * DATA_WIDTH+:DATA_WIDTH]),
					.WriteEnable(WriteEnable),
					.WriteData(WriteData)
				);
			end
			else begin : genblk1
				register_file_1r_1w #(
					.ADDR_WIDTH(ADDR_WIDTH),
					.DATA_WIDTH(DATA_WIDTH)
				) bram_cut(
					.clk(clk),
					.ReadEnable(ReadEnable[i]),
					.ReadAddr(ReadAddr[i * ADDR_WIDTH+:ADDR_WIDTH]),
					.ReadData(ReadData[i * DATA_WIDTH+:DATA_WIDTH]),
					.WriteAddr(WriteAddr),
					.WriteEnable(WriteEnable),
					.WriteData(WriteData)
				);
			end
		end
	endgenerate
endmodule
