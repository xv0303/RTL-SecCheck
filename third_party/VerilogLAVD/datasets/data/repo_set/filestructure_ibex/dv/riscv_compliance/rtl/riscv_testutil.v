module riscv_testutil (
	clk_i,
	rst_ni,
	dev_req_i,
	dev_we_i,
	dev_addr_i,
	dev_wdata_i,
	dev_be_i,
	dev_rvalid_o,
	dev_rdata_o,
	dev_err_o,
	host_req_o,
	host_gnt_i,
	host_rvalid_i,
	host_addr_o,
	host_rdata_i
);
	reg _sv2v_0;
	input clk_i;
	input rst_ni;
	input dev_req_i;
	input dev_we_i;
	input [31:0] dev_addr_i;
	input [31:0] dev_wdata_i;
	input [3:0] dev_be_i;
	output reg dev_rvalid_o;
	output wire [31:0] dev_rdata_o;
	output reg dev_err_o;
	output wire host_req_o;
	input host_gnt_i;
	input host_rvalid_i;
	output wire [31:0] host_addr_o;
	input [31:0] host_rdata_i;
	localparam ADDR_HALT = 0;
	localparam ADDR_SET_BEGIN_SIGNATURE = 4;
	localparam ADDR_SET_END_SIGNATURE = 8;
	wire [21:0] unused_addr;
	assign unused_addr = dev_addr_i[31:10];
	reg [31:0] begin_signature_addr_d;
	reg [31:0] begin_signature_addr_q;
	reg [31:0] end_signature_addr_d;
	reg [31:0] end_signature_addr_q;
	reg read_signature_and_terminate;
	always @(*) begin
		if (_sv2v_0)
			;
		read_signature_and_terminate = 1'b0;
		begin_signature_addr_d = begin_signature_addr_q;
		end_signature_addr_d = end_signature_addr_q;
		if (dev_we_i && dev_req_i)
			case (dev_addr_i[9:0])
				ADDR_HALT: read_signature_and_terminate = 1'b1;
				ADDR_SET_BEGIN_SIGNATURE: begin_signature_addr_d = dev_wdata_i;
				ADDR_SET_END_SIGNATURE: end_signature_addr_d = dev_wdata_i;
				default:
					;
			endcase
	end
	always @(posedge clk_i) begin
		begin_signature_addr_q <= begin_signature_addr_d;
		end_signature_addr_q <= end_signature_addr_d;
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dev_rvalid_o <= 1'b0;
		else
			dev_rvalid_o <= dev_req_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dev_err_o <= 1'b0;
		else
			dev_err_o <= (~dev_we_i | (dev_be_i != 4'hf)) & dev_req_i;
	assign dev_rdata_o = 32'h00000000;
	reg [1:0] state_q;
	reg [1:0] state_d;
	reg [31:0] read_addr_d;
	reg [31:0] read_addr_q;
	always @(*) begin
		if (_sv2v_0)
			;
		state_d = state_q;
		read_addr_d = read_addr_q;
		(* full_case, parallel_case *)
		case (state_q)
			2'd0:
				if (read_signature_and_terminate) begin
					$display("Reading signature from 0x%x to 0x%x", begin_signature_addr_q, end_signature_addr_q);
					state_d = 2'd1;
					read_addr_d = begin_signature_addr_q;
				end
			2'd1:
				if (host_gnt_i) begin
					read_addr_d = read_addr_q + 4;
					if (read_addr_d == end_signature_addr_q)
						state_d = 2'd2;
				end
			2'd2:
				if (host_rvalid_i)
					state_d = 2'd3;
			2'd3: begin
				$display("Terminating simulation by software request.");
				$finish;
			end
			default:
				;
		endcase
	end
	assign host_addr_o = read_addr_q;
	assign host_req_o = state_q == 2'd1;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			state_q <= 2'd0;
			read_addr_q <= 0;
		end
		else begin
			state_q <= state_d;
			read_addr_q <= read_addr_d;
			if (host_rvalid_i)
				$display("SIGNATURE: 0x%x", host_rdata_i);
		end
	initial _sv2v_0 = 0;
endmodule
