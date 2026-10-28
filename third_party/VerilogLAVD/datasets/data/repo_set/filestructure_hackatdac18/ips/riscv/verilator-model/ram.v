module ram (
	clk,
	instr_req_i,
	instr_addr_i,
	instr_rdata_o,
	instr_rvalid_o,
	instr_gnt_o,
	data_req_i,
	data_addr_i,
	data_we_i,
	data_be_i,
	data_wdata_i,
	data_rdata_o,
	data_rvalid_o,
	data_gnt_o
);
	parameter ADDR_WIDTH = 22;
	input wire clk;
	input wire instr_req_i;
	input wire [ADDR_WIDTH - 1:0] instr_addr_i;
	output wire [127:0] instr_rdata_o;
	output reg instr_rvalid_o;
	output wire instr_gnt_o;
	input wire data_req_i;
	input wire [ADDR_WIDTH - 1:0] data_addr_i;
	input wire data_we_i;
	input wire [3:0] data_be_i;
	input wire [31:0] data_wdata_i;
	output wire [31:0] data_rdata_o;
	output reg data_rvalid_o;
	output wire data_gnt_o;
	dp_ram #(.ADDR_WIDTH(ADDR_WIDTH)) dp_ram_i(
		.clk(clk),
		.en_a_i(instr_req_i),
		.addr_a_i(instr_addr_i),
		.wdata_a_i(1'sb0),
		.rdata_a_o(instr_rdata_o),
		.we_a_i(1'sb0),
		.be_a_i(4'b1111),
		.en_b_i(data_req_i),
		.addr_b_i(data_addr_i),
		.wdata_b_i(data_wdata_i),
		.rdata_b_o(data_rdata_o),
		.we_b_i(data_we_i),
		.be_b_i(data_be_i)
	);
	assign data_gnt_o = data_req_i;
	assign instr_gnt_o = instr_req_i;
	always @(posedge clk) begin
		data_rvalid_o <= data_req_i;
		instr_rvalid_o <= instr_req_i;
	end
endmodule
