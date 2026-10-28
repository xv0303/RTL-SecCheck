module test (
    input [2:0] user_input,
    input clk,
    input rst_n,
    output reg [2:0] out
);

    reg [1:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= 2'h0;
    else begin
        case (user_input)
            3'h0: state <= 2'h3;
            3'h1: state <= 2'h3;
            3'h2: state <= 2'h3;
            3'h3: state <= 2'h3;
            3'h4: state <= 2'h2;
            3'h5: state <= 2'h1;
        endcase
    end
    out <= {1'b1, state};
end

endmodule