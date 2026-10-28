module svci_to_axi4 (
	clk,
	rst_l,
	scan_mode,
	bus_clk_en,
	clk_override,
	axi_awvalid,
	axi_awready,
	axi_awposted,
	axi_awid,
	axi_awaddr,
	axi_awsize,
	axi_awprot,
	axi_awlen,
	axi_awburst,
	axi_awmid,
	axi_awprty,
	axi_wvalid,
	axi_wready,
	axi_wdata,
	axi_wstrb,
	axi_wlast,
	axi_bvalid,
	axi_bready,
	axi_bposted,
	axi_bresp,
	axi_bid,
	axi_bmid,
	axi_bprty,
	axi_arvalid,
	axi_arready,
	axi_arid,
	axi_araddr,
	axi_arsize,
	axi_arprot,
	axi_arlen,
	axi_arburst,
	axi_armid,
	axi_arprty,
	axi_rvalid,
	axi_rready,
	axi_rid,
	axi_rdata,
	axi_rresp,
	axi_rmid,
	axi_rprty,
	svci_cmd_valid,
	svci_cmd_ready,
	svci_cmd_tag,
	svci_cmd_mid,
	svci_cmd_addr,
	svci_cmd_wdata,
	svci_cmd_wbe,
	svci_cmd_length,
	svci_cmd_opc,
	svci_cmd_prty,
	dma_slv_algn_err,
	svci_rsp_valid,
	svci_rsp_ready,
	svci_rsp_tag,
	svci_rsp_mid,
	svci_rsp_rdata,
	svci_rsp_opc,
	svci_rsp_prty
);
	parameter TAG = 1;
	parameter ID = 1;
	parameter PRTY = 1;
	input wire clk;
	input wire rst_l;
	input wire scan_mode;
	input wire bus_clk_en;
	input wire clk_override;
	output wire axi_awvalid;
	input wire axi_awready;
	output wire axi_awposted;
	output wire [TAG - 1:0] axi_awid;
	output wire [31:0] axi_awaddr;
	output wire [2:0] axi_awsize;
	output wire [2:0] axi_awprot;
	output wire [7:0] axi_awlen;
	output wire [1:0] axi_awburst;
	output wire [ID - 1:0] axi_awmid;
	output wire [PRTY - 1:0] axi_awprty;
	output wire axi_wvalid;
	input wire axi_wready;
	output wire [63:0] axi_wdata;
	output wire [7:0] axi_wstrb;
	output wire axi_wlast;
	input wire axi_bvalid;
	output wire axi_bready;
	input wire axi_bposted;
	input wire [1:0] axi_bresp;
	input wire [TAG - 1:0] axi_bid;
	input wire [ID - 1:0] axi_bmid;
	input wire [PRTY - 1:0] axi_bprty;
	output wire axi_arvalid;
	input wire axi_arready;
	output wire [TAG - 1:0] axi_arid;
	output wire [31:0] axi_araddr;
	output wire [2:0] axi_arsize;
	output wire [2:0] axi_arprot;
	output wire [7:0] axi_arlen;
	output wire [1:0] axi_arburst;
	output wire [ID - 1:0] axi_armid;
	output wire [PRTY - 1:0] axi_arprty;
	input wire axi_rvalid;
	output wire axi_rready;
	input wire [TAG - 1:0] axi_rid;
	input wire [63:0] axi_rdata;
	input wire [1:0] axi_rresp;
	input wire [ID - 1:0] axi_rmid;
	input wire [PRTY - 1:0] axi_rprty;
	input wire svci_cmd_valid;
	output wire svci_cmd_ready;
	input wire [TAG - 1:0] svci_cmd_tag;
	input wire [ID - 1:0] svci_cmd_mid;
	input wire [31:0] svci_cmd_addr;
	input wire [63:0] svci_cmd_wdata;
	input wire [7:0] svci_cmd_wbe;
	input wire [2:0] svci_cmd_length;
	input wire [2:0] svci_cmd_opc;
	input wire [PRTY - 1:0] svci_cmd_prty;
	input wire dma_slv_algn_err;
	output wire svci_rsp_valid;
	input wire svci_rsp_ready;
	output wire [TAG - 1:0] svci_rsp_tag;
	output wire [ID - 1:0] svci_rsp_mid;
	output wire [63:0] svci_rsp_rdata;
	output wire [3:0] svci_rsp_opc;
	output wire [PRTY - 1:0] svci_rsp_prty;
	wire cmdbuf_wr_en;
	wire cmdbuf_data_en;
	wire cmdbuf_rst;
	wire cmdbuf_data_rst;
	wire cmdbuf_full;
	wire cmdbuf_vld;
	wire cmdbuf_data_vld;
	wire [2:0] cmdbuf_opc;
	wire [2:0] cmdbuf_size;
	wire [7:0] cmdbuf_wstrb;
	wire [31:0] cmdbuf_addr;
	wire [63:0] cmdbuf_wdata;
	wire [TAG - 1:0] cmdbuf_tag;
	wire [ID - 1:0] cmdbuf_mid;
	wire [PRTY - 1:0] cmdbuf_prty;
	wire wrbuf_en;
	wire wrbuf_rst;
	wire wrbuf_vld;
	wire wrbuf_posted;
	wire [TAG - 1:0] wrbuf_tag;
	wire [ID - 1:0] wrbuf_mid;
	wire [1:0] wrbuf_resp;
	wire [63:0] error_address;
	wire [PRTY - 1:0] wrbuf_prty;
	wire [1:0] axi_bresp_in;
	wire bus_clk;
	assign cmdbuf_wr_en = svci_cmd_valid & svci_cmd_ready;
	assign cmdbuf_data_en = cmdbuf_wr_en & (svci_cmd_opc[2:1] == 2'b01);
	assign cmdbuf_rst = ((axi_awvalid & axi_awready) | (axi_arvalid & axi_arready)) & ~cmdbuf_wr_en;
	assign cmdbuf_data_rst = ((axi_wvalid & axi_wready) & (cmdbuf_opc[2:1] == 2'b01)) & ~cmdbuf_data_en;
	assign cmdbuf_full = (cmdbuf_vld & ~((axi_awvalid & axi_awready) | (axi_arvalid & axi_arready))) | (cmdbuf_data_vld & ~((axi_wvalid & axi_wready) & (cmdbuf_opc[2:1] == 2'b01)));
	rvdffsc #(.WIDTH(1)) cmdbuf_vldff(
		.din(1'b1),
		.dout(cmdbuf_vld),
		.en(cmdbuf_wr_en),
		.clear(cmdbuf_rst),
		.clk(bus_clk),
		.*
	);
	rvdffsc #(.WIDTH(1)) cmdbuf_data_vldff(
		.din(1'b1),
		.dout(cmdbuf_data_vld),
		.en(cmdbuf_data_en),
		.clear(cmdbuf_data_rst),
		.clk(bus_clk),
		.*
	);
	rvdffs #(.WIDTH(3)) cmdbuf_opcff(
		.din(svci_cmd_opc[2:0]),
		.dout(cmdbuf_opc[2:0]),
		.en(cmdbuf_wr_en),
		.clk(bus_clk),
		.*
	);
	rvdffs #(.WIDTH(3)) cmdbuf_sizeff(
		.din(svci_cmd_length[2:0]),
		.dout(cmdbuf_size[2:0]),
		.en(cmdbuf_wr_en),
		.clk(bus_clk),
		.*
	);
	rvdffe #(.WIDTH(8)) cmdbuf_wstrbff(
		.din(svci_cmd_wbe[7:0]),
		.dout(cmdbuf_wstrb[7:0]),
		.en(cmdbuf_wr_en & bus_clk_en),
		.*
	);
	rvdffe #(.WIDTH(32)) cmdbuf_addrff(
		.din(svci_cmd_addr[31:0]),
		.dout(cmdbuf_addr[31:0]),
		.en(cmdbuf_wr_en & bus_clk_en),
		.*
	);
	rvdffe #(.WIDTH(64)) cmdbuf_wdataff(
		.din(svci_cmd_wdata[63:0]),
		.dout(cmdbuf_wdata[63:0]),
		.en(cmdbuf_data_en & bus_clk_en),
		.*
	);
	rvdffs #(.WIDTH(TAG)) cmdbuf_tagff(
		.din(svci_cmd_tag[TAG - 1:0]),
		.dout(cmdbuf_tag[TAG - 1:0]),
		.en(cmdbuf_wr_en),
		.clk(bus_clk),
		.*
	);
	rvdffs #(.WIDTH(ID)) cmdbuf_midff(
		.din(svci_cmd_mid[ID - 1:0]),
		.dout(cmdbuf_mid[ID - 1:0]),
		.en(cmdbuf_wr_en),
		.clk(bus_clk),
		.*
	);
	rvdffs #(.WIDTH(PRTY)) cmdbuf_prtyff(
		.din(svci_cmd_prty[PRTY - 1:0]),
		.dout(cmdbuf_prty[PRTY - 1:0]),
		.en(cmdbuf_wr_en),
		.clk(bus_clk),
		.*
	);
	assign axi_awvalid = cmdbuf_vld & (cmdbuf_opc[2:1] == 2'b01);
	assign axi_awposted = axi_awvalid & ~cmdbuf_opc[0];
	assign axi_awid[TAG - 1:0] = cmdbuf_tag[TAG - 1:0];
	assign axi_awaddr[31:0] = cmdbuf_addr[31:0];
	assign axi_awsize[2:0] = cmdbuf_size[2:0];
	assign axi_awprot[2:0] = 3'b000;
	assign axi_awlen[7:0] = 1'sb0;
	assign axi_awburst[1:0] = 2'b01;
	assign axi_awmid = cmdbuf_mid[ID - 1:0];
	assign axi_awprty = cmdbuf_prty[PRTY - 1:0];
	assign axi_wvalid = cmdbuf_data_vld;
	assign axi_wdata[63:0] = cmdbuf_wdata[63:0];
	assign axi_wstrb[7:0] = cmdbuf_wstrb[7:0];
	assign axi_wlast = 1'b1;
	assign axi_bready = ~wrbuf_vld | svci_rsp_ready;
	assign axi_arvalid = cmdbuf_vld & (cmdbuf_opc[2:0] == 3'b000);
	assign axi_arid[TAG - 1:0] = cmdbuf_tag[TAG - 1:0];
	assign axi_araddr[31:0] = cmdbuf_addr[31:0];
	assign axi_arsize[2:0] = cmdbuf_size[2:0];
	assign axi_arprot = 3'b000;
	assign axi_arlen[7:0] = 1'sb0;
	assign axi_arburst[1:0] = 2'b01;
	assign axi_armid = cmdbuf_mid[ID - 1:0];
	assign axi_rready = ~wrbuf_vld & svci_rsp_ready;
	assign axi_arprty = cmdbuf_prty[PRTY - 1:0];
	assign svci_rsp_valid = wrbuf_vld | axi_rvalid;
	assign svci_rsp_tag[TAG - 1:0] = (wrbuf_vld ? wrbuf_tag[TAG - 1:0] : axi_rid[TAG - 1:0]);
	assign svci_rsp_mid[ID - 1:0] = (wrbuf_vld ? wrbuf_mid[ID - 1:0] : axi_rmid[ID - 1:0]);
	assign svci_rsp_rdata[63:0] = (wrbuf_vld ? {32'b00000000000000000000000000000000, error_address[31:0]} : axi_rdata[63:0]);
	assign svci_rsp_opc[3:2] = (wrbuf_vld ? {1'b1, ~wrbuf_posted} : 2'b00);
	assign svci_rsp_opc[1:0] = (wrbuf_vld ? wrbuf_resp[1:0] : {(axi_rresp[1] ? (axi_rresp[0] ? 2'b10 : {dma_slv_algn_err, 1'b1}) : 2'b00)});
	assign svci_rsp_prty[PRTY - 1:0] = (wrbuf_vld ? wrbuf_prty[PRTY - 1:0] : axi_rprty[PRTY - 1:0]);
	assign svci_cmd_ready = ~cmdbuf_full;
	assign wrbuf_en = (axi_bvalid & axi_bready) & (~axi_bposted | axi_bresp[1]);
	assign wrbuf_rst = ((svci_rsp_valid & svci_rsp_ready) & svci_rsp_opc[3]) & ~wrbuf_en;
	assign axi_bresp_in[1:0] = {(axi_bresp[1] ? (axi_bresp[0] ? 2'b10 : {dma_slv_algn_err, 1'b1}) : 2'b00)};
	rvdffsc #(.WIDTH(1)) wrbuf_vldff(
		.din(1'b1),
		.dout(wrbuf_vld),
		.en(wrbuf_en),
		.clear(wrbuf_rst),
		.clk(bus_clk),
		.*
	);
	rvdffs #(.WIDTH(32)) wrbuf_erroff(
		.din(axi_rdata[31:0]),
		.dout(error_address[31:0]),
		.en(wrbuf_en),
		.clk(bus_clk),
		.*
	);
	rvdffs #(.WIDTH(1)) wrbuf_postedff(
		.din(axi_bposted),
		.dout(wrbuf_posted),
		.en(wrbuf_en),
		.clk(bus_clk),
		.*
	);
	rvdffs #(.WIDTH(TAG)) wrbuf_tagff(
		.din(axi_bid[TAG - 1:0]),
		.dout(wrbuf_tag[TAG - 1:0]),
		.en(wrbuf_en),
		.clk(bus_clk),
		.*
	);
	rvdffs #(.WIDTH(ID)) wrbuf_midff(
		.din(axi_bmid[ID - 1:0]),
		.dout(wrbuf_mid[ID - 1:0]),
		.en(wrbuf_en),
		.clk(bus_clk),
		.*
	);
	rvdffs #(.WIDTH(PRTY)) wrbuf_prtyff(
		.din(axi_bprty[PRTY - 1:0]),
		.dout(wrbuf_prty[PRTY - 1:0]),
		.en(wrbuf_en),
		.clk(bus_clk),
		.*
	);
	rvdffs #(.WIDTH(2)) wrbuf_respff(
		.din(axi_bresp_in[1:0]),
		.dout(wrbuf_resp[1:0]),
		.en(wrbuf_en),
		.clk(bus_clk),
		.*
	);
	rvclkhdr bus_cgc(
		.en(bus_clk_en),
		.l1clk(bus_clk),
		.*
	);
endmodule
