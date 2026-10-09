// dbg_bridge.v — JTAG 调试桥
module dbg_bridge(
  input  wire        tck,
  input  wire [4:0]  dbg_addr,
  input  wire        auth_ok,     // 授权状态
  output reg  [31:0] dbg_rdata
);
  reg [31:0] core_mem [0:31];

  initial begin
    core_mem[0] = 32'hDEAD_BEEF;
    core_mem[1] = 32'hCAFE_0001;
  end

  always @(posedge tck) begin
    dbg_rdata <= core_mem[dbg_addr];
  end
endmodule
