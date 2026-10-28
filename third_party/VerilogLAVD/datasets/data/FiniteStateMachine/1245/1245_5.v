// 示例 1: 基于状态的输出机，未处理所有状态
module test1(
    input        clk,
    input        rst_n,
    input        event_a,
    input        event_b,
    output reg   alarm
);

reg [1:0]  state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= 2'b00;
        else begin
            case (state)
                2'b00:  if (event_a) state <= 2'b01;
                2'b01:  if (event_b) state <= 2'b10;
                2'b10: ;
            endcase
        end
    end

    always @(state) begin
        case (state)
            2'b00:  alarm = 1'b0;
            2'b01:  alarm = 1'b0;
            2'b10: alarm = 1'b1;
        endcase
    end

endmodule