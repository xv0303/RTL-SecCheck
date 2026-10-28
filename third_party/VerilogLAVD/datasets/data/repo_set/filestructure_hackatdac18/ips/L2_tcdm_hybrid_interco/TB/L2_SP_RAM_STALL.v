module L2_SP_RAM_STALL (
	CLK,
	RSTN,
	CEN,
	WEN,
	A,
	D,
	BE,
	Q,
	gnt_o,
	r_gnt_i,
	id_i,
	r_id_o,
	aux_i,
	r_aux_o,
	r_valid_o
);
	parameter DATA_WIDTH = 32;
	parameter ADDR_WIDTH = 20;
	parameter BE_WIDTH = DATA_WIDTH / 8;
	parameter AUX_WIDTH = 4;
	parameter ID_WIDTH = 3;
	parameter LOG_NUM_ROWS = 20;
	input wire CLK;
	input wire RSTN;
	input wire CEN;
	input wire WEN;
	input wire [ADDR_WIDTH - 1:0] A;
	input wire [(BE_WIDTH * 8) - 1:0] D;
	input wire [BE_WIDTH - 1:0] BE;
	output wire [DATA_WIDTH - 1:0] Q;
	output reg gnt_o;
	input wire r_gnt_i;
	input wire [ID_WIDTH - 1:0] id_i;
	output wire [ID_WIDTH - 1:0] r_id_o;
	input wire [AUX_WIDTH - 1:0] aux_i;
	output wire [AUX_WIDTH - 1:0] r_aux_o;
	output wire r_valid_o;
	localparam numwords = (2 ** LOG_NUM_ROWS) - 1;
	reg [(BE_WIDTH * 8) - 1:0] ram [0:numwords - 1];
	reg [31:0] i;
	reg r_valid_int;
	wire r_gnt_int;
	reg [AUX_WIDTH - 1:0] r_aux_int;
	reg [ID_WIDTH - 1:0] r_id_int;
	reg [DATA_WIDTH - 1:0] Q_int;
	always @(posedge CLK or negedge RSTN)
		if (~RSTN)
			gnt_o <= 0;
		else
			gnt_o <= $random() % 2;
	always @(posedge CLK or negedge RSTN)
		if (RSTN == 1'b0) begin
			r_valid_int <= 1'sb0;
			r_aux_int <= 1'sb0;
			r_id_int <= 1'sb0;
			for (i = 0; i < numwords; i = i + 1)
				ram[i] <= 1'sb0;
		end
		else if ((~CEN & gnt_o) & r_gnt_int) begin
			r_valid_int <= 1'b1;
			r_aux_int <= aux_i;
			r_id_int <= id_i;
			if (~WEN) begin
				for (i = 0; i < BE_WIDTH; i = i + 1)
					if (BE[i])
						ram[A[LOG_NUM_ROWS - 1:0]][i * 8+:8] <= D[i * 8+:8];
				Q_int <= {DATA_WIDTH {1'bx}};
			end
			else
				Q_int <= ram[A[LOG_NUM_ROWS - 1:0]];
		end
		else begin
			r_valid_int <= 1'b0;
			r_aux_int <= aux_i;
			r_id_int <= id_i;
			Q_int <= {DATA_WIDTH {1'bx}};
		end
	wire clk;
	wire rst_n;
	generic_fifo #(
		.DATA_WIDTH((ID_WIDTH + AUX_WIDTH) + DATA_WIDTH),
		.DATA_DEPTH(8)
	) FIFO_OUT(
		.clk(clk),
		.rst_n(rst_n),
		.data_i({Q_int, r_aux_int, r_id_int}),
		.valid_i(r_valid_int),
		.grant_o(r_gnt_int),
		.data_o({Q, r_aux_o, r_id_o}),
		.valid_o(r_valid_o),
		.grant_i(r_gnt_i),
		.test_mode_i(1'b0)
	);
endmodule
