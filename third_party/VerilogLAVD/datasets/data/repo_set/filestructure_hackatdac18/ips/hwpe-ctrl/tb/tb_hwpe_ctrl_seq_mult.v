module tb_hwpe_ctrl_seq_mult;
	localparam AW = 8;
	localparam BW = 8;
	reg clk_i = 1'sb0;
	reg rst_ni = 1'sb1;
	reg [7:0] a;
	reg [7:0] b;
	wire [15:0] prod;
	wire valid;
	reg start;
	localparam TCP = 1.0ns;
	localparam TA = 0.2ns;
	localparam TT = 0.8ns;
	task cycle;
		begin
			clk_i <= #(TCP / 2) 1'b0;
			clk_i <= #(TCP) 1'b1;
			#(TCP)
				;
		end
	endtask
	initial begin
		#(20 * TCP)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 10; i = i + 1)
				cycle;
		end
		rst_ni <= #(TA) 1'b0;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < 10; i = i + 1)
				cycle;
		end
		rst_ni <= #(TA) 1'b1;
		while (1) begin
			a <= #(TA) $random();
			b <= #(TA) $random();
			start <= #(TA) 1'b1;
			cycle;
			start <= #(TA) 1'b0;
			begin : sv2v_autoblock_3
				reg signed [31:0] i;
				for (i = 0; i < AW; i = i + 1)
					cycle;
			end
		end
	end
	hwpe_ctrl_seq_mult #(
		.AW(8),
		.BW(8)
	) ctrl_seq_mult_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.start_i(start),
		.a_i(a),
		.b_i(b),
		.valid_o(valid),
		.prod_o(prod)
	);
endmodule
