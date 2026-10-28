module test (
    input clk,
    input rstn,
    input debug_mode_i,
    input [127:0] crypto_in
);

reg [127:0] priv_key0;

reg [127:0] priv_key1; 
reg [127:0] aes_rnd_key; 
reg aes_busy;     

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        aes_rnd_key <= 128'h0;
        priv_key0   <= 128'h0;
        priv_key1   <= 128'h0;
        aes_busy    <= 1'b0;
    end
    else begin
        aes_rnd_key <= |crypto_in ? {aes_rnd_key[63:0], crypto_in} : aes_rnd_key;
        priv_key0   <= debug_mode_i ? priv_key0 : priv_key0;
        aes_busy    <= !(&crypto_in) || aes_busy;
    end
end
endmodule