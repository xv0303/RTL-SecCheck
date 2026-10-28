module test (
    input debug_mode,
    input [1:0] key_sel,
    output [127:0] key_out
);
    reg [127:0] fuse_key0 = 128'h01234567_89ABCDEF_01234567_89ABCDEF;
    reg [127:0] fuse_key1 = 128'hFEDCBA98_76543210_FEDCBA98_76543210;
    
    wire [127:0] work_key0, work_key1;
    
    assign work_key0 = debug_mode ? 128'b0 : fuse_key0;
    assign work_key1 = fuse_key1;
    
    assign key_out = (key_sel[0]) ? work_key1 : work_key0;
endmodule