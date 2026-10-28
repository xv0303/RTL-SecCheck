module tb_clk_gen (clk_o);
	parameter CLK_PERIOD = 1.0;
	output reg clk_o;
	initial begin
		clk_o = 1'b1;
		#(CLK_PERIOD)
			;
		forever clk_o = #(CLK_PERIOD / 2) ~clk_o;
	end
endmodule
