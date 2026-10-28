module register_file_1r_1w_all (
	clk,
	rst_n,
	ReadEnable,
	ReadAddr,
	ReadData,
	WriteAddr,
	WriteEnable,
	WriteData,
	WriteBE,
	MemContent
);
	reg _sv2v_0;
	parameter ADDR_WIDTH = 5;
	parameter DATA_WIDTH = 64;
	input wire clk;
	input wire rst_n;
	input wire ReadEnable;
	input wire [ADDR_WIDTH - 1:0] ReadAddr;
	output reg [DATA_WIDTH - 1:0] ReadData;
	input wire [ADDR_WIDTH - 1:0] WriteAddr;
	input wire WriteEnable;
	input wire [DATA_WIDTH - 1:0] WriteData;
	input wire [(DATA_WIDTH / 8) - 1:0] WriteBE;
	output wire [((2 ** ADDR_WIDTH) * DATA_WIDTH) - 1:0] MemContent;
	localparam N_SCM_REGISTERS = 2 ** ADDR_WIDTH;
	(* ram_style = "block" *) reg [(N_SCM_REGISTERS * DATA_WIDTH) - 1:0] MemContent_int;
	reg [DATA_WIDTH - 1:0] WriteData_int;
	assign MemContent = MemContent_int;
	always @(posedge clk or negedge rst_n) begin : register_read_port_behavioral
		if (rst_n == 1'b0)
			ReadData <= 1'sb0;
		else
			ReadData <= MemContent_int[ReadAddr * DATA_WIDTH+:DATA_WIDTH];
	end
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < (DATA_WIDTH / 8); _gv_i_1 = _gv_i_1 + 1) begin : be_proc
			localparam i = _gv_i_1;
			always @(*) begin : writa_data_be_reg
				if (_sv2v_0)
					;
				if (WriteBE[i] == 1'b1)
					WriteData_int[(i * 8) + 7:i * 8] = WriteData[(i * 8) + 7:i * 8];
				else
					WriteData_int[(i * 8) + 7:i * 8] = MemContent_int[(WriteAddr * DATA_WIDTH) + (((i * 8) + 7) >= (i * 8) ? (i * 8) + 7 : (((i * 8) + 7) + (((i * 8) + 7) >= (i * 8) ? (((i * 8) + 7) - (i * 8)) + 1 : ((i * 8) - ((i * 8) + 7)) + 1)) - 1)-:(((i * 8) + 7) >= (i * 8) ? (((i * 8) + 7) - (i * 8)) + 1 : ((i * 8) - ((i * 8) + 7)) + 1)];
			end
		end
	endgenerate
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0)
			MemContent_int <= 1'sb0;
		else if (WriteEnable == 1'b1)
			MemContent_int[WriteAddr * DATA_WIDTH+:DATA_WIDTH] <= WriteData_int;
	initial _sv2v_0 = 0;
endmodule
