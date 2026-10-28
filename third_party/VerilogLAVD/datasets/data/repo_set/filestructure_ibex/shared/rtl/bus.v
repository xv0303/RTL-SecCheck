module bus (
	clk_i,
	rst_ni,
	host_req_i,
	host_gnt_o,
	host_addr_i,
	host_we_i,
	host_be_i,
	host_wdata_i,
	host_rvalid_o,
	host_rdata_o,
	host_err_o,
	device_req_o,
	device_addr_o,
	device_we_o,
	device_be_o,
	device_wdata_o,
	device_rvalid_i,
	device_rdata_i,
	device_err_i,
	cfg_device_addr_base,
	cfg_device_addr_mask
);
	reg _sv2v_0;
	parameter signed [31:0] NrDevices = 1;
	parameter signed [31:0] NrHosts = 1;
	parameter signed [31:0] DataWidth = 32;
	parameter signed [31:0] AddressWidth = 32;
	input clk_i;
	input rst_ni;
	input [0:NrHosts - 1] host_req_i;
	output reg [0:NrHosts - 1] host_gnt_o;
	input [(NrHosts * AddressWidth) - 1:0] host_addr_i;
	input [0:NrHosts - 1] host_we_i;
	input [(NrHosts * (DataWidth / 8)) - 1:0] host_be_i;
	input [(NrHosts * DataWidth) - 1:0] host_wdata_i;
	output reg [0:NrHosts - 1] host_rvalid_o;
	output reg [(NrHosts * DataWidth) - 1:0] host_rdata_o;
	output reg [0:NrHosts - 1] host_err_o;
	output reg [0:NrDevices - 1] device_req_o;
	output reg [(NrDevices * AddressWidth) - 1:0] device_addr_o;
	output reg [0:NrDevices - 1] device_we_o;
	output reg [(NrDevices * (DataWidth / 8)) - 1:0] device_be_o;
	output reg [(NrDevices * DataWidth) - 1:0] device_wdata_o;
	input [0:NrDevices - 1] device_rvalid_i;
	input [(NrDevices * DataWidth) - 1:0] device_rdata_i;
	input [0:NrDevices - 1] device_err_i;
	input [(NrDevices * AddressWidth) - 1:0] cfg_device_addr_base;
	input [(NrDevices * AddressWidth) - 1:0] cfg_device_addr_mask;
	localparam [31:0] NumBitsHostSel = (NrHosts > 1 ? $clog2(NrHosts) : 1);
	localparam [31:0] NumBitsDeviceSel = (NrDevices > 1 ? $clog2(NrDevices) : 1);
	reg host_sel_valid;
	reg device_sel_valid;
	reg decode_err_resp;
	reg [NumBitsHostSel - 1:0] host_sel_req;
	reg [NumBitsHostSel - 1:0] host_sel_resp;
	reg [NumBitsDeviceSel - 1:0] device_sel_req;
	reg [NumBitsDeviceSel - 1:0] device_sel_resp;
	function automatic signed [NumBitsHostSel - 1:0] sv2v_cast_3DCCB_signed;
		input reg signed [NumBitsHostSel - 1:0] inp;
		sv2v_cast_3DCCB_signed = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		host_sel_valid = 1'b0;
		host_sel_req = 1'sb0;
		begin : sv2v_autoblock_1
			integer host;
			for (host = NrHosts - 1; host >= 0; host = host - 1)
				if (host_req_i[host]) begin
					host_sel_valid = 1'b1;
					host_sel_req = sv2v_cast_3DCCB_signed(host);
				end
		end
	end
	function automatic signed [NumBitsDeviceSel - 1:0] sv2v_cast_E714D_signed;
		input reg signed [NumBitsDeviceSel - 1:0] inp;
		sv2v_cast_E714D_signed = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		device_sel_valid = 1'b0;
		device_sel_req = 1'sb0;
		begin : sv2v_autoblock_2
			integer device;
			for (device = 0; device < NrDevices; device = device + 1)
				if ((host_addr_i[((NrHosts - 1) - host_sel_req) * AddressWidth+:AddressWidth] & cfg_device_addr_mask[((NrDevices - 1) - device) * AddressWidth+:AddressWidth]) == cfg_device_addr_base[((NrDevices - 1) - device) * AddressWidth+:AddressWidth]) begin
					device_sel_valid = 1'b1;
					device_sel_req = sv2v_cast_E714D_signed(device);
				end
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			host_sel_resp <= 1'sb0;
			device_sel_resp <= 1'sb0;
			decode_err_resp <= 1'b0;
		end
		else begin
			device_sel_resp <= device_sel_req;
			host_sel_resp <= host_sel_req;
			decode_err_resp <= host_sel_valid & !device_sel_valid;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_3
			integer device;
			for (device = 0; device < NrDevices; device = device + 1)
				if (device_sel_valid && (sv2v_cast_E714D_signed(device) == device_sel_req)) begin
					device_req_o[device] = host_req_i[host_sel_req];
					device_we_o[device] = host_we_i[host_sel_req];
					device_addr_o[((NrDevices - 1) - device) * AddressWidth+:AddressWidth] = host_addr_i[((NrHosts - 1) - host_sel_req) * AddressWidth+:AddressWidth];
					device_wdata_o[((NrDevices - 1) - device) * DataWidth+:DataWidth] = host_wdata_i[((NrHosts - 1) - host_sel_req) * DataWidth+:DataWidth];
					device_be_o[((NrDevices - 1) - device) * (DataWidth / 8)+:DataWidth / 8] = host_be_i[((NrHosts - 1) - host_sel_req) * (DataWidth / 8)+:DataWidth / 8];
				end
				else begin
					device_req_o[device] = 1'b0;
					device_we_o[device] = 1'b0;
					device_addr_o[((NrDevices - 1) - device) * AddressWidth+:AddressWidth] = 'b0;
					device_wdata_o[((NrDevices - 1) - device) * DataWidth+:DataWidth] = 'b0;
					device_be_o[((NrDevices - 1) - device) * (DataWidth / 8)+:DataWidth / 8] = 'b0;
				end
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_4
			integer host;
			for (host = 0; host < NrHosts; host = host + 1)
				begin
					host_gnt_o[host] = 1'b0;
					if (sv2v_cast_3DCCB_signed(host) == host_sel_resp) begin
						host_rvalid_o[host] = device_rvalid_i[device_sel_resp] | decode_err_resp;
						host_err_o[host] = device_err_i[device_sel_resp] | decode_err_resp;
						host_rdata_o[((NrHosts - 1) - host) * DataWidth+:DataWidth] = device_rdata_i[((NrDevices - 1) - device_sel_resp) * DataWidth+:DataWidth];
					end
					else begin
						host_rvalid_o[host] = 1'b0;
						host_err_o[host] = 1'b0;
						host_rdata_o[((NrHosts - 1) - host) * DataWidth+:DataWidth] = 'b0;
					end
				end
		end
		host_gnt_o[host_sel_req] = host_req_i[host_sel_req];
	end
	initial _sv2v_0 = 0;
endmodule
