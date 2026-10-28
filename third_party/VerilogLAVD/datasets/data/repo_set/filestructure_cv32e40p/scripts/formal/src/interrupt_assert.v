module interrput_assert (
	clk_i,
	rst_ni,
	irq_i,
	irq_ack_o,
	irq_id_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] irq_i;
	input wire irq_ack_o;
	input wire [4:0] irq_id_o;
endmodule
