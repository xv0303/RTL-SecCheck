module tb_top;
	parameter INSTR_RDATA_WIDTH = 32;
	parameter RAM_ADDR_WIDTH = 22;
	parameter BOOT_ADDR = 'h180;
	parameter PULP_XPULP = 0;
	parameter PULP_CLUSTER = 0;
	parameter FPU = 0;
	parameter ZFINX = 0;
	parameter NUM_MHPMCOUNTERS = 1;
	parameter DM_HALTADDRESS = 32'h1a110800;
	time CLK_PHASE_HI = 5ns;
	time CLK_PHASE_LO = 5ns;
	time CLK_PERIOD = CLK_PHASE_HI + CLK_PHASE_LO;
	time STIM_APPLICATION_DEL = CLK_PERIOD * 0.1;
	time RESP_ACQUISITION_DEL = CLK_PERIOD * 0.9;
	time RESET_DEL = STIM_APPLICATION_DEL;
	reg signed [31:0] RESET_WAIT_CYCLES = 4;
	reg clk = 'b1;
	reg rst_n = 'b0;
	reg [31:0] cycle_cnt_q;
	wire tests_passed;
	wire tests_failed;
	wire exit_valid;
	wire [31:0] exit_value;
	wire fetch_enable;
	assign fetch_enable = 1'sb1;
	initial if ($test$plusargs("vcd")) begin
		$dumpfile("riscy_tb.vcd");
		$dumpvars(0, tb_top);
	end
	initial begin : load_prog
		string firmware;
		reg signed [31:0] prog_size;
		prog_size = 6;
		if ($value$plusargs("firmware=%s", firmware)) begin
			if ($test$plusargs("verbose"))
				$display("[TESTBENCH] %t: loading firmware %0s ...", $time, firmware);
			$readmemh(firmware, wrapper_i.ram_i.dp_ram_i.mem);
		end
		else begin
			$display("No firmware specified");
			$finish;
		end
	end
	initial begin : clock_gen
		forever begin
			#(CLK_PHASE_HI) clk = 1'b0;
			#(CLK_PHASE_LO) clk = 1'b1;
		end
	end
	initial begin : reset_gen
		rst_n = 1'b0;
		repeat (RESET_WAIT_CYCLES) @(posedge clk)
			;
		#(RESET_DEL) rst_n = 1'b1;
		if ($test$plusargs("verbose"))
			$display("reset deasserted", $time);
	end
	initial begin : timing_format
		$timeformat(-9, 0, "ns", 9);
	end
	always @(posedge clk or negedge rst_n) begin : sv2v_autoblock_1
		reg signed [31:0] maxcycles;
		if ($value$plusargs("maxcycles=%d", maxcycles)) begin
			if (~rst_n)
				cycle_cnt_q <= 0;
			else begin
				cycle_cnt_q <= cycle_cnt_q + 1;
				if (cycle_cnt_q >= maxcycles) begin
					$display("Fatal [%0t] ./dataset/filestructure_cv32e40p/example_tb/core/tb_top.sv:121:11 - tb_top.<unnamed_block>.<unnamed_block>.<unnamed_block>.<unnamed_block>\n msg: ", $time, "Simulation aborted due to maximum cycle limit");
					$finish(2);
				end
			end
		end
	end
	always @(posedge clk or negedge rst_n) begin
		if (tests_passed) begin
			$display("ALL TESTS PASSED");
			$finish;
		end
		if (tests_failed) begin
			$display("TEST(S) FAILED!");
			$finish;
		end
		if (exit_valid) begin
			if (exit_value == 0)
				$display("EXIT SUCCESS");
			else
				$display("EXIT FAILURE: %d", exit_value);
			$finish;
		end
	end
	cv32e40p_tb_subsystem #(
		.INSTR_RDATA_WIDTH(INSTR_RDATA_WIDTH),
		.RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
		.BOOT_ADDR(BOOT_ADDR),
		.PULP_XPULP(PULP_XPULP),
		.PULP_CLUSTER(PULP_CLUSTER),
		.FPU(FPU),
		.ZFINX(ZFINX),
		.NUM_MHPMCOUNTERS(NUM_MHPMCOUNTERS),
		.DM_HALTADDRESS(DM_HALTADDRESS)
	) wrapper_i(
		.clk_i(clk),
		.rst_ni(rst_n),
		.fetch_enable_i(fetch_enable),
		.tests_passed_o(tests_passed),
		.tests_failed_o(tests_failed),
		.exit_valid_o(exit_valid),
		.exit_value_o(exit_value)
	);
endmodule
