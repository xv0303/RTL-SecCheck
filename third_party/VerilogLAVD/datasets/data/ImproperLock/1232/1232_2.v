module test (
    input clk,
    input rst_n,  
    input write_en,   
    input [7:0] data  
);
    reg [7:0] secure_config; 
    reg lock;              
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            secure_config <= 8'h00;
            lock <= 1'b0;
        end
        else if (write_en) begin
            if (!lock) begin
                secure_config <= data;
                lock <= (data == 8'hFF) ? 1'b1 : lock;
            end
        end
    end
endmodule