module udma_apb_if (
	PADDR,
	PWDATA,
	PWRITE,
	PSEL,
	PENABLE,
	PRDATA,
	PREADY,
	PSLVERR,
	periph_data_o,
	periph_addr_o,
	periph_data_i,
	periph_ready_i,
	periph_valid_o,
	periph_rwn_o
);
	reg _sv2v_0;
	parameter APB_ADDR_WIDTH = 12;
	input wire [APB_ADDR_WIDTH - 1:0] PADDR;
	input wire [31:0] PWDATA;
	input wire PWRITE;
	input wire PSEL;
	input wire PENABLE;
	output reg [31:0] PRDATA;
	output reg PREADY;
	output wire PSLVERR;
	output wire [31:0] periph_data_o;
	output wire [4:0] periph_addr_o;
	input wire [511:0] periph_data_i;
	input wire [15:0] periph_ready_i;
	output reg [15:0] periph_valid_o;
	output wire periph_rwn_o;
	wire [3:0] s_periph_sel;
	wire s_periph_valid;
	assign periph_addr_o = PADDR[6:2];
	assign periph_rwn_o = ~PWRITE;
	assign periph_data_o = PWDATA;
	assign s_periph_sel = PADDR[10:7];
	assign s_periph_valid = PSEL & PENABLE;
	assign PSLVERR = 1'b0;
	always @(*) begin : proc_PRDATA
		if (_sv2v_0)
			;
		PRDATA = 'h0;
		PREADY = 1'b0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 16; i = i + 1)
				if (s_periph_sel == i) begin
					PRDATA = periph_data_i[i * 32+:32];
					PREADY = periph_ready_i[i];
				end
		end
	end
	always @(*) begin : proc_periph_valid
		if (_sv2v_0)
			;
		periph_valid_o = 'h0;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < 16; i = i + 1)
				if (s_periph_valid && (s_periph_sel == i))
					periph_valid_o[i] = 1'b1;
		end
	end
	initial _sv2v_0 = 0;
endmodule
