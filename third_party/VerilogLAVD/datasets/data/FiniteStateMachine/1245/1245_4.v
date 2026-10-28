module test(
    input        clk,
    input        rst_n,
    input  [2:0] user_input,
    output reg [1:0] state,
    output reg [2:0] out
);

localparam S0 = 2'b00;
localparam S1 = 2'b01;
localparam S2 = 2'b10;
localparam S3 = 2'b11;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S0;
    end else begin
        case (user_input)
            3'h0: state <= S1;
            3'h1: state <= S2;
            3'h2: state <= S3;
            3'h3: state <= S0;
            3'h4: state <= S1;
            3'h5: state <= S2;
        endcase
    end
end

always @(posedge clk) begin
    out <= {1'b1, state};
end

endmodule