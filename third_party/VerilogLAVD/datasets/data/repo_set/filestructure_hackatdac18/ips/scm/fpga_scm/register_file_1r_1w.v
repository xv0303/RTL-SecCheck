module register_file_1r_1w (
	clk,
	rst_n,
	ReadEnable,
	ReadAddr,
	ReadData,
	WriteAddr,
	WriteEnable,
	WriteData
);
	reg _sv2v_0;
	parameter ADDR_WIDTH = 5;
	parameter DATA_WIDTH = 64;
	parameter BLOCK_RAM = 1;
	input wire clk;
	input wire rst_n;
	input wire ReadEnable;
	input wire [ADDR_WIDTH - 1:0] ReadAddr;
	output reg [DATA_WIDTH - 1:0] ReadData;
	input wire [ADDR_WIDTH - 1:0] WriteAddr;
	input wire WriteEnable;
	input wire [DATA_WIDTH - 1:0] WriteData;
	localparam N_SCM_REGISTERS = 2 ** ADDR_WIDTH;
	generate
		if (BLOCK_RAM == 1) begin : block_ram_gen
			(* ram_style = "block" *) reg [DATA_WIDTH - 1:0] MemContent_int [0:N_SCM_REGISTERS - 1];
			reg [DATA_WIDTH - 1:0] ReadData_reg;
			reg ReadEnable_reg;
			always @(posedge clk) begin
				if (WriteEnable == 1'b1)
					MemContent_int[WriteAddr] <= WriteData;
				ReadData_reg <= MemContent_int[ReadAddr];
			end
			always @(posedge clk) ReadEnable_reg <= ReadEnable;
			wire [DATA_WIDTH:1] sv2v_tmp_2FB18;
			assign sv2v_tmp_2FB18 = (ReadEnable_reg == 1'b1 ? ReadData_reg : {DATA_WIDTH {1'sb0}});
			always @(*) ReadData = sv2v_tmp_2FB18;
		end
		else begin : distr_ram_gen
			reg [(N_SCM_REGISTERS * DATA_WIDTH) - 1:0] MemContent_int;
			reg [DATA_WIDTH - 1:0] ReadData_reg;
			always @(posedge clk or negedge rst_n)
				if (rst_n == 1'b0)
					ReadData_reg <= 1'sb0;
				else if (ReadEnable == 1'b1)
					ReadData_reg <= MemContent_int[ReadAddr * DATA_WIDTH+:DATA_WIDTH];
			always @(*) begin : register_read_port_behavioral
				if (_sv2v_0)
					;
				ReadData <= ReadData_reg;
			end
			always @(posedge clk or negedge rst_n)
				if (rst_n == 1'b0)
					MemContent_int <= 1'sb0;
				else if (WriteEnable == 1'b1)
					MemContent_int[WriteAddr * DATA_WIDTH+:DATA_WIDTH] <= WriteData;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
