module test (
    input       clk,        
    input       rst_n,      
    input       unlock_req, 
    output reg  lock_state  
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            lock_state <= 1'b1;
        else if (unlock_req) 
            lock_state <= 1'b0;
    end
endmodule