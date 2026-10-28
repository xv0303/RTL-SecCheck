module test(
    input clk_i,
    input rst_ni,
    input[7:0] reglk_ctrl_i,
    input acct_ctrl_i,
    input debug_mode_i,
    input axi_req_i, 
    output axi_resp_o,
    input rst_2
);

reg  keylen_reg, keylen_reg0, keylen_reg1, keylen_reg2;
reg  [31 : 0] key_reg0 [0 : 7];
reg  [31 : 0] key_reg1 [0 : 7];
reg  [31 : 0] key_reg2 [0 : 7];
reg  [1:0]    key_sel; 

wire  [255 : 0] core_key, core_key0, core_key1, core_key2;
wire            core_keylen;

assign core_key0 = debug_mode_i ? 'b0 : {key_reg0[7], key_reg0[6],
                    key_reg0[5], key_reg0[4], key_reg0[3], key_reg0[2], key_reg0[1], key_reg0[0]};
assign core_key1 = {key_reg1[7], key_reg1[6],
                    key_reg1[5], key_reg1[4], key_reg1[3], key_reg1[2], key_reg1[1], key_reg1[0]};
assign core_key2 = debug_mode_i ? 'b0 : {key_reg2[7], key_reg2[6],
                    key_reg2[5], key_reg2[4], key_reg2[3], key_reg2[2], key_reg2[1], key_reg2[0]};

assign core_key  = key_sel[1] ? core_key2 : (key_sel[0] ? core_key1 : core_key0) ;  
assign core_keylen  = key_sel[1] ? keylen_reg2 : (key_sel[0] ? keylen_reg1 : keylen_reg0) ;  

endmodule