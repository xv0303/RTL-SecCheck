module model_6144x32_2048x32scm (
	CLK,
	RSTN,
	CEN,
	CEN_scm0,
	CEN_scm1,
	WEN,
	WEN_scm0,
	WEN_scm1,
	BEN,
	BEN_scm0,
	A,
	A_scm0,
	A_scm1,
	D,
	D_scm0,
	Q,
	Q_scm0,
	Q_scm1
);
	input wire CLK;
	input wire RSTN;
	input wire CEN;
	input wire CEN_scm0;
	input wire CEN_scm1;
	input wire WEN;
	input wire WEN_scm0;
	input wire WEN_scm1;
	input wire [3:0] BEN;
	input wire [3:0] BEN_scm0;
	input wire [12:0] A;
	input wire [10:0] A_scm0;
	input wire [10:0] A_scm1;
	input wire [31:0] D;
	input wire [31:0] D_scm0;
	output reg [31:0] Q;
	output wire [31:0] Q_scm0;
	output wire [31:0] Q_scm1;
	localparam CUT0_ADDRW = 12;
	localparam CUT1_ADDRW = 11;
	localparam SCM0_ADDRW = 11;
	wire CEN_int [2:0];
	wire [95:0] Q_int;
	reg [1:0] muxsel;
	wire [31:0] BE_BW;
	wire [3:0] BE;
	wire [3:0] BE_scm0;
	wire read_enA;
	wire read_enB;
	wire read_enC;
	wire write_enA;
	wire write_enB;
	assign BE = ~BEN;
	assign BE_scm0 = ~BEN_scm0;
	assign BE_BW = {{8 {BE[3]}}, {8 {BE[2]}}, {8 {BE[1]}}, {8 {BE[0]}}};
	assign CEN_int[2] = (CEN | ~A[12]) | ~A[11];
	assign CEN_int[1] = (CEN | ~A[12]) | A[11];
	assign CEN_int[0] = CEN | A[12];
	always @(*)
		case (muxsel)
			2'b00: Q = Q_int[0+:32];
			2'b01: Q = Q_int[0+:32];
			2'b10: Q = Q_int[32+:32];
			2'b11: Q = Q_int[64+:32];
		endcase
	always @(posedge CLK or negedge RSTN)
		if (~RSTN)
			muxsel <= 1'sb0;
		else if (CEN == 1'b0)
			muxsel <= A[12:11];
	scm_2048x32 scm_0(
		.CLK(CLK),
		.RSTN(RSTN),
		.CEN(CEN_int[2]),
		.CEN_scm0(CEN_scm0),
		.CEN_scm1(CEN_scm1),
		.WEN(WEN),
		.WEN_scm0(WEN_scm0),
		.WEN_scm1(WEN_scm1),
		.BE(BE),
		.BE_scm0(BE_scm0),
		.A(A[10:0]),
		.A_scm0(A_scm0[10:0]),
		.A_scm1(A_scm1[10:0]),
		.D(D[31:0]),
		.D_scm0(D_scm0[31:0]),
		.Q(Q_int[64+:32]),
		.Q_scm0(Q_scm0),
		.Q_scm1(Q_scm1)
	);
	generic_memory #(
		.ADDR_WIDTH(11),
		.DATA_WIDTH(32)
	) cut_1(
		.CLK(CLK),
		.INITN(1'b1),
		.D(D),
		.A(A[10:0]),
		.CEN(CEN_int[1]),
		.WEN(WEN),
		.BEN(BEN),
		.Q(Q_int[32+:32])
	);
	generic_memory #(
		.ADDR_WIDTH(12),
		.DATA_WIDTH(32)
	) cut_0(
		.CLK(CLK),
		.INITN(1'b1),
		.D(D),
		.A(A[11:0]),
		.CEN(CEN_int[0]),
		.WEN(WEN),
		.BEN(BEN),
		.Q(Q_int[0+:32])
	);
endmodule
module model_sram_28672x32_scm_512x32 (
	CLK,
	RSTN,
	CEN,
	WEN,
	BEN,
	A,
	ID,
	D,
	Q
);
	input wire CLK;
	input wire RSTN;
	input wire CEN;
	input wire WEN;
	input wire [3:0] BEN;
	input wire [14:0] A;
	input wire [31:0] ID;
	input wire [31:0] D;
	output wire [31:0] Q;
	wire [7:0] CEN_int;
	wire CEN_sram;
	wire [255:0] Q_int;
	reg [2:0] muxsel;
	wire [31:0] BE_BW;
	wire [3:0] BE;
	assign BE = ~BEN;
	assign BE_BW = {{8 {BE[3]}}, {8 {BE[2]}}, {8 {BE[1]}}, {8 {BE[0]}}};
	assign CEN_int[0] = ((CEN | A[14]) | A[13]) | A[12];
	assign CEN_int[1] = ((CEN | A[14]) | A[13]) | ~A[12];
	assign CEN_int[2] = ((CEN | A[14]) | ~A[13]) | A[12];
	assign CEN_int[3] = ((CEN | A[14]) | ~A[13]) | ~A[12];
	assign CEN_int[4] = ((CEN | ~A[14]) | A[13]) | A[12];
	assign CEN_int[5] = ((CEN | ~A[14]) | A[13]) | ~A[12];
	assign CEN_int[6] = ((CEN | ~A[14]) | ~A[13]) | A[12];
	assign CEN_int[7] = ((CEN | ~A[14]) | ~A[13]) | ~A[12];
	assign Q = Q_int[muxsel * 32+:32];
	always @(posedge CLK or negedge RSTN)
		if (~RSTN)
			muxsel <= 1'sb0;
		else if (CEN == 1'b0)
			muxsel <= A[14:12];
	generic_memory #(
		.ADDR_WIDTH(12),
		.DATA_WIDTH(32)
	) cut_0(
		.CLK(CLK),
		.INITN(1'b1),
		.D(D),
		.A(A[11:0]),
		.CEN(CEN_int[0]),
		.WEN(WEN),
		.BEN(BEN),
		.Q(Q_int[0+:32])
	);
	generic_memory #(
		.ADDR_WIDTH(12),
		.DATA_WIDTH(32)
	) cut_1(
		.CLK(CLK),
		.INITN(1'b1),
		.D(D),
		.A(A[11:0]),
		.CEN(CEN_int[1]),
		.WEN(WEN),
		.BEN(BEN),
		.Q(Q_int[32+:32])
	);
	generic_memory #(
		.ADDR_WIDTH(12),
		.DATA_WIDTH(32)
	) cut_2(
		.CLK(CLK),
		.INITN(1'b1),
		.D(D),
		.A(A[11:0]),
		.CEN(CEN_int[2]),
		.WEN(WEN),
		.BEN(BEN),
		.Q(Q_int[64+:32])
	);
	generic_memory #(
		.ADDR_WIDTH(12),
		.DATA_WIDTH(32)
	) cut_3(
		.CLK(CLK),
		.INITN(1'b1),
		.D(D),
		.A(A[11:0]),
		.CEN(CEN_int[3]),
		.WEN(WEN),
		.BEN(BEN),
		.Q(Q_int[96+:32])
	);
	generic_memory #(
		.ADDR_WIDTH(12),
		.DATA_WIDTH(32)
	) cut_4(
		.CLK(CLK),
		.INITN(1'b1),
		.D(D),
		.A(A[11:0]),
		.CEN(CEN_int[4]),
		.WEN(WEN),
		.BEN(BEN),
		.Q(Q_int[128+:32])
	);
	generic_memory #(
		.ADDR_WIDTH(12),
		.DATA_WIDTH(32)
	) cut_5(
		.CLK(CLK),
		.INITN(1'b1),
		.D(D),
		.A(A[11:0]),
		.CEN(CEN_int[5]),
		.WEN(WEN),
		.BEN(BEN),
		.Q(Q_int[160+:32])
	);
	generic_memory #(
		.ADDR_WIDTH(12),
		.DATA_WIDTH(32)
	) cut_6(
		.CLK(CLK),
		.INITN(1'b1),
		.D(D),
		.A(A[11:0]),
		.CEN(CEN_int[6]),
		.WEN(WEN),
		.BEN(BEN),
		.Q(Q_int[192+:32])
	);
	scm_512x32 scm_7(
		.CLK(CLK),
		.RSTN(RSTN),
		.CEN(CEN_int[7]),
		.WEN(WEN),
		.BE(BE),
		.A(A[8:0]),
		.D(D[31:0]),
		.Q(Q_int[224+:32])
	);
endmodule
