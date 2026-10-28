module test(
    input        clk,
    input        rst,
    input        write_enable,
    input        lock_set,
    input  [7:0] data_in,
    output reg [7:0] reg_data,
    output reg   lock_bit
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_data <= 8'h00;
        lock_bit <= 1'b1;
    end else begin
        if (lock_set) begin
            lock_bit <= 1'b1;
        end else if (write_enable) begin
            lock_bit <= data_in[0];
        end

        if (write_enable && !lock_bit) begin
            reg_data <= data_in;
        end
    end
end

endmodule