module simulator_ctrl (
	clk_i,
	rst_ni,
	req_i,
	we_i,
	be_i,
	addr_i,
	wdata_i,
	rvalid_o,
	rdata_o
);
	parameter LogName = "ibex_out.log";
	parameter [0:0] FlushOnChar = 1;
	input clk_i;
	input rst_ni;
	input req_i;
	input we_i;
	input [3:0] be_i;
	input [31:0] addr_i;
	input [31:0] wdata_i;
	output reg rvalid_o;
	output wire [31:0] rdata_o;
	localparam [7:0] CHAR_OUT_ADDR = 8'h00;
	localparam [7:0] SIM_CTRL_ADDR = 8'h02;
	wire [7:0] ctrl_addr;
	reg [2:0] sim_finish;
	integer log_fd;
	initial log_fd = $fopen(LogName, "w");
	final $fclose(log_fd);
	assign ctrl_addr = addr_i[9:2];
	always @(posedge clk_i or negedge rst_ni) begin
		if (~rst_ni) begin
			rvalid_o <= 0;
			sim_finish <= 'b0;
		end
		else begin
			rvalid_o <= req_i;
			if (req_i & we_i)
				case (ctrl_addr)
					CHAR_OUT_ADDR:
						if (be_i[0]) begin
							$fwrite(log_fd, "%c", wdata_i[7:0]);
							if (FlushOnChar)
								$fflush(log_fd);
						end
					SIM_CTRL_ADDR:
						if ((be_i[0] & wdata_i[0]) && (sim_finish == 'b0)) begin
							$display("Terminating simulation by software request.");
							sim_finish <= 3'b001;
						end
					default:
						;
				endcase
		end
		if (sim_finish != 'b0)
			sim_finish <= sim_finish + 1;
		if (sim_finish >= 3'b010)
			$finish;
	end
	assign rdata_o = 1'sb0;
endmodule
