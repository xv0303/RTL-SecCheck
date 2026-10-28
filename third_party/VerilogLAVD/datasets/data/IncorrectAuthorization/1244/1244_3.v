module test (
    input wire clk,
    input wire rst_n,
    input wire [1:0] debug_level,
    input wire debug_en,
    input wire [1:0] access_addr,
    output reg [7:0] access_data
);

    reg [7:0] protected_mem [0:3];
    reg [1:0] sys_state;

    initial begin
        protected_mem[0] = 8'h5A;
        protected_mem[1] = 8'hA5;
        protected_mem[2] = 8'hC3;
        protected_mem[3] = 8'h3C;
        sys_state = 2'b00;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sys_state <= 2'b00;
        else if (sys_state == 2'b00)
            sys_state <= 2'b01;
        else if (sys_state == 2'b01)
            sys_state <= 2'b10;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            access_data <= 8'h00;
        else if (debug_en) begin
            access_data <= protected_mem[access_addr];
        end else begin
            access_data <= 8'h00;
        end
    end

endmodule
