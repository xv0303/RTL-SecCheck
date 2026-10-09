// crypto_core.v — 密钥寄存器核
module crypto_core(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        key_wr,
  input  wire [31:0] key_wdata,
  output reg  [31:0] key_reg,
  output wire        busy
);
  reg [31:0] status_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      key_reg <= 32'd0;
    else if (key_wr)
      key_reg <= key_wdata;
  end

  always @(posedge clk) begin
    status_reg <= {key_reg[31:8], key_reg[7:0], busy};
  end

  assign busy = key_wr;
endmodule
