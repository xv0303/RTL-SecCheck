module test(
    input         clk,
    input         rst,
    input         start,       
    input  [7:0]  key_in,      
    output reg    match,       
    output reg    ready        
);

    reg [7:0] stored_key = 8'h3C;   
    reg        mismatch;            
    integer    i;                   

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            match    <= 0;
            ready    <= 0;
            mismatch <= 0;
        end else if (start) begin
            mismatch <= 0;
            ready    <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (!mismatch) begin
                    if (key_in[i] != stored_key[i]) begin
                        mismatch <= 1;
                    end
                end
            end
            match <= ~mismatch;
            ready <= 1;
        end
    end

endmodule
