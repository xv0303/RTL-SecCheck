// decoder.v — 地址译码
module decoder(
  input  wire [7:0] addr,
  input  wire       lock_status,   // 来自 lock_ctrl 的授权状态
  output wire       key_wr,
  output wire       cfg_wr
);
  localparam ADDR_KEY_CFG = 8'h3C;
  localparam ADDR_CFG     = 8'h40;

  assign key_wr = (addr == ADDR_KEY_CFG);

  assign cfg_wr = (addr == ADDR_CFG) & lock_status;
endmodule
