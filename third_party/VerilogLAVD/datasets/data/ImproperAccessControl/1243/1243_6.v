module test (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         debug_mode_i,
    input  wire [1:0]   key_sel,
    output wire [191:0] key_out 
);
reg [31:0] key0, key1, key2;  

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key0 <= 32'hDEADBEEF;
        key1 <= 32'hCAFEBABE;
        key2 <= 32'hBADDF00D;
    end
end

wire [191:0] key_big0 = {key0, key0, key0, key0, key0, key0};
wire [191:0] key_big1 = {key1, key1, key1, key1, key1, key1};
wire [191:0] key_big2 = {key2, key2, key2, key2, key2, key2};

assign key_out = (key_sel == 2'b00) ? key_big0 :
                 (key_sel == 2'b01) ? key_big1 : 
                 key_big2;
endmodule