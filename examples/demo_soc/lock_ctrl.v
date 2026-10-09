// lock_ctrl.v — 权限锁状态机: 上电锁定, 输入正确密钥序列后解锁, 下一拍自动重新上锁
module lock_ctrl(
  input  wire       clk,
  input  wire       rst_n,
  input  wire       unlock_req,
  input  wire [7:0] secret,
  output reg        lock_status   // 1 = 已授权(解锁), 0 = 锁定
);
  localparam [7:0] SECRET = 8'hA5;

  localparam ST_LOCKED   = 1'b0;
  localparam ST_UNLOCKED = 1'b1;

  reg state;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= ST_LOCKED;
    end else begin
      case (state)
        ST_LOCKED:
          if (unlock_req && (secret == SECRET))
            state <= ST_UNLOCKED;
        ST_UNLOCKED:
          state <= ST_LOCKED;
        default:
          state <= ST_LOCKED;
      endcase
    end
  end

  always @(*) lock_status = (state == ST_UNLOCKED);
endmodule
