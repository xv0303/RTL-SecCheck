module test(out, user_input, clk, rst_n);
  input [2:0] user_input;
  input clk, rst_n;
  output reg [2:0] out;
  reg [1:0] state;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state = 2'b00;
    end else begin
      case (user_input)
        3'h0: ;
        3'h1: state = 2'b01;
        3'h2: state = 2'b10;
        3'h3: state = 2'b11;
      endcase
    end
    out <= {1'b1, state};
  end
endmodule