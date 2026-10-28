module ram_32768x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [14:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [32767:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_16384x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [13:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [16383:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_8192x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [12:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [8191:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_4096x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [11:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [4095:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_3072x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [11:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [3071:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_2048x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [10:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [2047:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_1536x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [10:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [1535:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_1024x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [9:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [1023:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_768x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [9:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [767:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_512x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [8:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [511:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_256x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [7:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [255:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_128x39 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [6:0] ADR;
	input wire [38:0] D;
	output reg [38:0] Q;
	input wire WE;
	reg [38:0] ram_core [127:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_1024x20 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [9:0] ADR;
	input wire [19:0] D;
	output reg [19:0] Q;
	input wire WE;
	reg [19:0] ram_core [1023:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_512x20 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [8:0] ADR;
	input wire [19:0] D;
	output reg [19:0] Q;
	input wire WE;
	reg [19:0] ram_core [511:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_256x20 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [7:0] ADR;
	input wire [19:0] D;
	output reg [19:0] Q;
	input wire WE;
	reg [19:0] ram_core [255:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_128x20 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [6:0] ADR;
	input wire [19:0] D;
	output reg [19:0] Q;
	input wire WE;
	reg [19:0] ram_core [127:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_64x20 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [5:0] ADR;
	input wire [19:0] D;
	output reg [19:0] Q;
	input wire WE;
	reg [19:0] ram_core [63:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_4096x34 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [11:0] ADR;
	input wire [33:0] D;
	output reg [33:0] Q;
	input wire WE;
	reg [33:0] ram_core [4095:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_2048x34 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [10:0] ADR;
	input wire [33:0] D;
	output reg [33:0] Q;
	input wire WE;
	reg [33:0] ram_core [2047:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_1024x34 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [9:0] ADR;
	input wire [33:0] D;
	output reg [33:0] Q;
	input wire WE;
	reg [33:0] ram_core [1023:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_512x34 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [8:0] ADR;
	input wire [33:0] D;
	output reg [33:0] Q;
	input wire WE;
	reg [33:0] ram_core [511:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_256x34 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [7:0] ADR;
	input wire [33:0] D;
	output reg [33:0] Q;
	input wire WE;
	reg [33:0] ram_core [255:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_128x34 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [6:0] ADR;
	input wire [33:0] D;
	output reg [33:0] Q;
	input wire WE;
	reg [33:0] ram_core [127:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_64x34 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [5:0] ADR;
	input wire [33:0] D;
	output reg [33:0] Q;
	input wire WE;
	reg [33:0] ram_core [63:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_4096x42 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [11:0] ADR;
	input wire [41:0] D;
	output reg [41:0] Q;
	input wire WE;
	reg [41:0] ram_core [4095:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_2048x42 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [10:0] ADR;
	input wire [41:0] D;
	output reg [41:0] Q;
	input wire WE;
	reg [41:0] ram_core [2047:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_1024x42 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [9:0] ADR;
	input wire [41:0] D;
	output reg [41:0] Q;
	input wire WE;
	reg [41:0] ram_core [1023:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_512x42 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [8:0] ADR;
	input wire [41:0] D;
	output reg [41:0] Q;
	input wire WE;
	reg [41:0] ram_core [511:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_256x42 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [7:0] ADR;
	input wire [41:0] D;
	output reg [41:0] Q;
	input wire WE;
	reg [41:0] ram_core [255:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_128x42 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [6:0] ADR;
	input wire [41:0] D;
	output reg [41:0] Q;
	input wire WE;
	reg [41:0] ram_core [127:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_64x42 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [5:0] ADR;
	input wire [41:0] D;
	output reg [41:0] Q;
	input wire WE;
	reg [41:0] ram_core [63:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_1024x21 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [9:0] ADR;
	input wire [20:0] D;
	output reg [20:0] Q;
	input wire WE;
	reg [20:0] ram_core [1023:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_512x21 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [8:0] ADR;
	input wire [20:0] D;
	output reg [20:0] Q;
	input wire WE;
	reg [20:0] ram_core [511:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_256x21 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [7:0] ADR;
	input wire [20:0] D;
	output reg [20:0] Q;
	input wire WE;
	reg [20:0] ram_core [255:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_128x21 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [6:0] ADR;
	input wire [20:0] D;
	output reg [20:0] Q;
	input wire WE;
	reg [20:0] ram_core [127:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_64x21 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [5:0] ADR;
	input wire [20:0] D;
	output reg [20:0] Q;
	input wire WE;
	reg [20:0] ram_core [63:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_1024x25 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [9:0] ADR;
	input wire [24:0] D;
	output reg [24:0] Q;
	input wire WE;
	reg [24:0] ram_core [1023:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_512x25 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [8:0] ADR;
	input wire [24:0] D;
	output reg [24:0] Q;
	input wire WE;
	reg [24:0] ram_core [511:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_256x25 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [7:0] ADR;
	input wire [24:0] D;
	output reg [24:0] Q;
	input wire WE;
	reg [24:0] ram_core [255:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_128x25 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [6:0] ADR;
	input wire [24:0] D;
	output reg [24:0] Q;
	input wire WE;
	reg [24:0] ram_core [127:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
module ram_64x25 (
	CLK,
	ADR,
	D,
	Q,
	WE
);
	input wire CLK;
	input wire [5:0] ADR;
	input wire [24:0] D;
	output reg [24:0] Q;
	input wire WE;
	reg [24:0] ram_core [63:0];
	always @(posedge CLK)
		if (WE) begin
			ram_core[ADR] <= D;
			Q <= 1'sbx;
		end
		else
			Q <= ram_core[ADR];
endmodule
