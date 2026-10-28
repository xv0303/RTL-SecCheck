module register_file_1r_1w_be (
	clk,
	rst_n,
	ReadEnable,
	ReadAddr,
	ReadData,
	WriteAddr,
	WriteEnable,
	WriteData,
	WriteBE
);
	reg _sv2v_0;
	parameter ADDR_WIDTH = 5;
	parameter DATA_WIDTH = 64;
	parameter NUM_BYTE = DATA_WIDTH / 8;
	input wire clk;
	input wire rst_n;
	input wire ReadEnable;
	input wire [ADDR_WIDTH - 1:0] ReadAddr;
	output reg [DATA_WIDTH - 1:0] ReadData;
	input wire [ADDR_WIDTH - 1:0] WriteAddr;
	input wire WriteEnable;
	input wire [(NUM_BYTE * (DATA_WIDTH / NUM_BYTE)) - 1:0] WriteData;
	input wire [NUM_BYTE - 1:0] WriteBE;
	localparam N_SCM_REGISTERS = 2 ** ADDR_WIDTH;
	(* ram_style = "block" *) reg [((N_SCM_REGISTERS * NUM_BYTE) * (DATA_WIDTH / NUM_BYTE)) - 1:0] MemContent_int;
	reg [DATA_WIDTH - 1:0] ReadData_reg;
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0)
			ReadData_reg <= 1'sb0;
		else if (ReadEnable == 1'b1)
			ReadData_reg <= MemContent_int[(DATA_WIDTH / NUM_BYTE) * (ReadAddr * NUM_BYTE)+:(DATA_WIDTH / NUM_BYTE) * NUM_BYTE];
	always @(*) begin : register_read_port_behavioral
		if (_sv2v_0)
			;
		ReadData <= ReadData_reg;
	end
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0)
			MemContent_int <= 1'sb0;
		else if (WriteEnable == 1'b1) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < NUM_BYTE; i = i + 1)
				if (WriteBE[i] == 1'b1)
					MemContent_int[((WriteAddr * NUM_BYTE) + i) * (DATA_WIDTH / NUM_BYTE)+:DATA_WIDTH / NUM_BYTE] <= WriteData[i * (DATA_WIDTH / NUM_BYTE)+:DATA_WIDTH / NUM_BYTE];
		end
	initial _sv2v_0 = 0;
endmodule
