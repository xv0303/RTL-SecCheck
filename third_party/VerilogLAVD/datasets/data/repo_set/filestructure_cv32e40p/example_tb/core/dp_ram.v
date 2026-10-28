module dp_ram (
	clk_i,
	en_a_i,
	addr_a_i,
	wdata_a_i,
	rdata_a_o,
	we_a_i,
	be_a_i,
	en_b_i,
	addr_b_i,
	wdata_b_i,
	rdata_b_o,
	we_b_i,
	be_b_i
);
	reg _sv2v_0;
	parameter ADDR_WIDTH = 8;
	parameter INSTR_RDATA_WIDTH = 128;
	input wire clk_i;
	input wire en_a_i;
	input wire [ADDR_WIDTH - 1:0] addr_a_i;
	input wire [31:0] wdata_a_i;
	output reg [INSTR_RDATA_WIDTH - 1:0] rdata_a_o;
	input wire we_a_i;
	input wire [3:0] be_a_i;
	input wire en_b_i;
	input wire [ADDR_WIDTH - 1:0] addr_b_i;
	input wire [31:0] wdata_b_i;
	output reg [31:0] rdata_b_o;
	input wire we_b_i;
	input wire [3:0] be_b_i;
	localparam bytes = 2 ** ADDR_WIDTH;
	reg [7:0] mem [0:bytes - 1];
	reg [ADDR_WIDTH - 1:0] addr_a_int;
	reg [ADDR_WIDTH - 1:0] addr_b_int;
	always @(*) begin
		if (_sv2v_0)
			;
		addr_a_int = {addr_a_i[ADDR_WIDTH - 1:2], 2'b00};
	end
	always @(*) begin
		if (_sv2v_0)
			;
		addr_b_int = {addr_b_i[ADDR_WIDTH - 1:2], 2'b00};
	end
	always @(posedge clk_i) begin
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < (INSTR_RDATA_WIDTH / 8); i = i + 1)
				rdata_a_o[i * 8+:8] <= mem[addr_a_int + i];
		end
		if (en_b_i) begin
			if (we_b_i) begin
				if (be_b_i[0])
					mem[addr_b_int] <= wdata_b_i[0+:8];
				if (be_b_i[1])
					mem[addr_b_int + 1] <= wdata_b_i[8+:8];
				if (be_b_i[2])
					mem[addr_b_int + 2] <= wdata_b_i[16+:8];
				if (be_b_i[3])
					mem[addr_b_int + 3] <= wdata_b_i[24+:8];
			end
			else begin
				if ($test$plusargs("verbose"))
					$display("read  addr=0x%08x: data=0x%08x", addr_b_int, {mem[addr_b_int + 3], mem[addr_b_int + 2], mem[addr_b_int + 1], mem[addr_b_int + 0]});
				rdata_b_o[7:0] <= mem[addr_b_int];
				rdata_b_o[15:8] <= mem[addr_b_int + 1];
				rdata_b_o[23:16] <= mem[addr_b_int + 2];
				rdata_b_o[31:24] <= mem[addr_b_int + 3];
			end
		end
	end
	export "DPI-C" function read_byte;
	export "DPI-C" task write_byte;
	function signed [31:0] read_byte;
		input reg [ADDR_WIDTH - 1:0] byte_addr;
		read_byte = mem[byte_addr];
	endfunction
	task write_byte;
		input integer byte_addr;
		input reg [7:0] val;
		output reg [7:0] other;
		begin
			mem[byte_addr] = val;
			other = mem[byte_addr];
		end
	endtask
	initial _sv2v_0 = 0;
endmodule
