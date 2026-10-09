// access_ctrl.v — 辅助访问控制
module access_ctrl(
  input  wire [7:0] cmd,
  input  wire       cmd_valid,
  input  wire       lock_q,        // 权限锁状态
  output wire       key_write_en
);
  wire cmd_decode = cmd_valid & (cmd[7:0] == 8'h2A);
  wire sel_keyreg = (cmd[7:4] == 4'h3);

  assign key_write_en = cmd_decode & sel_keyreg;
endmodule
