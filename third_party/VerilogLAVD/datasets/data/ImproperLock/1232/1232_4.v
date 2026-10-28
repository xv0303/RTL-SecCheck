module test (
    input clk, rst_n,  
    input [3:0] region_sel,  
    input [7:0] config_data, 
    input write_en   
);
    reg [7:0] crypto_cfg, pmu_cfg, io_cfg, boot_cfg;
    reg [3:0] region_lock;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            region_lock <= 4'b0000;
        end
        else if (write_en) begin
            if (!region_lock[region_sel]) begin 
                case (region_sel)
                    0: crypto_cfg <= config_data; 
                    1: pmu_cfg    <= config_data; 
                    2: io_cfg     <= config_data; 
                    3: boot_cfg   <= config_data; 
                endcase
            end
        end
    end
endmodule