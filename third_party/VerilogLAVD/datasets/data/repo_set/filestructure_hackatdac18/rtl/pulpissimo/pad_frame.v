module pad_frame (
	pad_cfg_i,
	ref_clk_o,
	rstn_o,
	jtag_tck_o,
	jtag_tdi_o,
	jtag_tdo_i,
	jtag_tms_o,
	jtag_trst_o,
	oe_sdio_clk_i,
	oe_sdio_cmd_i,
	oe_sdio_data0_i,
	oe_sdio_data1_i,
	oe_sdio_data2_i,
	oe_sdio_data3_i,
	oe_spim_sdio0_i,
	oe_spim_sdio1_i,
	oe_spim_sdio2_i,
	oe_spim_sdio3_i,
	oe_spim_csn0_i,
	oe_spim_csn1_i,
	oe_spim_sck_i,
	oe_i2s0_sck_i,
	oe_i2s0_ws_i,
	oe_i2s0_sdi_i,
	oe_i2s1_sdi_i,
	oe_cam_pclk_i,
	oe_cam_hsync_i,
	oe_cam_data0_i,
	oe_cam_data1_i,
	oe_cam_data2_i,
	oe_cam_data3_i,
	oe_cam_data4_i,
	oe_cam_data5_i,
	oe_cam_data6_i,
	oe_cam_data7_i,
	oe_cam_vsync_i,
	oe_i2c0_sda_i,
	oe_i2c0_scl_i,
	oe_uart_rx_i,
	oe_uart_tx_i,
	out_sdio_clk_i,
	out_sdio_cmd_i,
	out_sdio_data0_i,
	out_sdio_data1_i,
	out_sdio_data2_i,
	out_sdio_data3_i,
	out_spim_sdio0_i,
	out_spim_sdio1_i,
	out_spim_sdio2_i,
	out_spim_sdio3_i,
	out_spim_csn0_i,
	out_spim_csn1_i,
	out_spim_sck_i,
	out_i2s0_sck_i,
	out_i2s0_ws_i,
	out_i2s0_sdi_i,
	out_i2s1_sdi_i,
	out_cam_pclk_i,
	out_cam_hsync_i,
	out_cam_data0_i,
	out_cam_data1_i,
	out_cam_data2_i,
	out_cam_data3_i,
	out_cam_data4_i,
	out_cam_data5_i,
	out_cam_data6_i,
	out_cam_data7_i,
	out_cam_vsync_i,
	out_i2c0_sda_i,
	out_i2c0_scl_i,
	out_uart_rx_i,
	out_uart_tx_i,
	in_sdio_clk_o,
	in_sdio_cmd_o,
	in_sdio_data0_o,
	in_sdio_data1_o,
	in_sdio_data2_o,
	in_sdio_data3_o,
	in_spim_sdio0_o,
	in_spim_sdio1_o,
	in_spim_sdio2_o,
	in_spim_sdio3_o,
	in_spim_csn0_o,
	in_spim_csn1_o,
	in_spim_sck_o,
	in_i2s0_sck_o,
	in_i2s0_ws_o,
	in_i2s0_sdi_o,
	in_i2s1_sdi_o,
	in_cam_pclk_o,
	in_cam_hsync_o,
	in_cam_data0_o,
	in_cam_data1_o,
	in_cam_data2_o,
	in_cam_data3_o,
	in_cam_data4_o,
	in_cam_data5_o,
	in_cam_data6_o,
	in_cam_data7_o,
	in_cam_vsync_o,
	in_i2c0_sda_o,
	in_i2c0_scl_o,
	in_uart_rx_o,
	in_uart_tx_o,
	pad_sdio_clk,
	pad_sdio_cmd,
	pad_sdio_data0,
	pad_sdio_data1,
	pad_sdio_data2,
	pad_sdio_data3,
	pad_spim_sdio0,
	pad_spim_sdio1,
	pad_spim_sdio2,
	pad_spim_sdio3,
	pad_spim_csn0,
	pad_spim_csn1,
	pad_spim_sck,
	pad_i2s0_sck,
	pad_i2s0_ws,
	pad_i2s0_sdi,
	pad_i2s1_sdi,
	pad_cam_pclk,
	pad_cam_hsync,
	pad_cam_data0,
	pad_cam_data1,
	pad_cam_data2,
	pad_cam_data3,
	pad_cam_data4,
	pad_cam_data5,
	pad_cam_data6,
	pad_cam_data7,
	pad_cam_vsync,
	pad_i2c0_sda,
	pad_i2c0_scl,
	pad_uart_rx,
	pad_uart_tx,
	pad_reset_n,
	pad_bootsel,
	pad_jtag_tck,
	pad_jtag_tdi,
	pad_jtag_tdo,
	pad_jtag_tms,
	pad_jtag_trst,
	pad_xtal_in
);
	input wire [287:0] pad_cfg_i;
	output wire ref_clk_o;
	output wire rstn_o;
	output wire jtag_tck_o;
	output wire jtag_tdi_o;
	input wire jtag_tdo_i;
	output wire jtag_tms_o;
	output wire jtag_trst_o;
	input wire oe_sdio_clk_i;
	input wire oe_sdio_cmd_i;
	input wire oe_sdio_data0_i;
	input wire oe_sdio_data1_i;
	input wire oe_sdio_data2_i;
	input wire oe_sdio_data3_i;
	input wire oe_spim_sdio0_i;
	input wire oe_spim_sdio1_i;
	input wire oe_spim_sdio2_i;
	input wire oe_spim_sdio3_i;
	input wire oe_spim_csn0_i;
	input wire oe_spim_csn1_i;
	input wire oe_spim_sck_i;
	input wire oe_i2s0_sck_i;
	input wire oe_i2s0_ws_i;
	input wire oe_i2s0_sdi_i;
	input wire oe_i2s1_sdi_i;
	input wire oe_cam_pclk_i;
	input wire oe_cam_hsync_i;
	input wire oe_cam_data0_i;
	input wire oe_cam_data1_i;
	input wire oe_cam_data2_i;
	input wire oe_cam_data3_i;
	input wire oe_cam_data4_i;
	input wire oe_cam_data5_i;
	input wire oe_cam_data6_i;
	input wire oe_cam_data7_i;
	input wire oe_cam_vsync_i;
	input wire oe_i2c0_sda_i;
	input wire oe_i2c0_scl_i;
	input wire oe_uart_rx_i;
	input wire oe_uart_tx_i;
	input wire out_sdio_clk_i;
	input wire out_sdio_cmd_i;
	input wire out_sdio_data0_i;
	input wire out_sdio_data1_i;
	input wire out_sdio_data2_i;
	input wire out_sdio_data3_i;
	input wire out_spim_sdio0_i;
	input wire out_spim_sdio1_i;
	input wire out_spim_sdio2_i;
	input wire out_spim_sdio3_i;
	input wire out_spim_csn0_i;
	input wire out_spim_csn1_i;
	input wire out_spim_sck_i;
	input wire out_i2s0_sck_i;
	input wire out_i2s0_ws_i;
	input wire out_i2s0_sdi_i;
	input wire out_i2s1_sdi_i;
	input wire out_cam_pclk_i;
	input wire out_cam_hsync_i;
	input wire out_cam_data0_i;
	input wire out_cam_data1_i;
	input wire out_cam_data2_i;
	input wire out_cam_data3_i;
	input wire out_cam_data4_i;
	input wire out_cam_data5_i;
	input wire out_cam_data6_i;
	input wire out_cam_data7_i;
	input wire out_cam_vsync_i;
	input wire out_i2c0_sda_i;
	input wire out_i2c0_scl_i;
	input wire out_uart_rx_i;
	input wire out_uart_tx_i;
	output wire in_sdio_clk_o;
	output wire in_sdio_cmd_o;
	output wire in_sdio_data0_o;
	output wire in_sdio_data1_o;
	output wire in_sdio_data2_o;
	output wire in_sdio_data3_o;
	output wire in_spim_sdio0_o;
	output wire in_spim_sdio1_o;
	output wire in_spim_sdio2_o;
	output wire in_spim_sdio3_o;
	output wire in_spim_csn0_o;
	output wire in_spim_csn1_o;
	output wire in_spim_sck_o;
	output wire in_i2s0_sck_o;
	output wire in_i2s0_ws_o;
	output wire in_i2s0_sdi_o;
	output wire in_i2s1_sdi_o;
	output wire in_cam_pclk_o;
	output wire in_cam_hsync_o;
	output wire in_cam_data0_o;
	output wire in_cam_data1_o;
	output wire in_cam_data2_o;
	output wire in_cam_data3_o;
	output wire in_cam_data4_o;
	output wire in_cam_data5_o;
	output wire in_cam_data6_o;
	output wire in_cam_data7_o;
	output wire in_cam_vsync_o;
	output wire in_i2c0_sda_o;
	output wire in_i2c0_scl_o;
	output wire in_uart_rx_o;
	output wire in_uart_tx_o;
	inout wire pad_sdio_clk;
	inout wire pad_sdio_cmd;
	inout wire pad_sdio_data0;
	inout wire pad_sdio_data1;
	inout wire pad_sdio_data2;
	inout wire pad_sdio_data3;
	inout wire pad_spim_sdio0;
	inout wire pad_spim_sdio1;
	inout wire pad_spim_sdio2;
	inout wire pad_spim_sdio3;
	inout wire pad_spim_csn0;
	inout wire pad_spim_csn1;
	inout wire pad_spim_sck;
	inout wire pad_i2s0_sck;
	inout wire pad_i2s0_ws;
	inout wire pad_i2s0_sdi;
	inout wire pad_i2s1_sdi;
	inout wire pad_cam_pclk;
	inout wire pad_cam_hsync;
	inout wire pad_cam_data0;
	inout wire pad_cam_data1;
	inout wire pad_cam_data2;
	inout wire pad_cam_data3;
	inout wire pad_cam_data4;
	inout wire pad_cam_data5;
	inout wire pad_cam_data6;
	inout wire pad_cam_data7;
	inout wire pad_cam_vsync;
	inout wire pad_i2c0_sda;
	inout wire pad_i2c0_scl;
	inout wire pad_uart_rx;
	inout wire pad_uart_tx;
	inout wire pad_reset_n;
	inout wire pad_bootsel;
	inout wire pad_jtag_tck;
	inout wire pad_jtag_tdi;
	inout wire pad_jtag_tdo;
	inout wire pad_jtag_tms;
	inout wire pad_jtag_trst;
	inout wire pad_xtal_in;
	pad_functional_pd padinst_sdio_data0(
		.OEN(~oe_sdio_data0_i),
		.I(out_sdio_data0_i),
		.O(in_sdio_data0_o),
		.PAD(pad_sdio_data0),
		.PEN(~pad_cfg_i[132])
	);
	pad_functional_pd padinst_sdio_data1(
		.OEN(~oe_sdio_data1_i),
		.I(out_sdio_data1_i),
		.O(in_sdio_data1_o),
		.PAD(pad_sdio_data1),
		.PEN(~pad_cfg_i[138])
	);
	pad_functional_pd padinst_sdio_data2(
		.OEN(~oe_sdio_data2_i),
		.I(out_sdio_data2_i),
		.O(in_sdio_data2_o),
		.PAD(pad_sdio_data2),
		.PEN(~pad_cfg_i[144])
	);
	pad_functional_pd padinst_sdio_data3(
		.OEN(~oe_sdio_data3_i),
		.I(out_sdio_data3_i),
		.O(in_sdio_data3_o),
		.PAD(pad_sdio_data3),
		.PEN(~pad_cfg_i[150])
	);
	pad_functional_pd padinst_sdio_clk(
		.OEN(~oe_sdio_clk_i),
		.I(out_sdio_clk_i),
		.O(in_sdio_clk_o),
		.PAD(pad_sdio_clk),
		.PEN(~pad_cfg_i[120])
	);
	pad_functional_pd padinst_sdio_cmd(
		.OEN(~oe_sdio_cmd_i),
		.I(out_sdio_cmd_i),
		.O(in_sdio_cmd_o),
		.PAD(pad_sdio_cmd),
		.PEN(~pad_cfg_i[126])
	);
	pad_functional_pd padinst_spim_sck(
		.OEN(~oe_spim_sck_i),
		.I(out_spim_sck_i),
		.O(in_spim_sck_o),
		.PAD(pad_spim_sck),
		.PEN(~pad_cfg_i[36])
	);
	pad_functional_pd padinst_spim_sdio0(
		.OEN(~oe_spim_sdio0_i),
		.I(out_spim_sdio0_i),
		.O(in_spim_sdio0_o),
		.PAD(pad_spim_sdio0),
		.PEN(~pad_cfg_i[0])
	);
	pad_functional_pd padinst_spim_sdio1(
		.OEN(~oe_spim_sdio1_i),
		.I(out_spim_sdio1_i),
		.O(in_spim_sdio1_o),
		.PAD(pad_spim_sdio1),
		.PEN(~pad_cfg_i[6])
	);
	pad_functional_pd padinst_spim_sdio2(
		.OEN(~oe_spim_sdio2_i),
		.I(out_spim_sdio2_i),
		.O(in_spim_sdio2_o),
		.PAD(pad_spim_sdio2),
		.PEN(~pad_cfg_i[12])
	);
	pad_functional_pd padinst_spim_sdio3(
		.OEN(~oe_spim_sdio3_i),
		.I(out_spim_sdio3_i),
		.O(in_spim_sdio3_o),
		.PAD(pad_spim_sdio3),
		.PEN(~pad_cfg_i[18])
	);
	pad_functional_pd padinst_spim_csn1(
		.OEN(~oe_spim_csn1_i),
		.I(out_spim_csn1_i),
		.O(in_spim_csn1_o),
		.PAD(pad_spim_csn1),
		.PEN(~pad_cfg_i[30])
	);
	pad_functional_pd padinst_spim_csn0(
		.OEN(~oe_spim_csn0_i),
		.I(out_spim_csn0_i),
		.O(in_spim_csn0_o),
		.PAD(pad_spim_csn0),
		.PEN(~pad_cfg_i[24])
	);
	pad_functional_pd padinst_i2s1_sdi(
		.OEN(~oe_i2s1_sdi_i),
		.I(out_i2s1_sdi_i),
		.O(in_i2s1_sdi_o),
		.PAD(pad_i2s1_sdi),
		.PEN(~pad_cfg_i[228])
	);
	pad_functional_pd padinst_i2s0_ws(
		.OEN(~oe_i2s0_ws_i),
		.I(out_i2s0_ws_i),
		.O(in_i2s0_ws_o),
		.PAD(pad_i2s0_ws),
		.PEN(~pad_cfg_i[216])
	);
	pad_functional_pd padinst_i2s0_sdi(
		.OEN(~oe_i2s0_sdi_i),
		.I(out_i2s0_sdi_i),
		.O(in_i2s0_sdi_o),
		.PAD(pad_i2s0_sdi),
		.PEN(~pad_cfg_i[222])
	);
	pad_functional_pd padinst_i2s0_sck(
		.OEN(~oe_i2s0_sck_i),
		.I(out_i2s0_sck_i),
		.O(in_i2s0_sck_o),
		.PAD(pad_i2s0_sck),
		.PEN(~pad_cfg_i[210])
	);
	pad_functional_pu padinst_jtag_tck(
		.OEN(1'b1),
		.I(),
		.O(jtag_tck_o),
		.PAD(pad_jtag_tck),
		.PEN(1'b1)
	);
	pad_functional_pu padinst_jtag_tms(
		.OEN(1'b1),
		.I(),
		.O(jtag_tms_o),
		.PAD(pad_jtag_tms),
		.PEN(1'b1)
	);
	pad_functional_pu padinst_jtag_tdi(
		.OEN(1'b1),
		.I(),
		.O(jtag_tdi_o),
		.PAD(pad_jtag_tdi),
		.PEN(1'b1)
	);
	pad_functional_pu padinst_jtag_trstn(
		.OEN(1'b1),
		.I(),
		.O(jtag_trst_o),
		.PAD(pad_jtag_trst),
		.PEN(1'b1)
	);
	pad_functional_pd padinst_jtag_tdo(
		.OEN(1'b0),
		.I(jtag_tdo_i),
		.O(),
		.PAD(pad_jtag_tdo),
		.PEN(1'b1)
	);
	pad_functional_pd padinst_cam_pclk(
		.OEN(~oe_cam_pclk_i),
		.I(out_cam_pclk_i),
		.O(in_cam_pclk_o),
		.PAD(pad_cam_pclk),
		.PEN(~pad_cfg_i[54])
	);
	pad_functional_pd padinst_cam_hsync(
		.OEN(~oe_cam_hsync_i),
		.I(out_cam_hsync_i),
		.O(in_cam_hsync_o),
		.PAD(pad_cam_hsync),
		.PEN(~pad_cfg_i[60])
	);
	pad_functional_pd padinst_cam_data0(
		.OEN(~oe_cam_data0_i),
		.I(out_cam_data0_i),
		.O(in_cam_data0_o),
		.PAD(pad_cam_data0),
		.PEN(~pad_cfg_i[66])
	);
	pad_functional_pd padinst_cam_data1(
		.OEN(~oe_cam_data1_i),
		.I(out_cam_data1_i),
		.O(in_cam_data1_o),
		.PAD(pad_cam_data1),
		.PEN(~pad_cfg_i[72])
	);
	pad_functional_pd padinst_cam_data2(
		.OEN(~oe_cam_data2_i),
		.I(out_cam_data2_i),
		.O(in_cam_data2_o),
		.PAD(pad_cam_data2),
		.PEN(~pad_cfg_i[78])
	);
	pad_functional_pd padinst_cam_data3(
		.OEN(~oe_cam_data3_i),
		.I(out_cam_data3_i),
		.O(in_cam_data3_o),
		.PAD(pad_cam_data3),
		.PEN(~pad_cfg_i[84])
	);
	pad_functional_pd padinst_cam_data4(
		.OEN(~oe_cam_data4_i),
		.I(out_cam_data4_i),
		.O(in_cam_data4_o),
		.PAD(pad_cam_data4),
		.PEN(~pad_cfg_i[90])
	);
	pad_functional_pd padinst_cam_data5(
		.OEN(~oe_cam_data5_i),
		.I(out_cam_data5_i),
		.O(in_cam_data5_o),
		.PAD(pad_cam_data5),
		.PEN(~pad_cfg_i[96])
	);
	pad_functional_pd padinst_cam_data6(
		.OEN(~oe_cam_data6_i),
		.I(out_cam_data6_i),
		.O(in_cam_data6_o),
		.PAD(pad_cam_data6),
		.PEN(~pad_cfg_i[102])
	);
	pad_functional_pd padinst_cam_data7(
		.OEN(~oe_cam_data7_i),
		.I(out_cam_data7_i),
		.O(in_cam_data7_o),
		.PAD(pad_cam_data7),
		.PEN(~pad_cfg_i[108])
	);
	pad_functional_pd padinst_cam_vsync(
		.OEN(~oe_cam_vsync_i),
		.I(out_cam_vsync_i),
		.O(in_cam_vsync_o),
		.PAD(pad_cam_vsync),
		.PEN(~pad_cfg_i[114])
	);
	pad_functional_pu padinst_uart_rx(
		.OEN(~oe_uart_rx_i),
		.I(out_uart_rx_i),
		.O(in_uart_rx_o),
		.PAD(pad_uart_rx),
		.PEN(~pad_cfg_i[198])
	);
	pad_functional_pu padinst_uart_tx(
		.OEN(~oe_uart_tx_i),
		.I(out_uart_tx_i),
		.O(in_uart_tx_o),
		.PAD(pad_uart_tx),
		.PEN(~pad_cfg_i[204])
	);
	pad_functional_pd padinst_i2c0_sda(
		.OEN(~oe_i2c0_sda_i),
		.I(out_i2c0_sda_i),
		.O(in_i2c0_sda_o),
		.PAD(pad_i2c0_sda),
		.PEN(~pad_cfg_i[42])
	);
	pad_functional_pd padinst_i2c0_scl(
		.OEN(~oe_i2c0_scl_i),
		.I(out_i2c0_scl_i),
		.O(in_i2c0_scl_o),
		.PAD(pad_i2c0_scl),
		.PEN(~pad_cfg_i[48])
	);
	pad_functional_pu padinst_reset_n(
		.OEN(1'b1),
		.I(),
		.O(rstn_o),
		.PAD(pad_reset_n),
		.PEN(1'b1)
	);
	pad_functional_pu padinst_ref_clk(
		.OEN(1'b1),
		.I(),
		.O(ref_clk_o),
		.PAD(pad_xtal_in),
		.PEN(1'b1)
	);
endmodule
