module debug_assert (
	clk_i,
	rst_ni,
	debug_req_i,
	debug_havereset_o,
	debug_running_o,
	debug_halted_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire debug_req_i;
	input wire debug_havereset_o;
	input wire debug_running_o;
	input wire debug_halted_o;
endmodule
