module test(
    input        clk,
    input        rst,
    input        start,          
    input  [7:0] pwd_in,         
    output reg   match,          
    output reg   busy            
);

    reg [7:0] stored_pwd = 8'h5A;
    reg [2:0] bit_cnt;           
    reg       mismatch;          

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy      <= 0;
            match     <= 0;
            bit_cnt   <= 0;
            mismatch  <= 0;
        end else if (start && !busy) begin
            busy      <= 1;
            bit_cnt   <= 0;
            mismatch  <= 0;
        end else if (busy) begin
            if (!mismatch) begin
                if (pwd_in[bit_cnt] != stored_pwd[bit_cnt]) begin
                    mismatch <= 1;
                end
            end
            bit_cnt <= bit_cnt + 1;
            if (bit_cnt == 3'b111) begin
                busy  <= 0;
                match <= ~mismatch;
            end
        end
    end

endmodule
