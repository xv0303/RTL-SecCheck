module tb_fs_handler (
	clk,
	rst_n,
	CSN,
	WEN,
	ADDR,
	WDATA,
	BE,
	RDATA
);
	parameter ADDR_WIDTH = 32;
	parameter DATA_WIDTH = 64;
	parameter NB_CORES = 4;
	input wire clk;
	input wire rst_n;
	input wire CSN;
	input wire WEN;
	input wire [ADDR_WIDTH - 1:0] ADDR;
	input wire [DATA_WIDTH - 1:0] WDATA;
	input wire [(DATA_WIDTH / 8) - 1:0] BE;
	output reg [DATA_WIDTH - 1:0] RDATA;
	wire [11:0] add_fopen;
	wire [31:0] dat_fopen;
	wire req_fopen;
	wire [11:0] add_stdout;
	wire [31:0] dat_stdout;
	wire req_stdout;
	integer FILE_00;
	integer FILE_TO_OPEN;
	string file_name;
	integer tmp;
	integer single_char;
	wire req_rw;
	wire add_rw;
	wire dat_rw;
	event FOPEN_EVENT;
	event FCLOSE_EVENT;
	event READ_EVENT;
	event WRITE_EVENT;
	assign req_stdout = ((CSN == 1'b0) && (WEN == 1'b0)) && ({ADDR[31:12], 12'h000} == 32'h1a10f000);
	assign req_fopen = ((CSN == 1'b0) && (WEN == 1'b0)) && (ADDR == 32'h1a112000);
	assign req_rw = (CSN == 1'b0) && (ADDR == 32'h1a113000);
	assign add_stdout = ADDR[11:0];
	assign add_fopen = ADDR[11:0];
	assign add_rw = ADDR[11:0];
	assign dat_stdout = WDATA[31:0];
	assign dat_fopen = WDATA[31:0];
	assign dat_rw = WDATA[31:0];
	tb_fs_handler_debug #(
		.ADDR_WIDTH(9),
		.DATA_WIDTH(32),
		.NB_CORES(NB_CORES),
		.CLUSTER_ID(0),
		.DEBUG_TYPE("PE"),
		.SILENT_MODE("OFF"),
		.COLORED_MODE("OFF")
	) STDOUT_PRINTF_CLUSTER(
		.rst_ni(rst_n),
		.clk_i(clk),
		.req_i(req_stdout),
		.add_i(ADDR[11:3]),
		.dat_i(WDATA[31:0])
	);
	tb_fs_handler_debug #(
		.ADDR_WIDTH(14),
		.DATA_WIDTH(32),
		.NB_CORES(NB_CORES),
		.CLUSTER_ID(0),
		.DEBUG_TYPE("FS"),
		.SILENT_MODE("OFF"),
		.COLORED_MODE("OFF")
	) FS_PRINTF_CLUSTER(
		.rst_ni(rst_n),
		.clk_i(clk),
		.req_i(req_fopen),
		.add_i(ADDR[13:0]),
		.dat_i(WDATA[31:0])
	);
	tb_fs_handler_debug #(
		.ADDR_WIDTH(9),
		.DATA_WIDTH(32),
		.NB_CORES(NB_CORES),
		.CLUSTER_ID(31),
		.DEBUG_TYPE("PE"),
		.SILENT_MODE("OFF"),
		.COLORED_MODE("OFF")
	) STDOUT_PRINTF_FC(
		.rst_ni(rst_n),
		.clk_i(clk),
		.req_i(req_stdout),
		.add_i(ADDR[11:3]),
		.dat_i(WDATA[31:0])
	);
	tb_fs_handler_debug #(
		.ADDR_WIDTH(14),
		.DATA_WIDTH(32),
		.NB_CORES(1),
		.CLUSTER_ID(31),
		.DEBUG_TYPE("FS"),
		.SILENT_MODE("OFF"),
		.COLORED_MODE("OFF")
	) FS_PRINTF_FC(
		.rst_ni(rst_n),
		.clk_i(clk),
		.req_i(req_fopen),
		.add_i(ADDR[13:0]),
		.dat_i(WDATA[31:0])
	);
	task FOPEN;
		begin
			FILE_00 = $fopen("fs/file_00.txt", "r");
			tmp = $fgets(file_name, FILE_00);
			$fclose(FILE_00);
			$display("Opening Binary file %s", file_name);
			file_name = file_name.substr(0, file_name.len() - 2);
			FILE_TO_OPEN = $fopen(file_name, "r+b");
			if (!FILE_TO_OPEN)
				$display("Error [%0t] ./dataset/filestructure_hackatdac18/install/tb_fs_handler.sv:210:10 - tb_fs_handler.FOPEN.<unnamed_block>\n msg: ", $time, "Error opening the file %s", file_name);
		end
	endtask
	always @(FOPEN_EVENT)
		FOPEN;
	task FCLOSE;
		begin
			FILE_00 = $fopen("fs/file_00.txt", "r");
			tmp = $fgets(file_name, FILE_00);
			$fclose(FILE_00);
			$display("Closing Binary file %s", file_name);
			$fclose(FILE_TO_OPEN);
		end
	endtask
	always @(FCLOSE_EVENT)
		FCLOSE;
	task F_READ;
		single_char = $fgetc(FILE_TO_OPEN);
	endtask
	always @(READ_EVENT)
		F_READ;
	task F_WRITE;
		$fwrite(FILE_TO_OPEN, "%c", WDATA);
	endtask
	always @(WRITE_EVENT)
		F_WRITE;
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0)
			RDATA <= 1'sb0;
		else begin
			RDATA <= single_char;
			if ((((ADDR == 32'h1a112000) && (CSN == 1'b0)) && (WEN == 1'b0)) && (WDATA == 0))
				-> FOPEN_EVENT;
			if ((((ADDR == 32'h1a112000) && (CSN == 1'b0)) && (WEN == 1'b0)) && (WDATA == 1))
				-> FCLOSE_EVENT;
			if (((ADDR == 32'h1a113000) && (CSN == 1'b0)) && (WEN == 1'b1))
				-> READ_EVENT;
			if (((ADDR == 32'h1a113000) && (CSN == 1'b0)) && (WEN == 1'b0))
				-> WRITE_EVENT;
		end
endmodule
module tb_fs_handler_debug (
	rst_ni,
	clk_i,
	req_i,
	add_i,
	dat_i
);
	parameter ADDR_WIDTH = 12;
	parameter DATA_WIDTH = 32;
	parameter NB_CORES = 4;
	parameter CLUSTER_ID = 0;
	parameter DEBUG_TYPE = "FS";
	parameter SILENT_MODE = "OFF";
	parameter FULL_LINE = "ON";
	parameter COLORED_MODE = "ON";
	input wire rst_ni;
	input wire clk_i;
	input wire req_i;
	input wire [ADDR_WIDTH - 1:0] add_i;
	input wire [DATA_WIDTH - 1:0] dat_i;
	integer IOFILE [0:NB_CORES - 1];
	string FILENAME [0:NB_CORES - 1];
	string FILE_ID;
	string CLUSTER_ID_STR;
	reg [31:0] core_index;
	wire [31:0] index;
	string LINE_BUFFER [0:NB_CORES - 1];
	initial for (core_index = 0; core_index < NB_CORES; core_index = core_index + 1)
		begin : _CREATE_IO_FILES_
			FILE_ID.itoa(core_index);
			CLUSTER_ID_STR.itoa(CLUSTER_ID);
			case (DEBUG_TYPE)
				"FS": FILENAME[core_index] = {"fs/file_", CLUSTER_ID_STR, "_", FILE_ID, ".txt"};
				"PE": FILENAME[core_index] = {"stdout/stdout_fake_pe", CLUSTER_ID_STR, "_", FILE_ID};
			endcase
			IOFILE[core_index] = $fopen(FILENAME[core_index], "w");
			LINE_BUFFER[core_index] = "";
		end
	always @(posedge clk_i)
		if (rst_ni == 1'b1) begin
			if ((req_i == 1'b1) && (CLUSTER_ID == add_i[ADDR_WIDTH - 1:4])) begin
				if (NB_CORES > 1)
					core_index = add_i[3:0];
				else
					core_index = 0;
				$fwrite(IOFILE[core_index], "%s", dat_i[7:0]);
				if (SILENT_MODE == "OFF") begin
					if (COLORED_MODE == "ON")
						case (core_index)
							0:
								$write("%c[1;30m", 27);
							1:
								$write("%c[1;31m", 27);
							2:
								$write("%c[1;32m", 27);
							3:
								$write("%c[1;33m", 27);
							4:
								$write("%c[1;34m", 27);
							5:
								$write("%c[1;35m", 27);
							6:
								$write("%c[1;36m", 27);
							7:
								$write("%c[4;30m", 27);
							8:
								$write("%c[4;31m", 27);
							9:
								$write("%c[4;32m", 27);
							10:
								$write("%c[4;33m", 27);
							11:
								$write("%c[4;34m", 27);
							12:
								$write("%c[4;35m", 27);
							13:
								$write("%c[4;36m", 27);
							14:
								$write("%c[5;30m", 27);
							15:
								$write("%c[5;31m", 27);
						endcase
					if (FULL_LINE == "ON")
						LINE_BUFFER[core_index] = {LINE_BUFFER[core_index], string'(dat_i[7:0])};
					else begin
						$write("Cluster_%d_PE_%0d Required Putchar: %s", CLUSTER_ID, core_index, dat_i[7:0]);
						if (COLORED_MODE == "ON")
							$write("%c[0m\n", 27);
						else
							$write("\n");
					end
				end
				if ((dat_i[7:0] == 10) || (dat_i == 0)) begin
					$fflush(IOFILE[core_index]);
					if (SILENT_MODE == "OFF") begin
						if (FULL_LINE == "ON") begin
							$display("[STDOUT-CL%0d_PE%0d] %s", CLUSTER_ID, core_index, LINE_BUFFER[core_index].substr(0, LINE_BUFFER[core_index].len() - 2));
							LINE_BUFFER[core_index] = "";
						end
						else
							$display("CL%0d_PE%0d Writing line", CLUSTER_ID, core_index);
					end
				end
			end
		end
endmodule
