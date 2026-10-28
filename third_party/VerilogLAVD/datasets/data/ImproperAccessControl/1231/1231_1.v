module test (
    input wire clk,
    input wire rst,
    input wire [7:0] config_data,
    input wire write_enable,
    output reg lock_bit
);

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      lock_bit <= 1'b1;
    end else if (write_enable) begin
      lock_bit <= config_data[0];
    end
  end

endmodule