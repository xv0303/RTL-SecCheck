module dp_ram (
	clk,
	en_a_i,
	addr_a_i,
	wdata_a_i,
	rdata_a_o,
	we_a_i,
	be_a_i,
	en_b_i,
	addr_b_i,
	wdata_b_i,
	rdata_b_o,
	we_b_i,
	be_b_i
);
	reg _sv2v_0;
	parameter ADDR_WIDTH = 8;
	input wire clk;
	input wire en_a_i;
	input wire [ADDR_WIDTH - 1:0] addr_a_i;
	input wire [31:0] wdata_a_i;
	output reg [127:0] rdata_a_o;
	input wire we_a_i;
	input wire [3:0] be_a_i;
	input wire en_b_i;
	input wire [ADDR_WIDTH - 1:0] addr_b_i;
	input wire [31:0] wdata_b_i;
	output reg [31:0] rdata_b_o;
	input wire we_b_i;
	input wire [3:0] be_b_i;
	localparam bytes = 2 ** ADDR_WIDTH;
	reg [7:0] mem [0:bytes - 1];
	reg [19:0] addr_b_int;
	always @(*) begin
		if (_sv2v_0)
			;
		addr_b_int = {addr_b_i[19:2], 2'b00};
	end
	always @(posedge clk) begin
		rdata_a_o[0+:8] <= mem[addr_a_i + 0];
		rdata_a_o[8+:8] <= mem[addr_a_i + 1];
		rdata_a_o[16+:8] <= mem[addr_a_i + 2];
		rdata_a_o[24+:8] <= mem[addr_a_i + 3];
		rdata_a_o[32+:8] <= mem[addr_a_i + 4];
		rdata_a_o[40+:8] <= mem[addr_a_i + 5];
		rdata_a_o[48+:8] <= mem[addr_a_i + 6];
		rdata_a_o[56+:8] <= mem[addr_a_i + 7];
		rdata_a_o[64+:8] <= mem[addr_a_i + 8];
		rdata_a_o[72+:8] <= mem[addr_a_i + 9];
		rdata_a_o[80+:8] <= mem[addr_a_i + 10];
		rdata_a_o[88+:8] <= mem[addr_a_i + 11];
		rdata_a_o[96+:8] <= mem[addr_a_i + 12];
		rdata_a_o[104+:8] <= mem[addr_a_i + 13];
		rdata_a_o[112+:8] <= mem[addr_a_i + 14];
		rdata_a_o[120+:8] <= mem[addr_a_i + 15];
		if (en_b_i) begin
			if (we_b_i) begin
				if (be_b_i[0])
					mem[addr_b_int] <= wdata_b_i[0+:8];
				if (be_b_i[1])
					mem[addr_b_int + 1] <= wdata_b_i[8+:8];
				if (be_b_i[2])
					mem[addr_b_int + 2] <= wdata_b_i[16+:8];
				if (be_b_i[3])
					mem[addr_b_int + 3] <= wdata_b_i[24+:8];
			end
			else begin
				rdata_b_o[7:0] <= mem[addr_b_int];
				rdata_b_o[15:8] <= mem[addr_b_int + 1];
				rdata_b_o[23:16] <= mem[addr_b_int + 2];
				rdata_b_o[31:24] <= mem[addr_b_int + 3];
			end
		end
	end
	function [7:0] readByte;
		input integer byte_addr;
		readByte = mem[byte_addr];
	endfunction
	task writeByte;
		input integer byte_addr;
		input [7:0] val;
		mem[byte_addr] = val;
	endtask
	initial _sv2v_0 = 0;
endmodule
