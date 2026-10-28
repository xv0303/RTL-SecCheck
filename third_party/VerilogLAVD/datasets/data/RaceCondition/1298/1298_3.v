module test(
    input         clk,
    input         rst_n,
    input         en,
    input  [1:0]  sec_cfg,
    output        sensitive_data
);
    reg state;
    localparam IDLE = 1'b0;
    localparam DATA_MODE = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else begin
            case(state)
                IDLE:       state <= en ? DATA_MODE : IDLE;
                DATA_MODE:  state <= en ? DATA_MODE : IDLE;
            endcase
        end
    end

    assign sensitive_data = (state == DATA_MODE) & (sec_cfg == 2'b10);

endmodule