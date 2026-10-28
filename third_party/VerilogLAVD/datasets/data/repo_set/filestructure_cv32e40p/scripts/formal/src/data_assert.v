module data_assert (
	clk_i,
	rst_ni,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	data_rdata_i
);
	input wire clk_i;
	input wire rst_ni;
	input wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	input wire data_we_o;
	input wire [3:0] data_be_o;
	input wire [31:0] data_addr_o;
	input wire [31:0] data_wdata_o;
	input wire [31:0] data_rdata_i;
	reg signed [31:0] s_outstanding_cnt;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			s_outstanding_cnt <= 0;
		else if ((data_req_o & data_gnt_i) & data_rvalid_i)
			s_outstanding_cnt <= s_outstanding_cnt;
		else if (data_req_o & data_gnt_i)
			s_outstanding_cnt <= s_outstanding_cnt + 1;
		else if (data_rvalid_i)
			s_outstanding_cnt <= s_outstanding_cnt - 1;
endmodule
