module register_file_2r_2w (
	clk,
	rst_n,
	raddr_a_i,
	rdata_a_o,
	raddr_b_i,
	rdata_b_o,
	waddr_a_i,
	wdata_a_i,
	we_a_i,
	waddr_b_i,
	wdata_b_i,
	we_b_i
);
	reg _sv2v_0;
	parameter ADDR_WIDTH = 5;
	parameter DATA_WIDTH = 32;
	input wire clk;
	input wire rst_n;
	input wire [ADDR_WIDTH - 1:0] raddr_a_i;
	output reg [DATA_WIDTH - 1:0] rdata_a_o;
	input wire [ADDR_WIDTH - 1:0] raddr_b_i;
	output reg [DATA_WIDTH - 1:0] rdata_b_o;
	input wire [ADDR_WIDTH - 1:0] waddr_a_i;
	input wire [DATA_WIDTH - 1:0] wdata_a_i;
	input wire we_a_i;
	input wire [ADDR_WIDTH - 1:0] waddr_b_i;
	input wire [DATA_WIDTH - 1:0] wdata_b_i;
	input wire we_b_i;
	localparam NUM_WORDS = 2 ** ADDR_WIDTH;
	(* ram_style = "block" *) reg [(NUM_WORDS * DATA_WIDTH) - 1:0] rf_reg;
	reg [NUM_WORDS - 1:0] we_a_dec;
	reg [NUM_WORDS - 1:0] we_b_dec;
	always @(*) begin : we_a_decoder
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < NUM_WORDS; i = i + 1)
				if (waddr_a_i == i)
					we_a_dec[i] <= we_a_i;
				else
					we_a_dec[i] <= 1'b0;
		end
	end
	always @(*) begin : we_b_decoder
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < NUM_WORDS; i = i + 1)
				if (waddr_b_i == i)
					we_b_dec[i] <= we_b_i;
				else
					we_b_dec[i] <= 1'b0;
		end
	end
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < NUM_WORDS; _gv_i_1 = _gv_i_1 + 1) begin : rf_gen
			localparam i = _gv_i_1;
			always @(posedge clk or negedge rst_n) begin : register_write_behavioral
				if (rst_n == 1'b0)
					rf_reg[i * DATA_WIDTH+:DATA_WIDTH] <= 'b0;
				else if (we_b_dec[i] == 1'b1)
					rf_reg[i * DATA_WIDTH+:DATA_WIDTH] <= wdata_b_i;
				else if (we_a_dec[i] == 1'b1)
					rf_reg[i * DATA_WIDTH+:DATA_WIDTH] <= wdata_a_i;
				else
					rf_reg[i * DATA_WIDTH+:DATA_WIDTH] <= rf_reg[i * DATA_WIDTH+:DATA_WIDTH];
			end
		end
	endgenerate
	always @(*) begin : register_read_a_behavioral
		if (_sv2v_0)
			;
		rdata_a_o <= rf_reg[raddr_a_i * DATA_WIDTH+:DATA_WIDTH];
	end
	always @(*) begin : register_read_b_behavioral
		if (_sv2v_0)
			;
		rdata_b_o <= rf_reg[raddr_b_i * DATA_WIDTH+:DATA_WIDTH];
	end
	initial _sv2v_0 = 0;
endmodule
