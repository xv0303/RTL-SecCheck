module io_generic_fifo (
	clk_i,
	rstn_i,
	clr_i,
	elements_o,
	data_o,
	valid_o,
	ready_i,
	valid_i,
	data_i,
	ready_o
);
	parameter DATA_WIDTH = 32;
	parameter BUFFER_DEPTH = 2;
	parameter LOG_BUFFER_DEPTH = (BUFFER_DEPTH < 1 ? 0 : (BUFFER_DEPTH < 2 ? 1 : (BUFFER_DEPTH < 4 ? 2 : (BUFFER_DEPTH < 8 ? 3 : (BUFFER_DEPTH < 16 ? 4 : (BUFFER_DEPTH < 32 ? 5 : (BUFFER_DEPTH < 64 ? 6 : (BUFFER_DEPTH < 128 ? 7 : (BUFFER_DEPTH < 256 ? 8 : (BUFFER_DEPTH < 512 ? 9 : (BUFFER_DEPTH < 1024 ? 10 : (BUFFER_DEPTH < 2048 ? 11 : (BUFFER_DEPTH < 4096 ? 12 : (BUFFER_DEPTH < 8192 ? 13 : (BUFFER_DEPTH < 16384 ? 14 : (BUFFER_DEPTH < 32768 ? 15 : (BUFFER_DEPTH < 65536 ? 16 : (BUFFER_DEPTH < 131072 ? 17 : (BUFFER_DEPTH < 262144 ? 18 : (BUFFER_DEPTH < 524288 ? 19 : (BUFFER_DEPTH < 1048576 ? 20 : (BUFFER_DEPTH < 2097152 ? 21 : (BUFFER_DEPTH < 4194304 ? 22 : (BUFFER_DEPTH < 8388608 ? 23 : (BUFFER_DEPTH < 16777216 ? 24 : 25)))))))))))))))))))))))));
	input wire clk_i;
	input wire rstn_i;
	input wire clr_i;
	output wire [LOG_BUFFER_DEPTH:0] elements_o;
	output wire [DATA_WIDTH - 1:0] data_o;
	output wire valid_o;
	input wire ready_i;
	input wire valid_i;
	input wire [DATA_WIDTH - 1:0] data_i;
	output wire ready_o;
	reg [LOG_BUFFER_DEPTH - 1:0] pointer_in;
	reg [LOG_BUFFER_DEPTH - 1:0] pointer_out;
	reg [LOG_BUFFER_DEPTH:0] elements;
	reg [DATA_WIDTH - 1:0] buffer [BUFFER_DEPTH - 1:0];
	wire full;
	reg [31:0] loop1;
	assign full = elements == BUFFER_DEPTH;
	assign elements_o = elements;
	always @(posedge clk_i or negedge rstn_i) begin : elements_sequential
		if (rstn_i == 1'b0)
			elements <= 0;
		else if (clr_i)
			elements <= 0;
		else if ((ready_i && valid_o) && (!valid_i || full))
			elements <= elements - 1;
		else if (((!valid_o || !ready_i) && valid_i) && !full)
			elements <= elements + 1;
	end
	always @(posedge clk_i or negedge rstn_i) begin : buffers_sequential
		if (rstn_i == 1'b0)
			for (loop1 = 0; loop1 < BUFFER_DEPTH; loop1 = loop1 + 1)
				buffer[loop1] <= 0;
		else if (valid_i && !full)
			buffer[pointer_in] <= data_i;
	end
	always @(posedge clk_i or negedge rstn_i) begin : sequential
		if (rstn_i == 1'b0) begin
			pointer_out <= 0;
			pointer_in <= 0;
		end
		else if (clr_i) begin
			pointer_out <= 0;
			pointer_in <= 0;
		end
		else begin
			if (valid_i && !full) begin
				if (pointer_in == $unsigned(BUFFER_DEPTH - 1))
					pointer_in <= 0;
				else
					pointer_in <= pointer_in + 1;
			end
			if (ready_i && valid_o) begin
				if (pointer_out == $unsigned(BUFFER_DEPTH - 1))
					pointer_out <= 0;
				else
					pointer_out <= pointer_out + 1;
			end
		end
	end
	assign data_o = buffer[pointer_out];
	assign valid_o = elements != 0;
	assign ready_o = ~full;
endmodule
