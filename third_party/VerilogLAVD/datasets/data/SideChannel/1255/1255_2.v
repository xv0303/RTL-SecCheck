module test(
    input         clk,
    input         rst,
    input         start,     
    input  [63:0] key_in,    
    output reg    auth_ok,   
    output reg    done   
);

    localparam [63:0] REF_KEY = {8'h50,8'h40,8'h73,8'h73,8'h57,8'h30,8'h72,8'h64};
    integer           i;
    reg [3:0]         err_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            auth_ok <= 0;
            done    <= 0;
            err_cnt <= 0;
        end else if (start) begin
            err_cnt <= 0;
            done    <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                if (err_cnt == 0) begin
                    if (key_in[8*i+7 -: 8] != REF_KEY[8*i+7 -: 8])
                        err_cnt <= err_cnt + 1;
                end
            end
            auth_ok <= (err_cnt == 0);
            done    <= 1;
        end
    end

endmodule
