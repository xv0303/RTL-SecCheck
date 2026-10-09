// top.v — 顶层: 总线命令 + 权限锁 + 密钥核 + 调试桥
module top(
  input  wire        clk,
  input  wire        rst_n,
  input  wire [7:0]  cmd_addr,
  input  wire [7:0]  cmd_wdata,
  input  wire        cmd_wr,
  input  wire        jtag_tck,
  input  wire [4:0]  dbg_addr,
  output wire [31:0] dbg_rdata,
  output wire        sec_alert
);
  wire        lock_status;
  wire        key_wr, cfg_wr, key_write_en;
  wire [31:0] key_reg;
  wire        busy;

  lock_ctrl u_lock (
    .clk        (clk),
    .rst_n      (rst_n),
    .unlock_req (cmd_wr & (cmd_addr == 8'h01)),
    .secret     (cmd_wdata[7:0]),
    .lock_status(lock_status)
  );

  decoder u_dec (
    .addr       (cmd_addr),
    .lock_status(lock_status),
    .key_wr     (key_wr),
    .cfg_wr     (cfg_wr)
  );

  access_ctrl u_acc (
    .cmd         (cmd_wdata),
    .cmd_valid   (cmd_wr),
    .lock_q      (lock_status),
    .key_write_en(key_write_en)
  );

  crypto_core u_core (
    .clk      (clk),
    .rst_n    (rst_n),
    .key_wr   (key_wr | key_write_en),
    .key_wdata({24'd0, cmd_wdata}),
    .key_reg  (key_reg),
    .busy     (busy)
  );

  dbg_bridge u_dbg (
    .tck     (jtag_tck),
    .dbg_addr(dbg_addr),
    .auth_ok (lock_status),
    .dbg_rdata(dbg_rdata)
  );

  assign sec_alert = (key_wr | key_write_en) & ~lock_status;
endmodule
