module udma_subsystem (
	L2_ro_wen_o,
	L2_ro_req_o,
	L2_ro_gnt_i,
	L2_ro_addr_o,
	L2_ro_be_o,
	L2_ro_wdata_o,
	L2_ro_rvalid_i,
	L2_ro_rdata_i,
	L2_wo_wen_o,
	L2_wo_req_o,
	L2_wo_gnt_i,
	L2_wo_addr_o,
	L2_wo_wdata_o,
	L2_wo_be_o,
	L2_wo_rvalid_i,
	L2_wo_rdata_i,
	dft_test_mode_i,
	dft_cg_enable_i,
	sys_clk_i,
	periph_clk_i,
	HRESETn,
	PADDR,
	PWDATA,
	PWRITE,
	PSEL,
	PENABLE,
	PRDATA,
	PREADY,
	PSLVERR,
	events_o,
	event_valid_i,
	event_data_i,
	event_ready_o,
	spi0_clk,
	spi0_csn0,
	spi0_csn1,
	spi0_csn2,
	spi0_csn3,
	spi0_mode,
	spi0_sdo0,
	spi0_sdo1,
	spi0_sdo2,
	spi0_sdo3,
	spi0_sdi0,
	spi0_sdi1,
	spi0_sdi2,
	spi0_sdi3,
	cam_clk_i,
	cam_data_i,
	cam_hsync_i,
	cam_vsync_i,
	uart_rx,
	uart_tx,
	i2s_sd0_i,
	i2s_sd1_i,
	i2s_ws_i,
	i2s_sck_i,
	i2s_ws0_o,
	i2s_sck0_o,
	i2s_mode0_o,
	i2s_ws1_o,
	i2s_sck1_o,
	i2s_mode1_o,
	i2c0_scl_i,
	i2c0_scl_o,
	i2c0_scl_oe,
	i2c0_sda_i,
	i2c0_sda_o,
	i2c0_sda_oe,
	i2c1_scl_i,
	i2c1_scl_o,
	i2c1_scl_oe,
	i2c1_sda_i,
	i2c1_sda_o,
	i2c1_sda_oe,
	sdclk_o,
	sdcmd_o,
	sdcmd_i,
	sdcmd_oen_o,
	sddata_o,
	sddata_i,
	sddata_oen_o
);
	parameter UDMA_EVENTS = 28;
	parameter L2_ADDR_WIDTH = 15;
	parameter L2_DATA_WIDTH = 32;
	parameter CAM_DATA_WIDTH = 8;
	parameter APB_ADDR_WIDTH = 12;
	parameter TRANS_SIZE = 17;
	output wire L2_ro_wen_o;
	output wire L2_ro_req_o;
	input wire L2_ro_gnt_i;
	output wire [31:0] L2_ro_addr_o;
	output wire [(L2_DATA_WIDTH / 8) - 1:0] L2_ro_be_o;
	output wire [L2_DATA_WIDTH - 1:0] L2_ro_wdata_o;
	input wire L2_ro_rvalid_i;
	input wire [L2_DATA_WIDTH - 1:0] L2_ro_rdata_i;
	output wire L2_wo_wen_o;
	output wire L2_wo_req_o;
	input wire L2_wo_gnt_i;
	output wire [31:0] L2_wo_addr_o;
	output wire [L2_DATA_WIDTH - 1:0] L2_wo_wdata_o;
	output wire [(L2_DATA_WIDTH / 8) - 1:0] L2_wo_be_o;
	input wire L2_wo_rvalid_i;
	input wire [L2_DATA_WIDTH - 1:0] L2_wo_rdata_i;
	input wire dft_test_mode_i;
	input wire dft_cg_enable_i;
	input wire sys_clk_i;
	input wire periph_clk_i;
	input wire HRESETn;
	input wire [APB_ADDR_WIDTH - 1:0] PADDR;
	input wire [31:0] PWDATA;
	input wire PWRITE;
	input wire PSEL;
	input wire PENABLE;
	output wire [31:0] PRDATA;
	output wire PREADY;
	output wire PSLVERR;
	output wire [UDMA_EVENTS - 1:0] events_o;
	input wire event_valid_i;
	input wire [7:0] event_data_i;
	output wire event_ready_o;
	output wire spi0_clk;
	output wire spi0_csn0;
	output wire spi0_csn1;
	output wire spi0_csn2;
	output wire spi0_csn3;
	output wire [1:0] spi0_mode;
	output wire spi0_sdo0;
	output wire spi0_sdo1;
	output wire spi0_sdo2;
	output wire spi0_sdo3;
	input wire spi0_sdi0;
	input wire spi0_sdi1;
	input wire spi0_sdi2;
	input wire spi0_sdi3;
	input wire cam_clk_i;
	input wire [CAM_DATA_WIDTH - 1:0] cam_data_i;
	input wire cam_hsync_i;
	input wire cam_vsync_i;
	input wire uart_rx;
	output wire uart_tx;
	input wire i2s_sd0_i;
	input wire i2s_sd1_i;
	input wire i2s_ws_i;
	input wire i2s_sck_i;
	output wire i2s_ws0_o;
	output wire i2s_sck0_o;
	output wire [1:0] i2s_mode0_o;
	output wire i2s_ws1_o;
	output wire i2s_sck1_o;
	output wire [1:0] i2s_mode1_o;
	input wire i2c0_scl_i;
	output wire i2c0_scl_o;
	output wire i2c0_scl_oe;
	input wire i2c0_sda_i;
	output wire i2c0_sda_o;
	output wire i2c0_sda_oe;
	input wire i2c1_scl_i;
	output wire i2c1_scl_o;
	output wire i2c1_scl_oe;
	input wire i2c1_sda_i;
	output wire i2c1_sda_o;
	output wire i2c1_sda_oe;
	output wire sdclk_o;
	output wire sdcmd_o;
	input wire sdcmd_i;
	output wire sdcmd_oen_o;
	output wire [3:0] sddata_o;
	input wire [3:0] sddata_i;
	output wire [3:0] sddata_oen_o;
	localparam N_I2S = 1;
	localparam N_UART = 1;
	localparam N_SPI = 1;
	localparam N_I2C = 2;
	localparam N_CAM = 1;
	localparam N_RF = 0;
	localparam N_SDIO = 1;
	localparam N_HYPER = 0;
	localparam N_RX_CHANNELS = 8;
	localparam N_TX_CHANNELS = 5;
	localparam L2_AWIDTH_NOAL = L2_ADDR_WIDTH + 2;
	localparam N_PERIPHS = 7;
	localparam CH_ID_UART = 0;
	localparam CH_ID_SPIM0 = 1;
	localparam CH_ID_SDIO = 2;
	localparam CH_ID_I2C0 = 3;
	localparam CH_ID_I2C1 = 4;
	localparam CH_ID_I2S = 5;
	localparam CH_ID_CAM = 7;
	localparam PER_ID_UART = 0;
	localparam PER_ID_SPIM0 = 1;
	localparam PER_ID_SDIO = 2;
	localparam PER_ID_I2C0 = 3;
	localparam PER_ID_I2C1 = 4;
	localparam PER_ID_I2S = 5;
	localparam PER_ID_CAM = 6;
	wire [(5 * L2_AWIDTH_NOAL) - 1:0] tx_cfg_startaddr;
	wire [(5 * TRANS_SIZE) - 1:0] tx_cfg_size;
	wire [4:0] tx_cfg_continuous;
	wire [4:0] tx_cfg_en;
	wire [4:0] tx_cfg_clr;
	wire [4:0] tx_ch_req;
	wire [4:0] tx_ch_gnt;
	wire [159:0] tx_ch_data;
	wire [4:0] tx_ch_valid;
	wire [4:0] tx_ch_ready;
	wire [9:0] tx_ch_datasize;
	wire [4:0] tx_ch_events;
	wire [4:0] tx_ch_en;
	wire [4:0] tx_ch_pending;
	wire [(5 * L2_AWIDTH_NOAL) - 1:0] tx_ch_curr_addr;
	wire [(5 * TRANS_SIZE) - 1:0] tx_ch_bytes_left;
	wire [(8 * L2_AWIDTH_NOAL) - 1:0] rx_cfg_startaddr;
	wire [(8 * TRANS_SIZE) - 1:0] rx_cfg_size;
	wire [7:0] rx_cfg_continuous;
	wire [7:0] rx_cfg_filter;
	wire [7:0] rx_cfg_en;
	wire [7:0] rx_cfg_clr;
	wire [255:0] rx_ch_data;
	wire [7:0] rx_ch_valid;
	wire [7:0] rx_ch_ready;
	wire [15:0] rx_ch_datasize;
	wire [7:0] rx_ch_events;
	wire [7:0] rx_ch_en;
	wire [7:0] rx_ch_pending;
	wire [(8 * L2_AWIDTH_NOAL) - 1:0] rx_ch_curr_addr;
	wire [(8 * TRANS_SIZE) - 1:0] rx_ch_bytes_left;
	wire [L2_ADDR_WIDTH - 1:0] s_L2_ro_addr;
	wire [L2_ADDR_WIDTH - 1:0] s_L2_wo_addr;
	wire [UDMA_EVENTS - 1:0] s_events;
	wire [1:0] s_rf_event;
	wire s_spi0_eot;
	wire s_spi1_eot;
	wire s_spi2_eot;
	wire [6:0] s_clk_periphs_core;
	wire [6:0] s_clk_periphs_per;
	wire [31:0] s_periph_data_to;
	wire [4:0] s_periph_addr;
	wire s_periph_rwn;
	wire [223:0] s_periph_data_from;
	wire [6:0] s_periph_valid;
	wire [6:0] s_periph_ready;
	wire [31:0] s_periph_data_from_spim0;
	wire s_periph_valid_spim0;
	wire s_periph_ready_from_spim0;
	wire [31:0] s_periph_data_from_sdio;
	wire s_periph_valid_sdio;
	wire s_periph_ready_from_sdio;
	wire [31:0] s_periph_data_from_i2c0;
	wire s_periph_valid_i2c0;
	wire s_periph_ready_from_i2c0;
	wire [31:0] s_periph_data_from_i2c1;
	wire s_periph_valid_i2c1;
	wire s_periph_ready_from_i2c1;
	wire [31:0] s_periph_data_from_uart;
	wire s_periph_valid_uart;
	wire s_periph_ready_from_uart;
	wire [31:0] s_periph_data_from_i2s;
	wire s_periph_valid_i2s;
	wire s_periph_ready_from_i2s;
	wire [31:0] s_periph_data_from_cam;
	wire s_periph_valid_cam;
	wire s_periph_ready_from_cam;
	wire [3:0] s_trigger_events;
	wire s_cam_evt;
	wire s_i2s_evt;
	wire s_i2c1_evt;
	wire s_i2c0_evt;
	wire s_uart_evt;
	wire [2:0] s_tgen_en;
	assign L2_ro_addr_o = {8'h1c, {(32 - L2_ADDR_WIDTH) - 10 {1'b0}}, s_L2_ro_addr, 2'b00};
	assign L2_wo_addr_o = {8'h1c, {(32 - L2_ADDR_WIDTH) - 10 {1'b0}}, s_L2_wo_addr, 2'b00};
	assign s_cam_evt = 1'b0;
	assign s_i2s_evt = 1'b0;
	assign s_uart_evt = 1'b0;
	assign rx_cfg_filter[CH_ID_UART] = 1'b0;
	assign rx_cfg_filter[CH_ID_SDIO] = 1'b0;
	assign rx_cfg_filter[CH_ID_SPIM0] = 1'b0;
	assign rx_cfg_filter[CH_ID_I2C0] = 1'b0;
	assign rx_cfg_filter[CH_ID_I2C1] = 1'b0;
	assign rx_cfg_filter[CH_ID_I2S] = 1'b0;
	assign rx_cfg_filter[6] = 1'b0;
	assign s_events = {6'h00, s_cam_evt, rx_ch_events[CH_ID_CAM], s_i2s_evt, rx_ch_events[6], rx_ch_events[CH_ID_I2S], 2'h0, s_i2c1_evt, rx_ch_events[CH_ID_I2C1], tx_ch_events[CH_ID_I2C1], s_i2c0_evt, rx_ch_events[CH_ID_I2C0], tx_ch_events[CH_ID_I2C0], 1'b0, rx_ch_events[CH_ID_SDIO], tx_ch_events[CH_ID_SDIO], s_spi0_eot, rx_ch_events[CH_ID_SPIM0], tx_ch_events[CH_ID_SPIM0], s_uart_evt, rx_ch_events[CH_ID_UART], tx_ch_events[CH_ID_UART], 4'h0};
	integer i;
	assign s_periph_data_from = {s_periph_data_from_cam, s_periph_data_from_i2s, s_periph_data_from_i2c1, s_periph_data_from_i2c0, s_periph_data_from_sdio, s_periph_data_from_spim0, s_periph_data_from_uart};
	assign s_periph_ready = {s_periph_ready_from_cam, s_periph_ready_from_i2s, s_periph_ready_from_i2c1, s_periph_ready_from_i2c0, s_periph_ready_from_sdio, s_periph_ready_from_spim0, s_periph_ready_from_uart};
	assign s_periph_valid_uart = s_periph_valid[PER_ID_UART];
	assign s_periph_valid_spim0 = s_periph_valid[PER_ID_SPIM0];
	assign s_periph_valid_sdio = s_periph_valid[PER_ID_SDIO];
	assign s_periph_valid_i2c0 = s_periph_valid[PER_ID_I2C0];
	assign s_periph_valid_i2c1 = s_periph_valid[PER_ID_I2C1];
	assign s_periph_valid_i2s = s_periph_valid[PER_ID_I2S];
	assign s_periph_valid_cam = s_periph_valid[PER_ID_CAM];
	assign events_o = s_events;
	assign L2_ro_wen_o = 1'b1;
	assign L2_wo_wen_o = 1'b0;
	assign L2_ro_be_o = 'h0;
	assign L2_ro_wdata_o = 'h0;
	wire s_filter_eot_evt;
	wire s_filter_act_evt;
	udma_core #(
		.L2_ADDR_WIDTH(L2_ADDR_WIDTH),
		.L2_DATA_WIDTH(L2_DATA_WIDTH),
		.DATA_WIDTH(32),
		.N_RX_CHANNELS(N_RX_CHANNELS),
		.N_TX_CHANNELS(N_TX_CHANNELS),
		.TRANS_SIZE(TRANS_SIZE),
		.N_PERIPHS(N_PERIPHS),
		.APB_ADDR_WIDTH(APB_ADDR_WIDTH)
	) u_udmacore(
		.sys_clk_i(sys_clk_i),
		.per_clk_i(periph_clk_i),
		.dft_cg_enable_i(dft_cg_enable_i),
		.HRESETn(HRESETn),
		.PADDR(PADDR),
		.PWDATA(PWDATA),
		.PWRITE(PWRITE),
		.PSEL(PSEL),
		.PENABLE(PENABLE),
		.PRDATA(PRDATA),
		.PREADY(PREADY),
		.PSLVERR(PSLVERR),
		.periph_per_clk_o(s_clk_periphs_per),
		.periph_sys_clk_o(s_clk_periphs_core),
		.event_valid_i(event_valid_i),
		.event_data_i(event_data_i),
		.event_ready_o(event_ready_o),
		.event_o(s_trigger_events),
		.filter_eot_o(s_filter_eot_evt),
		.filter_act_o(s_filter_act_evt),
		.periph_data_to_o(s_periph_data_to),
		.periph_addr_o(s_periph_addr),
		.periph_data_from_i(s_periph_data_from),
		.periph_ready_i(s_periph_ready),
		.periph_valid_o(s_periph_valid),
		.periph_rwn_o(s_periph_rwn),
		.tx_l2_req_o(L2_ro_req_o),
		.tx_l2_gnt_i(L2_ro_gnt_i),
		.tx_l2_addr_o(s_L2_ro_addr),
		.tx_l2_rdata_i(L2_ro_rdata_i),
		.tx_l2_rvalid_i(L2_ro_rvalid_i),
		.rx_l2_req_o(L2_wo_req_o),
		.rx_l2_gnt_i(L2_wo_gnt_i),
		.rx_l2_addr_o(s_L2_wo_addr),
		.rx_l2_be_o(L2_wo_be_o),
		.rx_l2_wdata_o(L2_wo_wdata_o),
		.tx_ch_req_i(tx_ch_req),
		.tx_ch_gnt_o(tx_ch_gnt),
		.tx_ch_valid_o(tx_ch_valid),
		.tx_ch_data_o(tx_ch_data),
		.tx_ch_ready_i(tx_ch_ready),
		.tx_ch_datasize_i(tx_ch_datasize),
		.tx_ch_events_o(tx_ch_events),
		.tx_ch_en_o(tx_ch_en),
		.tx_ch_pending_o(tx_ch_pending),
		.tx_ch_curr_addr_o(tx_ch_curr_addr),
		.tx_ch_bytes_left_o(tx_ch_bytes_left),
		.tx_cfg_startaddr_i(tx_cfg_startaddr),
		.tx_cfg_size_i(tx_cfg_size),
		.tx_cfg_continuous_i(tx_cfg_continuous),
		.tx_cfg_en_i(tx_cfg_en),
		.tx_cfg_clr_i(tx_cfg_clr),
		.rx_ch_valid_i(rx_ch_valid),
		.rx_ch_data_i(rx_ch_data),
		.rx_ch_ready_o(rx_ch_ready),
		.rx_ch_datasize_i(rx_ch_datasize),
		.rx_ch_events_o(rx_ch_events),
		.rx_ch_en_o(rx_ch_en),
		.rx_ch_pending_o(rx_ch_pending),
		.rx_ch_curr_addr_o(rx_ch_curr_addr),
		.rx_ch_bytes_left_o(rx_ch_bytes_left),
		.rx_cfg_startaddr_i(rx_cfg_startaddr),
		.rx_cfg_size_i(rx_cfg_size),
		.rx_cfg_continuous_i(rx_cfg_continuous),
		.rx_cfg_filter_i(rx_cfg_filter),
		.rx_cfg_en_i(rx_cfg_en),
		.rx_cfg_clr_i(rx_cfg_clr)
	);
	udma_uart_top #(
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.TRANS_SIZE(TRANS_SIZE)
	) u_uart(
		.sys_clk_i(s_clk_periphs_core[PER_ID_UART]),
		.periph_clk_i(s_clk_periphs_per[PER_ID_UART]),
		.rstn_i(HRESETn),
		.uart_tx_o(uart_tx),
		.uart_rx_i(uart_rx),
		.cfg_data_i(s_periph_data_to),
		.cfg_addr_i(s_periph_addr),
		.cfg_valid_i(s_periph_valid_uart),
		.cfg_rwn_i(s_periph_rwn),
		.cfg_data_o(s_periph_data_from_uart),
		.cfg_ready_o(s_periph_ready_from_uart),
		.cfg_rx_startaddr_o(rx_cfg_startaddr[0+:L2_AWIDTH_NOAL]),
		.cfg_rx_size_o(rx_cfg_size[0+:TRANS_SIZE]),
		.cfg_rx_continuous_o(rx_cfg_continuous[CH_ID_UART]),
		.cfg_rx_en_o(rx_cfg_en[CH_ID_UART]),
		.cfg_rx_clr_o(rx_cfg_clr[CH_ID_UART]),
		.cfg_rx_en_i(rx_ch_en[CH_ID_UART]),
		.cfg_rx_pending_i(rx_ch_pending[CH_ID_UART]),
		.cfg_rx_curr_addr_i(rx_ch_curr_addr[0+:L2_AWIDTH_NOAL]),
		.cfg_rx_bytes_left_i(rx_ch_bytes_left[0+:TRANS_SIZE]),
		.cfg_rx_datasize_o(),
		.cfg_tx_startaddr_o(tx_cfg_startaddr[0+:L2_AWIDTH_NOAL]),
		.cfg_tx_size_o(tx_cfg_size[0+:TRANS_SIZE]),
		.cfg_tx_continuous_o(tx_cfg_continuous[CH_ID_UART]),
		.cfg_tx_en_o(tx_cfg_en[CH_ID_UART]),
		.cfg_tx_clr_o(tx_cfg_clr[CH_ID_UART]),
		.cfg_tx_en_i(tx_ch_en[CH_ID_UART]),
		.cfg_tx_pending_i(tx_ch_pending[CH_ID_UART]),
		.cfg_tx_curr_addr_i(tx_ch_curr_addr[0+:L2_AWIDTH_NOAL]),
		.cfg_tx_bytes_left_i(tx_ch_bytes_left[0+:TRANS_SIZE]),
		.cfg_tx_datasize_o(),
		.data_tx_req_o(tx_ch_req[CH_ID_UART]),
		.data_tx_gnt_i(tx_ch_gnt[CH_ID_UART]),
		.data_tx_datasize_o(tx_ch_datasize[0+:2]),
		.data_tx_i(tx_ch_data[0+:32]),
		.data_tx_valid_i(tx_ch_valid[CH_ID_UART]),
		.data_tx_ready_o(tx_ch_ready[CH_ID_UART]),
		.data_rx_datasize_o(rx_ch_datasize[0+:2]),
		.data_rx_o(rx_ch_data[0+:32]),
		.data_rx_valid_o(rx_ch_valid[CH_ID_UART]),
		.data_rx_ready_i(rx_ch_ready[CH_ID_UART])
	);
	udma_spim_top #(
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.TRANS_SIZE(TRANS_SIZE)
	) u_spim0(
		.sys_clk_i(s_clk_periphs_core[PER_ID_SPIM0]),
		.periph_clk_i(s_clk_periphs_per[PER_ID_SPIM0]),
		.rstn_i(HRESETn),
		.dft_test_mode_i(dft_test_mode_i),
		.dft_cg_enable_i(dft_cg_enable_i),
		.spi_eot_o(s_spi0_eot),
		.spi_event_i(s_trigger_events),
		.spi_clk_o(spi0_clk),
		.spi_csn0_o(spi0_csn0),
		.spi_csn1_o(spi0_csn1),
		.spi_csn2_o(spi0_csn2),
		.spi_csn3_o(spi0_csn3),
		.spi_mode_o(spi0_mode),
		.spi_sdo0_o(spi0_sdo0),
		.spi_sdo1_o(spi0_sdo1),
		.spi_sdo2_o(spi0_sdo2),
		.spi_sdo3_o(spi0_sdo3),
		.spi_sdi0_i(spi0_sdi0),
		.spi_sdi1_i(spi0_sdi1),
		.spi_sdi2_i(spi0_sdi2),
		.spi_sdi3_i(spi0_sdi3),
		.cfg_data_i(s_periph_data_to),
		.cfg_addr_i(s_periph_addr),
		.cfg_valid_i(s_periph_valid_spim0),
		.cfg_rwn_i(s_periph_rwn),
		.cfg_data_o(s_periph_data_from_spim0),
		.cfg_ready_o(s_periph_ready_from_spim0),
		.data_tx_req_o(tx_ch_req[CH_ID_SPIM0]),
		.data_tx_gnt_i(tx_ch_gnt[CH_ID_SPIM0]),
		.data_tx_datasize_o(tx_ch_datasize[2+:2]),
		.data_tx_i(tx_ch_data[32+:32]),
		.data_tx_valid_i(tx_ch_valid[CH_ID_SPIM0]),
		.data_tx_ready_o(tx_ch_ready[CH_ID_SPIM0]),
		.data_rx_datasize_o(rx_ch_datasize[2+:2]),
		.data_rx_o(rx_ch_data[32+:32]),
		.data_rx_valid_o(rx_ch_valid[CH_ID_SPIM0]),
		.data_rx_ready_i(rx_ch_ready[CH_ID_SPIM0]),
		.cfg_tx_startaddr_o(tx_cfg_startaddr[CH_ID_SPIM0 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_tx_size_o(tx_cfg_size[CH_ID_SPIM0 * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_tx_continuous_o(tx_cfg_continuous[CH_ID_SPIM0]),
		.cfg_tx_en_o(tx_cfg_en[CH_ID_SPIM0]),
		.cfg_tx_clr_o(tx_cfg_clr[CH_ID_SPIM0]),
		.cfg_tx_en_i(tx_ch_en[CH_ID_SPIM0]),
		.cfg_tx_pending_i(tx_ch_pending[CH_ID_SPIM0]),
		.cfg_tx_curr_addr_i(tx_ch_curr_addr[CH_ID_SPIM0 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_tx_bytes_left_i(tx_ch_bytes_left[CH_ID_SPIM0 * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_startaddr_o(rx_cfg_startaddr[CH_ID_SPIM0 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_size_o(rx_cfg_size[CH_ID_SPIM0 * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_continuous_o(rx_cfg_continuous[CH_ID_SPIM0]),
		.cfg_rx_en_o(rx_cfg_en[CH_ID_SPIM0]),
		.cfg_rx_clr_o(rx_cfg_clr[CH_ID_SPIM0]),
		.cfg_rx_en_i(rx_ch_en[CH_ID_SPIM0]),
		.cfg_rx_pending_i(rx_ch_pending[CH_ID_SPIM0]),
		.cfg_rx_curr_addr_i(rx_ch_curr_addr[CH_ID_SPIM0 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_bytes_left_i(rx_ch_bytes_left[CH_ID_SPIM0 * TRANS_SIZE+:TRANS_SIZE])
	);
	wire ddata_i;
	udma_sdio_top #(
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.TRANS_SIZE(TRANS_SIZE)
	) u_sdio(
		.sys_clk_i(s_clk_periphs_core[PER_ID_UART]),
		.periph_clk_i(s_clk_periphs_per[PER_ID_UART]),
		.rstn_i(HRESETn),
		.err_o(),
		.eot_o(),
		.sdclk_o(sdclk_o),
		.sdcmd_o(sdcmd_o),
		.sdcmd_i(sdcmd_i),
		.sdcmd_oen_o(sdcmd_oen_o),
		.sddata_o(sddata_o),
		.sddata_i(ddata_i),
		.sddata_oen_o(sddata_oen_o),
		.cfg_data_i(s_periph_data_to),
		.cfg_addr_i(s_periph_addr),
		.cfg_valid_i(s_periph_valid_sdio),
		.cfg_rwn_i(s_periph_rwn),
		.cfg_data_o(s_periph_data_from_sdio),
		.cfg_ready_o(s_periph_ready_from_sdio),
		.cfg_rx_startaddr_o(rx_cfg_startaddr[CH_ID_SDIO * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_size_o(rx_cfg_size[CH_ID_SDIO * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_continuous_o(rx_cfg_continuous[CH_ID_SDIO]),
		.cfg_rx_en_o(rx_cfg_en[CH_ID_SDIO]),
		.cfg_rx_clr_o(rx_cfg_clr[CH_ID_SDIO]),
		.cfg_rx_en_i(rx_ch_en[CH_ID_SDIO]),
		.cfg_rx_pending_i(rx_ch_pending[CH_ID_SDIO]),
		.cfg_rx_curr_addr_i(rx_ch_curr_addr[CH_ID_SDIO * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_bytes_left_i(rx_ch_bytes_left[CH_ID_SDIO * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_tx_startaddr_o(tx_cfg_startaddr[CH_ID_SDIO * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_tx_size_o(tx_cfg_size[CH_ID_SDIO * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_tx_continuous_o(tx_cfg_continuous[CH_ID_SDIO]),
		.cfg_tx_en_o(tx_cfg_en[CH_ID_SDIO]),
		.cfg_tx_clr_o(tx_cfg_clr[CH_ID_SDIO]),
		.cfg_tx_en_i(tx_ch_en[CH_ID_SDIO]),
		.cfg_tx_pending_i(tx_ch_pending[CH_ID_SDIO]),
		.cfg_tx_curr_addr_i(tx_ch_curr_addr[CH_ID_SDIO * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_tx_bytes_left_i(tx_ch_bytes_left[CH_ID_SDIO * TRANS_SIZE+:TRANS_SIZE]),
		.data_tx_req_o(tx_ch_req[CH_ID_SDIO]),
		.data_tx_gnt_i(tx_ch_gnt[CH_ID_SDIO]),
		.data_tx_datasize_o(tx_ch_datasize[4+:2]),
		.data_tx_i(tx_ch_data[64+:32]),
		.data_tx_valid_i(tx_ch_valid[CH_ID_SDIO]),
		.data_tx_ready_o(tx_ch_ready[CH_ID_SDIO]),
		.data_rx_datasize_o(rx_ch_datasize[4+:2]),
		.data_rx_o(rx_ch_data[64+:32]),
		.data_rx_valid_o(rx_ch_valid[CH_ID_SDIO]),
		.data_rx_ready_i(rx_ch_ready[CH_ID_SDIO])
	);
	udma_i2c_top #(
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.TRANS_SIZE(TRANS_SIZE)
	) u_i2c0(
		.sys_clk_i(s_clk_periphs_core[PER_ID_I2C0]),
		.periph_clk_i(s_clk_periphs_per[PER_ID_I2C0]),
		.rstn_i(HRESETn),
		.cfg_data_i(s_periph_data_to),
		.cfg_addr_i(s_periph_addr),
		.cfg_valid_i(s_periph_valid_i2c0),
		.cfg_rwn_i(s_periph_rwn),
		.cfg_data_o(s_periph_data_from_i2c0),
		.cfg_ready_o(s_periph_ready_from_i2c0),
		.cfg_tx_startaddr_o(tx_cfg_startaddr[CH_ID_I2C0 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_tx_size_o(tx_cfg_size[CH_ID_I2C0 * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_tx_continuous_o(tx_cfg_continuous[CH_ID_I2C0]),
		.cfg_tx_en_o(tx_cfg_en[CH_ID_I2C0]),
		.cfg_tx_clr_o(tx_cfg_clr[CH_ID_I2C0]),
		.cfg_tx_en_i(tx_ch_en[CH_ID_I2C0]),
		.cfg_tx_pending_i(tx_ch_pending[CH_ID_I2C0]),
		.cfg_tx_curr_addr_i(tx_ch_curr_addr[CH_ID_I2C0 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_tx_bytes_left_i(tx_ch_bytes_left[CH_ID_I2C0 * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_startaddr_o(rx_cfg_startaddr[CH_ID_I2C0 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_size_o(rx_cfg_size[CH_ID_I2C0 * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_continuous_o(rx_cfg_continuous[CH_ID_I2C0]),
		.cfg_rx_en_o(rx_cfg_en[CH_ID_I2C0]),
		.cfg_rx_clr_o(rx_cfg_clr[CH_ID_I2C0]),
		.cfg_rx_en_i(rx_ch_en[CH_ID_I2C0]),
		.cfg_rx_pending_i(rx_ch_pending[CH_ID_I2C0]),
		.cfg_rx_curr_addr_i(rx_ch_curr_addr[CH_ID_I2C0 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_bytes_left_i(rx_ch_bytes_left[CH_ID_I2C0 * TRANS_SIZE+:TRANS_SIZE]),
		.data_tx_req_o(tx_ch_req[CH_ID_I2C0]),
		.data_tx_gnt_i(tx_ch_gnt[CH_ID_I2C0]),
		.data_tx_datasize_o(tx_ch_datasize[6+:2]),
		.data_tx_i(tx_ch_data[103-:8]),
		.data_tx_valid_i(tx_ch_valid[CH_ID_I2C0]),
		.data_tx_ready_o(tx_ch_ready[CH_ID_I2C0]),
		.data_rx_datasize_o(rx_ch_datasize[6+:2]),
		.data_rx_o(rx_ch_data[103-:8]),
		.data_rx_valid_o(rx_ch_valid[CH_ID_I2C0]),
		.data_rx_ready_i(rx_ch_ready[CH_ID_I2C0]),
		.err_o(s_i2c0_evt),
		.scl_i(i2c0_scl_i),
		.scl_o(i2c0_scl_o),
		.scl_oe(i2c0_scl_oe),
		.sda_i(i2c0_sda_i),
		.sda_o(i2c0_sda_o),
		.sda_oe(i2c0_sda_oe),
		.ext_events_i(s_trigger_events)
	);
	assign rx_ch_data[127-:24] = 'h0;
	udma_i2c_top #(
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.TRANS_SIZE(TRANS_SIZE)
	) u_i2c1(
		.sys_clk_i(s_clk_periphs_core[PER_ID_I2C1]),
		.periph_clk_i(s_clk_periphs_per[PER_ID_I2C1]),
		.rstn_i(HRESETn),
		.cfg_data_i(s_periph_data_to),
		.cfg_addr_i(s_periph_addr),
		.cfg_valid_i(s_periph_valid_i2c1),
		.cfg_rwn_i(s_periph_rwn),
		.cfg_data_o(s_periph_data_from_i2c1),
		.cfg_ready_o(s_periph_ready_from_i2c1),
		.cfg_tx_startaddr_o(tx_cfg_startaddr[CH_ID_I2C1 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_tx_size_o(tx_cfg_size[CH_ID_I2C1 * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_tx_continuous_o(tx_cfg_continuous[CH_ID_I2C1]),
		.cfg_tx_en_o(tx_cfg_en[CH_ID_I2C1]),
		.cfg_tx_clr_o(tx_cfg_clr[CH_ID_I2C1]),
		.cfg_tx_en_i(tx_ch_en[CH_ID_I2C1]),
		.cfg_tx_pending_i(tx_ch_pending[CH_ID_I2C1]),
		.cfg_tx_curr_addr_i(tx_ch_curr_addr[CH_ID_I2C1 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_tx_bytes_left_i(tx_ch_bytes_left[CH_ID_I2C1 * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_startaddr_o(rx_cfg_startaddr[CH_ID_I2C1 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_size_o(rx_cfg_size[CH_ID_I2C1 * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_continuous_o(rx_cfg_continuous[CH_ID_I2C1]),
		.cfg_rx_en_o(rx_cfg_en[CH_ID_I2C1]),
		.cfg_rx_clr_o(rx_cfg_clr[CH_ID_I2C1]),
		.cfg_rx_en_i(rx_ch_en[CH_ID_I2C1]),
		.cfg_rx_pending_i(rx_ch_pending[CH_ID_I2C1]),
		.cfg_rx_curr_addr_i(rx_ch_curr_addr[CH_ID_I2C1 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_bytes_left_i(rx_ch_bytes_left[CH_ID_I2C1 * TRANS_SIZE+:TRANS_SIZE]),
		.data_tx_req_o(tx_ch_req[CH_ID_I2C1]),
		.data_tx_gnt_i(tx_ch_gnt[CH_ID_I2C1]),
		.data_tx_datasize_o(tx_ch_datasize[8+:2]),
		.data_tx_i(tx_ch_data[135-:8]),
		.data_tx_valid_i(tx_ch_valid[CH_ID_I2C1]),
		.data_tx_ready_o(tx_ch_ready[CH_ID_I2C1]),
		.data_rx_datasize_o(rx_ch_datasize[8+:2]),
		.data_rx_o(rx_ch_data[135-:8]),
		.data_rx_valid_o(rx_ch_valid[CH_ID_I2C1]),
		.data_rx_ready_i(rx_ch_ready[CH_ID_I2C1]),
		.err_o(s_i2c1_evt),
		.scl_i(i2c1_scl_i),
		.scl_o(i2c1_scl_o),
		.scl_oe(i2c1_scl_oe),
		.sda_i(i2c1_sda_i),
		.sda_o(i2c1_sda_o),
		.sda_oe(i2c1_sda_oe),
		.ext_events_i(s_trigger_events)
	);
	assign rx_ch_data[159-:24] = 'h0;
	udma_i2s_2ch #(
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.TRANS_SIZE(TRANS_SIZE)
	) u_i2s_udma(
		.sys_clk_i(s_clk_periphs_core[PER_ID_I2S]),
		.periph_clk_i(s_clk_periphs_per[PER_ID_I2S]),
		.rstn_i(HRESETn),
		.dft_test_mode_i(dft_test_mode_i),
		.dft_cg_enable_i(dft_cg_enable_i),
		.ext_sd0_i(i2s_sd0_i),
		.ext_sd1_i(i2s_sd1_i),
		.ext_sck_i(i2s_sck_i),
		.ext_ws_i(i2s_ws_i),
		.ext_ws_o(),
		.ext_sck0_o(i2s_sck0_o),
		.ext_ws0_o(i2s_ws0_o),
		.ext_mode0_o(i2s_mode0_o),
		.ext_sck1_o(i2s_sck1_o),
		.ext_ws1_o(i2s_ws1_o),
		.ext_mode1_o(i2s_mode1_o),
		.cfg_data_i(s_periph_data_to),
		.cfg_addr_i(s_periph_addr),
		.cfg_valid_i(s_periph_valid_i2s),
		.cfg_rwn_i(s_periph_rwn),
		.cfg_data_o(s_periph_data_from_i2s),
		.cfg_ready_o(s_periph_ready_from_i2s),
		.cfg_rx_ch0_startaddr_o(rx_cfg_startaddr[CH_ID_I2S * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_ch0_size_o(rx_cfg_size[CH_ID_I2S * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_ch0_continuous_o(rx_cfg_continuous[CH_ID_I2S]),
		.cfg_rx_ch0_en_o(rx_cfg_en[CH_ID_I2S]),
		.cfg_rx_ch0_clr_o(rx_cfg_clr[CH_ID_I2S]),
		.cfg_rx_ch0_en_i(rx_ch_en[CH_ID_I2S]),
		.cfg_rx_ch0_pending_i(rx_ch_pending[CH_ID_I2S]),
		.cfg_rx_ch0_curr_addr_i(rx_ch_curr_addr[CH_ID_I2S * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_ch0_bytes_left_i(rx_ch_bytes_left[CH_ID_I2S * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_ch0_datasize_o(),
		.cfg_rx_ch1_startaddr_o(rx_cfg_startaddr[6 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_ch1_size_o(rx_cfg_size[6 * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_ch1_continuous_o(rx_cfg_continuous[6]),
		.cfg_rx_ch1_en_o(rx_cfg_en[6]),
		.cfg_rx_ch1_clr_o(rx_cfg_clr[6]),
		.cfg_rx_ch1_en_i(rx_ch_en[6]),
		.cfg_rx_ch1_pending_i(rx_ch_pending[6]),
		.cfg_rx_ch1_curr_addr_i(rx_ch_curr_addr[6 * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_ch1_bytes_left_i(rx_ch_bytes_left[6 * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_ch1_datasize_o(),
		.data_rx_ch0_datasize_o(rx_ch_datasize[10+:2]),
		.data_rx_ch0_o(rx_ch_data[160+:32]),
		.data_rx_ch0_valid_o(rx_ch_valid[CH_ID_I2S]),
		.data_rx_ch0_ready_i(rx_ch_ready[CH_ID_I2S]),
		.data_rx_ch1_datasize_o(rx_ch_datasize[12+:2]),
		.data_rx_ch1_o(rx_ch_data[192+:32]),
		.data_rx_ch1_valid_o(rx_ch_valid[6]),
		.data_rx_ch1_ready_i(rx_ch_ready[6])
	);
	camera_if #(
		.L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
		.TRANS_SIZE(TRANS_SIZE),
		.DATA_WIDTH(8)
	) u_camera_if(
		.clk_i(s_clk_periphs_core[PER_ID_CAM]),
		.rstn_i(HRESETn),
		.dft_test_mode_i(dft_test_mode_i),
		.dft_cg_enable_i(dft_cg_enable_i),
		.cfg_data_i(s_periph_data_to),
		.cfg_addr_i(s_periph_addr),
		.cfg_valid_i(s_periph_valid_cam),
		.cfg_rwn_i(s_periph_rwn),
		.cfg_data_o(s_periph_data_from_cam),
		.cfg_ready_o(s_periph_ready_from_cam),
		.cfg_rx_startaddr_o(rx_cfg_startaddr[CH_ID_CAM * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_size_o(rx_cfg_size[CH_ID_CAM * TRANS_SIZE+:TRANS_SIZE]),
		.cfg_rx_continuous_o(rx_cfg_continuous[CH_ID_CAM]),
		.cfg_rx_en_o(rx_cfg_en[CH_ID_CAM]),
		.cfg_rx_filter_o(rx_cfg_filter[CH_ID_CAM]),
		.cfg_rx_clr_o(rx_cfg_clr[CH_ID_CAM]),
		.cfg_rx_en_i(rx_ch_en[CH_ID_CAM]),
		.cfg_rx_pending_i(rx_ch_pending[CH_ID_CAM]),
		.cfg_rx_curr_addr_i(rx_ch_curr_addr[CH_ID_CAM * L2_AWIDTH_NOAL+:L2_AWIDTH_NOAL]),
		.cfg_rx_bytes_left_i(rx_ch_bytes_left[CH_ID_CAM * TRANS_SIZE+:TRANS_SIZE]),
		.data_rx_datasize_o(rx_ch_datasize[14+:2]),
		.data_rx_data_o(rx_ch_data[239-:16]),
		.data_rx_valid_o(rx_ch_valid[CH_ID_CAM]),
		.data_rx_ready_i(rx_ch_ready[CH_ID_CAM]),
		.cam_clk_i(cam_clk_i),
		.cam_data_i(cam_data_i),
		.cam_hsync_i(cam_hsync_i),
		.cam_vsync_i(cam_vsync_i)
	);
	assign rx_ch_data[255-:16] = 'h0;
endmodule
