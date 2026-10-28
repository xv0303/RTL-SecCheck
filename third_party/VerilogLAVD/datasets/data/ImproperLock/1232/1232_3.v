module test (
    input clk, rst_n,
    input [31:0] config_data, 
    input write_en          
);
    reg [31:0] dram_config; 
    reg config_lock;   
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            config_lock <= 1'b0;
            dram_config <= 32'h0;
        end
        else if (write_en && !config_lock) begin
            dram_config <= config_data;
            config_lock <= (config_data[31]) ? 1'b1 : config_lock;
        end
    end
endmodule