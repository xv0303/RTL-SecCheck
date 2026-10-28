module test (
    input debug_mode_i,
    input [1:0] key_sel,
    output [255:0] key_out
);
    reg [255:0] root_key = 256'h89ABCDEF01234567_FEDCBA9876543210_0123456789ABCDEF_FEDCBA9876543210;
    reg [255:0] enc_key = 256'hDEADBEEFCAFEBABE_1337C0DE5EC0FFEE_8BADF00D5CA1AB1E_1234567890ABCDEF;
    
    wire [255:0] sel_key;
    
    assign sel_key = (key_sel == 2'b10) ? enc_key : root_key;
    
    assign key_out = debug_mode_i ? 
                    ((key_sel == 2'b01) ? 256'b0 : sel_key) : 
                    sel_key;
endmodule