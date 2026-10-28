module pulp_power_gating (
	sleep_i,
	sleepout_o
);
	input wire sleep_i;
	output wire sleepout_o;
	assign sleepout_o = sleep_i;
endmodule
