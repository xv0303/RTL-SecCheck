module test (
    input debug_mode_i,
    input [1:0] key_sel,
    output [127:0] key_out
);
    reg [127:0] secure_key0 = 128'hA5A5A5A5_5A5A5A5A_A5A5A5A5_5A5A5A5A;
    reg [127:0] secure_key1 = 128'hDEADBEEF_CAFEBABE_DEADBEEF_CAFEBABE;
    
    wire [127:0] working_key0;
    wire [127:0] working_key1;
    
    assign working_key0 = debug_mode_i ? 128'b0 : secure_key0;
    assign working_key1 = secure_key1;
    
    assign key_out = (key_sel == 2'b01) ? working_key1 : 
                    (key_sel == 2'b00) ? working_key0 : 128'b0;
endmodule