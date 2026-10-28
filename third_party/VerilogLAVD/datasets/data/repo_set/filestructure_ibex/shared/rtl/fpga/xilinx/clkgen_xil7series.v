module clkgen_xil7series (
	IO_CLK,
	IO_RST_N,
	clk_sys,
	rst_sys_n
);
	input IO_CLK;
	input IO_RST_N;
	output wire clk_sys;
	output wire rst_sys_n;
	wire locked_pll;
	wire io_clk_buf;
	wire clk_50_buf;
	wire clk_50_unbuf;
	wire clk_fb_buf;
	wire clk_fb_unbuf;
	IBUF io_clk_ibuf(
		.I(IO_CLK),
		.O(io_clk_buf)
	);
	PLLE2_ADV #(
		.BANDWIDTH("OPTIMIZED"),
		.COMPENSATION("ZHOLD"),
		.STARTUP_WAIT("FALSE"),
		.DIVCLK_DIVIDE(1),
		.CLKFBOUT_MULT(12),
		.CLKFBOUT_PHASE(0.000),
		.CLKOUT0_DIVIDE(24),
		.CLKOUT0_PHASE(0.000),
		.CLKOUT0_DUTY_CYCLE(0.500),
		.CLKIN1_PERIOD(10)
	) pll(
		.CLKFBOUT(clk_fb_unbuf),
		.CLKOUT0(clk_50_unbuf),
		.CLKOUT1(),
		.CLKOUT2(),
		.CLKOUT3(),
		.CLKOUT4(),
		.CLKOUT5(),
		.CLKFBIN(clk_fb_buf),
		.CLKIN1(io_clk_buf),
		.CLKIN2(1'b0),
		.CLKINSEL(1'b1),
		.DADDR(7'h00),
		.DCLK(1'b0),
		.DEN(1'b0),
		.DI(16'h0000),
		.DO(),
		.DRDY(),
		.DWE(1'b0),
		.LOCKED(locked_pll),
		.PWRDWN(1'b0),
		.RST(1'b0)
	);
	BUFG clk_fb_bufg(
		.I(clk_fb_unbuf),
		.O(clk_fb_buf)
	);
	BUFG clk_50_bufg(
		.I(clk_50_unbuf),
		.O(clk_50_buf)
	);
	assign clk_sys = clk_50_buf;
	assign rst_sys_n = locked_pll & IO_RST_N;
endmodule
