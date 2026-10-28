module onehot_to_bin (
	onehot,
	bin
);
	parameter ONEHOT_WIDTH = 16;
	parameter BIN_WIDTH = $clog2(ONEHOT_WIDTH);
	input [ONEHOT_WIDTH - 1:0] onehot;
	output wire [BIN_WIDTH - 1:0] bin;
	genvar _gv_i_1;
	genvar _gv_j_1;
	generate
		for (_gv_j_1 = 0; _gv_j_1 < BIN_WIDTH; _gv_j_1 = _gv_j_1 + 1) begin : jl
			localparam j = _gv_j_1;
			wire [ONEHOT_WIDTH - 1:0] tmp_mask;
			for (_gv_i_1 = 0; _gv_i_1 < ONEHOT_WIDTH; _gv_i_1 = _gv_i_1 + 1) begin : il
				localparam i = _gv_i_1;
				wire [BIN_WIDTH - 1:0] tmp_i;
				assign tmp_i = i;
				assign tmp_mask[i] = tmp_i[j];
			end
			assign bin[j] = |(tmp_mask & onehot);
		end
	endgenerate
endmodule
