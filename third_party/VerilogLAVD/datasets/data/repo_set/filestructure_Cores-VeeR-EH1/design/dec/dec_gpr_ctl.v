module dec_gpr_ctl (
	active_clk,
	raddr0,
	raddr1,
	raddr2,
	raddr3,
	rden0,
	rden1,
	rden2,
	rden3,
	waddr0,
	waddr1,
	waddr2,
	wen0,
	wen1,
	wen2,
	wd0,
	wd1,
	wd2,
	wen_bank_id,
	wr_bank_id,
	clk,
	rst_l,
	rd0,
	rd1,
	rd2,
	rd3,
	scan_mode
);
	reg _sv2v_0;
	parameter GPR_BANKS = 1;
	parameter GPR_BANKS_LOG2 = 1;
	input wire active_clk;
	input wire [4:0] raddr0;
	input wire [4:0] raddr1;
	input wire [4:0] raddr2;
	input wire [4:0] raddr3;
	input wire rden0;
	input wire rden1;
	input wire rden2;
	input wire rden3;
	input wire [4:0] waddr0;
	input wire [4:0] waddr1;
	input wire [4:0] waddr2;
	input wire wen0;
	input wire wen1;
	input wire wen2;
	input wire [31:0] wd0;
	input wire [31:0] wd1;
	input wire [31:0] wd2;
	input wire wen_bank_id;
	input wire [GPR_BANKS_LOG2 - 1:0] wr_bank_id;
	input wire clk;
	input wire rst_l;
	output reg [31:0] rd0;
	output reg [31:0] rd1;
	output reg [31:0] rd2;
	output reg [31:0] rd3;
	input wire scan_mode;
	wire [(((GPR_BANKS * 31) + 0) >= 1 ? (((GPR_BANKS * 31) + 0) * 32) + 31 : ((2 - ((GPR_BANKS * 31) + 0)) * 32) + ((((GPR_BANKS * 31) + 0) * 32) - 1)):(((GPR_BANKS * 31) + 0) >= 1 ? 32 : ((GPR_BANKS * 31) + 0) * 32)] gpr_out;
	reg [1023:32] gpr_in;
	reg [31:1] w0v;
	reg [31:1] w1v;
	reg [31:1] w2v;
	wire [31:1] gpr_wr_en;
	wire [(GPR_BANKS * 31) + 0:1] gpr_bank_wr_en;
	wire [GPR_BANKS_LOG2 - 1:0] gpr_bank_id;
	rvdffs #(GPR_BANKS_LOG2) bankid_ff(
		.*,
		.clk(active_clk),
		.en(wen_bank_id),
		.din(wr_bank_id[GPR_BANKS_LOG2 - 1:0]),
		.dout(gpr_bank_id[GPR_BANKS_LOG2 - 1:0])
	);
	assign gpr_wr_en[31:1] = (w0v[31:1] | w1v[31:1]) | w2v[31:1];
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < GPR_BANKS; _gv_i_1 = _gv_i_1 + 1) begin : gpr_banks
			localparam i = _gv_i_1;
			assign gpr_bank_wr_en[(i * 31) + 31-:31] = gpr_wr_en[31:1] & {31 {gpr_bank_id[GPR_BANKS_LOG2 - 1:0] == i}};
			genvar _gv_j_1;
			for (_gv_j_1 = 1; _gv_j_1 < 32; _gv_j_1 = _gv_j_1 + 1) begin : gpr
				localparam j = _gv_j_1;
				rvdffe #(32) gprff(
					.*,
					.en(gpr_bank_wr_en[(i * 31) + j]),
					.din(gpr_in[(j * 32) + 31-:32]),
					.dout(gpr_out[((((GPR_BANKS * 31) + 0) >= 1 ? (i * 31) + j : 1 - (((i * 31) + j) - ((GPR_BANKS * 31) + 0))) * 32) + 31-:32])
				);
			end
		end
	endgenerate
	function automatic signed [4:0] sv2v_cast_5_signed;
		input reg signed [4:0] inp;
		sv2v_cast_5_signed = inp;
	endfunction
	function automatic signed [0:0] sv2v_cast_1_signed;
		input reg signed [0:0] inp;
		sv2v_cast_1_signed = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		rd0[31:0] = 32'b00000000000000000000000000000000;
		rd1[31:0] = 32'b00000000000000000000000000000000;
		rd2[31:0] = 32'b00000000000000000000000000000000;
		rd3[31:0] = 32'b00000000000000000000000000000000;
		w0v[31:1] = 31'b0000000000000000000000000000000;
		w1v[31:1] = 31'b0000000000000000000000000000000;
		w2v[31:1] = 31'b0000000000000000000000000000000;
		gpr_in[32+:992] = 1'sb0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < GPR_BANKS; i = i + 1)
				begin : sv2v_autoblock_2
					reg signed [31:0] j;
					for (j = 1; j < 32; j = j + 1)
						begin
							rd0[31:0] = rd0[31:0] | ({32 {(rden0 & (raddr0[4:0] == sv2v_cast_5_signed(j))) & (gpr_bank_id[GPR_BANKS_LOG2 - 1:0] == sv2v_cast_1_signed(i))}} & gpr_out[((((GPR_BANKS * 31) + 0) >= 1 ? (i * 31) + j : 1 - (((i * 31) + j) - ((GPR_BANKS * 31) + 0))) * 32) + 31-:32]);
							rd1[31:0] = rd1[31:0] | ({32 {(rden1 & (raddr1[4:0] == sv2v_cast_5_signed(j))) & (gpr_bank_id[GPR_BANKS_LOG2 - 1:0] == sv2v_cast_1_signed(i))}} & gpr_out[((((GPR_BANKS * 31) + 0) >= 1 ? (i * 31) + j : 1 - (((i * 31) + j) - ((GPR_BANKS * 31) + 0))) * 32) + 31-:32]);
							rd2[31:0] = rd2[31:0] | ({32 {(rden2 & (raddr2[4:0] == sv2v_cast_5_signed(j))) & (gpr_bank_id[GPR_BANKS_LOG2 - 1:0] == sv2v_cast_1_signed(i))}} & gpr_out[((((GPR_BANKS * 31) + 0) >= 1 ? (i * 31) + j : 1 - (((i * 31) + j) - ((GPR_BANKS * 31) + 0))) * 32) + 31-:32]);
							rd3[31:0] = rd3[31:0] | ({32 {(rden3 & (raddr3[4:0] == sv2v_cast_5_signed(j))) & (gpr_bank_id[GPR_BANKS_LOG2 - 1:0] == sv2v_cast_1_signed(i))}} & gpr_out[((((GPR_BANKS * 31) + 0) >= 1 ? (i * 31) + j : 1 - (((i * 31) + j) - ((GPR_BANKS * 31) + 0))) * 32) + 31-:32]);
						end
				end
		end
		begin : sv2v_autoblock_3
			reg signed [31:0] j;
			for (j = 1; j < 32; j = j + 1)
				begin
					w0v[j] = wen0 & (waddr0[4:0] == sv2v_cast_5_signed(j));
					w1v[j] = wen1 & (waddr1[4:0] == sv2v_cast_5_signed(j));
					w2v[j] = wen2 & (waddr2[4:0] == sv2v_cast_5_signed(j));
					gpr_in[j * 32+:32] = (({32 {w0v[j]}} & wd0[31:0]) | ({32 {w1v[j]}} & wd1[31:0])) | ({32 {w2v[j]}} & wd2[31:0]);
				end
		end
	end
	initial _sv2v_0 = 0;
endmodule
