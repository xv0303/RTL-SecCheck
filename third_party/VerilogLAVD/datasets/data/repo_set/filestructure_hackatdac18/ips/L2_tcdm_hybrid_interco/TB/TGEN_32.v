module TGEN_32 (
	data_req_o,
	data_gnt_i,
	data_add_o,
	data_wen_o,
	data_wdata_o,
	data_be_o,
	data_aux_o,
	data_err_i,
	data_r_valid_i,
	data_r_rdata_i,
	data_r_aux_i,
	clk,
	rst_n,
	fetch_enable_i
);
	parameter ID_WIDTH = 10;
	parameter AUX_WIDTH = 5;
	parameter ADDR_WIDTH = 32;
	parameter DATA_WIDTH = 32;
	parameter BE_WIDTH = DATA_WIDTH / 8;
	output reg data_req_o;
	input wire data_gnt_i;
	output reg [ADDR_WIDTH - 1:0] data_add_o;
	output reg data_wen_o;
	output reg [DATA_WIDTH - 1:0] data_wdata_o;
	output reg [BE_WIDTH - 1:0] data_be_o;
	output reg [AUX_WIDTH - 1:0] data_aux_o;
	input wire data_err_i;
	input wire data_r_valid_i;
	input wire [DATA_WIDTH - 1:0] data_r_rdata_i;
	input wire [AUX_WIDTH - 1:0] data_r_aux_i;
	input wire clk;
	input wire rst_n;
	input wire fetch_enable_i;
	event start_inj;
	event trans_granted;
	always @(posedge clk) begin
		if (fetch_enable_i)
			-> start_inj;
		if (data_req_o & data_gnt_i)
			-> trans_granted;
	end
	task NOP;
		begin
			data_req_o <= 1'sb0;
			data_add_o <= 1'sb0;
			data_wen_o <= 1'sb0;
			data_wdata_o <= 1'sb0;
			data_be_o <= 1'sb0;
			data_aux_o <= 1'sb0;
			@(posedge clk)
				;
		end
	endtask
	task Write32;
		input reg [ADDR_WIDTH - 1:0] addr;
		input reg [AUX_WIDTH - 1:0] aux;
		input reg [DATA_WIDTH - 1:0] wdata;
		input reg [(DATA_WIDTH / 8) - 1:0] be;
		begin
			data_req_o <= 1'b1;
			data_add_o <= addr;
			data_wen_o <= 1'b0;
			data_wdata_o <= wdata;
			data_be_o <= be;
			data_aux_o <= aux;
			@(trans_granted)
				;
			data_req_o <= 1'sb0;
			data_add_o <= 1'sb0;
			data_wen_o <= 1'sb0;
			data_wdata_o <= 1'sb0;
			data_be_o <= 1'sb0;
			data_aux_o <= 1'sb0;
		end
	endtask
	initial begin
		NOP;
		@(start_inj)
			;
		begin : sv2v_autoblock_1
			reg [31:0] j;
			for (j = 0; j < 100; j = j + 1)
				Write32(32'h00000000 + (j * 4), $random % (2 ** AUX_WIDTH), $random, 1'sb1);
		end
	end
	task Read32;
		input reg [ADDR_WIDTH - 1:0] addr;
		input reg [AUX_WIDTH - 1:0] aux;
		begin
			data_req_o <= 1'b1;
			data_add_o <= addr;
			data_wen_o <= 1'b1;
			data_wdata_o <= 1'sb0;
			data_be_o <= 1'sb0;
			data_aux_o <= aux;
			@(trans_granted)
				;
			data_req_o <= 1'sb0;
			data_add_o <= 1'sb0;
			data_wen_o <= 1'sb0;
			data_wdata_o <= 1'sb0;
			data_be_o <= 1'sb0;
			data_aux_o <= 1'sb0;
		end
	endtask
endmodule
