module varcic (
	clk_i,
	rstn_i,
	cfg_update_i,
	cfg_decimation_i,
	cfg_shift_i,
	data_i,
	data_valid_i,
	data_o,
	data_valid_o
);
	reg _sv2v_0;
	parameter STAGES = 5;
	parameter ACC_WIDTH = 51;
	input wire clk_i;
	input wire rstn_i;
	input wire cfg_update_i;
	input wire [9:0] cfg_decimation_i;
	input wire [2:0] cfg_shift_i;
	input wire data_i;
	input wire data_valid_i;
	output reg [15:0] data_o;
	output reg data_valid_o;
	wire [ACC_WIDTH - 1:0] integrator_data [0:STAGES];
	wire [ACC_WIDTH - 1:0] comb_data [0:STAGES];
	reg [9:0] r_sample_nr;
	always @(posedge clk_i or negedge rstn_i)
		if (~rstn_i) begin
			r_sample_nr <= 'h0;
			data_valid_o <= 1'b0;
		end
		else if (cfg_update_i) begin
			r_sample_nr <= 0;
			data_valid_o <= 0;
		end
		else if (data_valid_i) begin
			if (r_sample_nr == cfg_decimation_i) begin
				r_sample_nr <= 0;
				data_valid_o <= 1;
			end
			else begin
				r_sample_nr <= r_sample_nr + 1;
				data_valid_o <= 0;
			end
		end
		else
			data_valid_o <= 0;
	assign integrator_data[0] = (data_i ? 'h1 : {ACC_WIDTH {1'b1}});
	assign comb_data[0] = integrator_data[STAGES];
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < STAGES; _gv_i_1 = _gv_i_1 + 1) begin : cic_stages
			localparam i = _gv_i_1;
			cic_integrator #(ACC_WIDTH) cic_integrator_inst(
				.clk_i(clk_i),
				.rstn_i(rstn_i),
				.clr_i(cfg_update_i),
				.en_i(data_valid_i),
				.data_i(integrator_data[i]),
				.data_o(integrator_data[i + 1])
			);
			cic_comb #(ACC_WIDTH) cic_comb_inst(
				.clk_i(clk_i),
				.rstn_i(rstn_i),
				.clr_i(cfg_update_i),
				.en_i(data_valid_o),
				.data_i(comb_data[i]),
				.data_o(comb_data[i + 1])
			);
		end
	endgenerate
	always @(*) begin : proc_data_o
		if (_sv2v_0)
			;
		data_o = 'h0;
		case (cfg_shift_i)
			0: data_o = comb_data[STAGES][ACC_WIDTH - 1:ACC_WIDTH - 16];
			1: data_o = comb_data[STAGES][ACC_WIDTH - 6:ACC_WIDTH - 21];
			2: data_o = comb_data[STAGES][ACC_WIDTH - 11:ACC_WIDTH - 26];
			3: data_o = comb_data[STAGES][ACC_WIDTH - 16:ACC_WIDTH - 31];
			4: data_o = comb_data[STAGES][ACC_WIDTH - 21:ACC_WIDTH - 36];
			5: data_o = comb_data[STAGES][ACC_WIDTH - 26:ACC_WIDTH - 41];
			6: data_o = comb_data[STAGES][ACC_WIDTH - 31:ACC_WIDTH - 46];
			7: data_o = comb_data[STAGES][ACC_WIDTH - 36:ACC_WIDTH - 51];
			default: data_o = comb_data[STAGES][ACC_WIDTH - 1:ACC_WIDTH - 16];
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
