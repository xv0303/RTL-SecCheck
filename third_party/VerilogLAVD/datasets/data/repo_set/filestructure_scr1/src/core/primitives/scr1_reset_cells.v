module scr1_reset_buf_cell (
	rst_n,
	clk,
	test_mode,
	test_rst_n,
	reset_n_in,
	reset_n_out,
	reset_n_status
);
	input wire rst_n;
	input wire clk;
	input wire test_mode;
	input wire test_rst_n;
	input wire reset_n_in;
	output wire reset_n_out;
	output wire reset_n_status;
	reg reset_n_ff;
	reg reset_n_status_ff;
	wire rst_n_mux;
	assign rst_n_mux = (test_mode == 1'b1 ? test_rst_n : rst_n);
	always @(negedge rst_n_mux or posedge clk)
		if (~rst_n_mux)
			reset_n_ff <= 1'b0;
		else
			reset_n_ff <= reset_n_in;
	assign reset_n_out = (test_mode == 1'b1 ? test_rst_n : reset_n_ff);
	always @(negedge rst_n_mux or posedge clk)
		if (~rst_n_mux)
			reset_n_status_ff <= 1'b0;
		else
			reset_n_status_ff <= reset_n_in;
	assign reset_n_status = reset_n_status_ff;
endmodule
module scr1_reset_sync_cell (
	rst_n,
	clk,
	test_rst_n,
	test_mode,
	rst_n_in,
	rst_n_out
);
	parameter [31:0] STAGES_AMOUNT = 2;
	input wire rst_n;
	input wire clk;
	input wire test_rst_n;
	input wire test_mode;
	input wire rst_n_in;
	output wire rst_n_out;
	reg [STAGES_AMOUNT - 1:0] rst_n_dff;
	wire local_rst_n_in;
	assign local_rst_n_in = (test_mode == 1'b1 ? test_rst_n : rst_n);
	generate
		if (STAGES_AMOUNT == 1) begin : gen_reset_sync_cell_single
			always @(negedge local_rst_n_in or posedge clk)
				if (~local_rst_n_in)
					rst_n_dff <= 1'b0;
				else
					rst_n_dff <= rst_n_in;
		end
		else begin : gen_reset_sync_cell_multi
			always @(negedge local_rst_n_in or posedge clk)
				if (~local_rst_n_in)
					rst_n_dff <= 1'sb0;
				else
					rst_n_dff <= {rst_n_dff[STAGES_AMOUNT - 2:0], rst_n_in};
		end
	endgenerate
	assign rst_n_out = (test_mode == 1'b1 ? test_rst_n : rst_n_dff[STAGES_AMOUNT - 1]);
endmodule
module scr1_data_sync_cell (
	rst_n,
	clk,
	data_in,
	data_out
);
	parameter [31:0] STAGES_AMOUNT = 1;
	input wire rst_n;
	input wire clk;
	input wire data_in;
	output wire data_out;
	reg [STAGES_AMOUNT - 1:0] data_dff;
	generate
		if (STAGES_AMOUNT == 1) begin : gen_data_sync_cell_single
			always @(negedge rst_n or posedge clk)
				if (~rst_n)
					data_dff <= 1'b0;
				else
					data_dff <= data_in;
		end
		else begin : gen_data_sync_cell_multi
			always @(negedge rst_n or posedge clk)
				if (~rst_n)
					data_dff <= 1'sb0;
				else
					data_dff <= {data_dff[STAGES_AMOUNT - 2:0], data_in};
		end
	endgenerate
	assign data_out = data_dff[STAGES_AMOUNT - 1];
endmodule
module scr1_reset_qlfy_adapter_cell_sync (
	rst_n,
	clk,
	test_rst_n,
	test_mode,
	reset_n_in_sync,
	reset_n_out_qlfy,
	reset_n_out,
	reset_n_status
);
	input wire rst_n;
	input wire clk;
	input wire test_rst_n;
	input wire test_mode;
	input wire reset_n_in_sync;
	output wire reset_n_out_qlfy;
	output wire reset_n_out;
	output wire reset_n_status;
	wire rst_n_mux;
	reg reset_n_front_ff;
	assign rst_n_mux = (test_mode == 1'b1 ? test_rst_n : rst_n);
	always @(negedge rst_n_mux or posedge clk)
		if (~rst_n_mux)
			reset_n_front_ff <= 1'b0;
		else
			reset_n_front_ff <= reset_n_in_sync;
	assign reset_n_out_qlfy = reset_n_front_ff;
	scr1_reset_buf_cell i_reset_output_buf(
		.rst_n(rst_n),
		.clk(clk),
		.test_mode(test_mode),
		.test_rst_n(test_rst_n),
		.reset_n_in(reset_n_front_ff),
		.reset_n_out(reset_n_out),
		.reset_n_status(reset_n_status)
	);
endmodule
module scr1_reset_and2_cell (
	rst_n_in,
	test_rst_n,
	test_mode,
	rst_n_out
);
	input wire [1:0] rst_n_in;
	input wire test_rst_n;
	input wire test_mode;
	output wire rst_n_out;
	assign rst_n_out = (test_mode == 1'b1 ? test_rst_n : &rst_n_in);
endmodule
module scr1_reset_and3_cell (
	rst_n_in,
	test_rst_n,
	test_mode,
	rst_n_out
);
	input wire [2:0] rst_n_in;
	input wire test_rst_n;
	input wire test_mode;
	output wire rst_n_out;
	assign rst_n_out = (test_mode == 1'b1 ? test_rst_n : &rst_n_in);
endmodule
module scr1_reset_mux2_cell (
	rst_n_in,
	select,
	test_rst_n,
	test_mode,
	rst_n_out
);
	input wire [1:0] rst_n_in;
	input wire select;
	input wire test_rst_n;
	input wire test_mode;
	output wire rst_n_out;
	assign rst_n_out = (test_mode == 1'b1 ? test_rst_n : rst_n_in[select]);
endmodule
