module L2_SP_RAM (
	CLK,
	RSTN,
	CEN,
	WEN,
	A,
	D,
	BE,
	Q,
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
	input wire CLK;
	input wire RSTN;
	input wire CEN;
	input wire WEN;
	input wire [ADDR_WIDTH - 1:0] A;
	input wire [(BE_WIDTH * 8) - 1:0] D;
	input wire [BE_WIDTH - 1:0] BE;
	output reg [DATA_WIDTH - 1:0] Q;
	input wire [ID_WIDTH - 1:0] id_i;
	output reg [ID_WIDTH - 1:0] r_id_o;
	input wire [AUX_WIDTH - 1:0] aux_i;
	output reg [AUX_WIDTH - 1:0] r_aux_o;
	output reg r_valid_o;
	localparam numwords = (2 ** ADDR_WIDTH) - 1;
	reg [(BE_WIDTH * 8) - 1:0] ram [0:numwords - 1];
	reg [31:0] i;
	always @(posedge CLK or negedge RSTN)
		if (RSTN == 1'b0) begin
			r_valid_o <= 1'sb0;
			r_aux_o <= 1'sb0;
			r_id_o <= 1'sb0;
			for (i = 0; i < numwords; i = i + 1)
				ram[i] <= 1'sb0;
		end
		else if (~CEN) begin
			r_valid_o <= 1'b1;
			r_aux_o <= aux_i;
			r_id_o <= id_i;
			if (~WEN) begin
				for (i = 0; i < BE_WIDTH; i = i + 1)
					if (BE[i])
						ram[A][i * 8+:8] <= D[i * 8+:8];
				Q <= {DATA_WIDTH {1'bx}};
			end
			else
				Q <= ram[A];
		end
		else begin
			r_valid_o <= 1'b0;
			r_aux_o <= aux_i;
			r_id_o <= id_i;
			Q <= {DATA_WIDTH {1'bx}};
		end
endmodule
