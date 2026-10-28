module register_file_2r_1w_asymm (
	clk,
	rst_n,
	ReadEnable_a,
	ReadAddr_a,
	ReadData_a,
	ReadEnable_b,
	ReadAddr_b,
	ReadData_b,
	WriteEnable,
	WriteAddr,
	WriteData,
	WriteBE
);
	reg _sv2v_0;
	parameter ADDR_WIDTH = 5;
	parameter DATA_WIDTH = 32;
	parameter NUM_BYTE = DATA_WIDTH / 8;
	parameter ASYMM_FACTOR = 3;
	input wire clk;
	input wire rst_n;
	input wire ReadEnable_a;
	input wire [ADDR_WIDTH - 1:0] ReadAddr_a;
	output reg [DATA_WIDTH - 1:0] ReadData_a;
	input wire ReadEnable_b;
	input wire [ADDR_WIDTH - 1:0] ReadAddr_b;
	output wire [(ASYMM_FACTOR * DATA_WIDTH) - 1:0] ReadData_b;
	input wire WriteEnable;
	input wire [ADDR_WIDTH - 1:0] WriteAddr;
	input wire [(NUM_BYTE * 8) - 1:0] WriteData;
	input wire [NUM_BYTE - 1:0] WriteBE;
	localparam NUM_WORDS = 2 ** ADDR_WIDTH;
	(* ram_style = "block" *) reg [(NUM_WORDS * DATA_WIDTH) - 1:0] rf_reg;
	wire [(NUM_WORDS * (ASYMM_FACTOR * DATA_WIDTH)) - 1:0] rf_reg_as;
	reg [NUM_WORDS - 1:0] we_dec;
	reg [ADDR_WIDTH - 1:0] ReadAddr_b_reg;
	always @(*) begin : we_decoder
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < NUM_WORDS; i = i + 1)
				if (WriteAddr == i)
					we_dec[i] <= WriteEnable;
				else
					we_dec[i] <= 1'b0;
		end
	end
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < NUM_WORDS; _gv_i_1 = _gv_i_1 + 1) begin : rf_gen
			localparam i = _gv_i_1;
			always @(posedge clk or negedge rst_n) begin : register_write_behavioral
				if (rst_n == 1'b0)
					rf_reg[i * DATA_WIDTH+:DATA_WIDTH] <= 'b0;
				else if (we_dec[i] == 1'b1)
					rf_reg[i * DATA_WIDTH+:DATA_WIDTH] <= WriteData;
				else
					rf_reg[i * DATA_WIDTH+:DATA_WIDTH] <= rf_reg[i * DATA_WIDTH+:DATA_WIDTH];
			end
		end
	endgenerate
	always @(posedge clk or negedge rst_n) begin : register_read_a_behavioral
		if (rst_n == 1'b0)
			ReadData_a <= {DATA_WIDTH {1'b0}};
		else if (ReadEnable_a)
			ReadData_a <= rf_reg[ReadAddr_a * DATA_WIDTH+:DATA_WIDTH];
	end
	always @(posedge clk or negedge rst_n) begin : register_addr_b_behavioral
		if (rst_n == 1'b0)
			ReadAddr_b_reg <= {ASYMM_FACTOR * DATA_WIDTH {1'b0}};
		else if (ReadEnable_b)
			ReadAddr_b_reg <= ReadAddr_b;
	end
	assign ReadData_b = rf_reg_as[ReadAddr_b_reg * (ASYMM_FACTOR * DATA_WIDTH)+:ASYMM_FACTOR * DATA_WIDTH];
	genvar _gv_x_1;
	generate
		for (_gv_x_1 = 0; _gv_x_1 < (2 ** ADDR_WIDTH); _gv_x_1 = _gv_x_1 + 1) begin : asymm_circular_rewiring_gen
			localparam x = _gv_x_1;
			localparam x_low = x % (2 ** ADDR_WIDTH);
			localparam x_high = ((x + ASYMM_FACTOR) - 1) % (2 ** ADDR_WIDTH);
			if (x_high > x_low) begin : genblk1
				assign rf_reg_as[x_low * (ASYMM_FACTOR * DATA_WIDTH)+:ASYMM_FACTOR * DATA_WIDTH] = rf_reg[DATA_WIDTH * ((x_high >= x_low ? x_high : (x_high + (x_high >= x_low ? (x_high - x_low) + 1 : (x_low - x_high) + 1)) - 1) - ((x_high >= x_low ? (x_high - x_low) + 1 : (x_low - x_high) + 1) - 1))+:DATA_WIDTH * (x_high >= x_low ? (x_high - x_low) + 1 : (x_low - x_high) + 1)];
			end
			else begin : genblk1
				assign rf_reg_as[x_low * (ASYMM_FACTOR * DATA_WIDTH)+:ASYMM_FACTOR * DATA_WIDTH] = {rf_reg[DATA_WIDTH * ((x_high >= 0 ? x_high : (x_high + (x_high >= 0 ? x_high + 1 : 1 - x_high)) - 1) - ((x_high >= 0 ? x_high + 1 : 1 - x_high) - 1))+:DATA_WIDTH * (x_high >= 0 ? x_high + 1 : 1 - x_high)], rf_reg[DATA_WIDTH * (({ADDR_WIDTH {1'b1}} >= x_low ? {ADDR_WIDTH {1'b1}} : ({ADDR_WIDTH {1'b1}} + ({ADDR_WIDTH {1'b1}} >= x_low ? ({ADDR_WIDTH {1'b1}} - x_low) + 1 : (x_low - {ADDR_WIDTH {1'b1}}) + 1)) - 1) - (({ADDR_WIDTH {1'b1}} >= x_low ? ({ADDR_WIDTH {1'b1}} - x_low) + 1 : (x_low - {ADDR_WIDTH {1'b1}}) + 1) - 1))+:DATA_WIDTH * ({ADDR_WIDTH {1'b1}} >= x_low ? ({ADDR_WIDTH {1'b1}} - x_low) + 1 : (x_low - {ADDR_WIDTH {1'b1}}) + 1)]};
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
