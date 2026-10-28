module test(
  input clk,
  input rst,
  input start,
  input [3:0] cfg_input,
  input [15:0] addr_input
);

  localparam IDLE = 1'b0;
  localparam WORK = 1'b1;

  reg state;
  wire access_grant;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= IDLE;
    else if (state == IDLE && start) state <= WORK;
    else if (state == WORK) state <= IDLE;
  end

  assign access_grant = (addr_input < cfg_input * 4096);

endmodule