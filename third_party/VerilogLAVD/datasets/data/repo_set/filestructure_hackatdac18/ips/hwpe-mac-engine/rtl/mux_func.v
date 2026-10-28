module mux_func (
	a,
	b,
	c,
	d,
	clk,
	rst
);
	input wire [127:0] a;
	input wire [127:0] b;
	output reg [127:0] c;
	input wire [127:0] d;
	input wire clk;
	input wire rst;
	wire rdy_out_sha;
	wire rdy_out_md5;
	wire [127:0] aes_out;
	wire [127:0] sha_out;
	wire [127:0] md5_out;
	wire [127:0] temperature_out;
	aes_1cc aes(
		.clk(0),
		.rst(1),
		.g_input(b),
		.e_input(a),
		.o(aes_out)
	);
	wire rdy_out;
	keccak sha(
		.clk(clk),
		.reset(rst),
		.in(a),
		.in_ready(1),
		.out(sha_out),
		.out_ready(rdy_out)
	);
	md5 md5(
		.clk(clk),
		.reset(rst),
		.data_i(a[31:0]),
		.load_i(1),
		.ready_o(rdy_out_md5),
		.data_o(md5_out[31:0])
	);
	tempsen temperature_sensor(
		.clk(clk),
		.in(a),
		.out(temperature_out)
	);
	always @(posedge clk) begin
		if (d[0] == 1'b1)
			c = aes_out;
		if (d[1] == 1'b1)
			c = sha_out;
		if (d[2] == 1'b1)
			c = md5_out;
		if (d[3] == 1'b1)
			c = temperature_out;
		else
			c = 128'h00000000000000000000000000000000;
	end
endmodule
