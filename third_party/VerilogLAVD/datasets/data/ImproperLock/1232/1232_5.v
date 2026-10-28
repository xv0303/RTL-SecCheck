module test (
    input  wire        clk,  
    input  wire        rst_n,     
    input  wire        sleep_mode,  
    input  wire        wake_up,   
    input  wire        jtag_unlock  
);

reg [31:0] reglk_mem [0:2];
integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n || sleep_mode) begin
        for (i = 0; i < 3; i = i + 1)
            reglk_mem[i] <= 32'h0;
    end
    else if (wake_up) begin
        for (i = 0; i < 3; i = i + 1)
            reglk_mem[i] <= 32'h0;
    end
end

wire can_write = (reglk_mem[0] == 32'h0);
reg [7:0] config_reg;

always @(posedge clk) begin
    if (can_write)
        config_reg <= config_reg + 1;
end

endmodule
