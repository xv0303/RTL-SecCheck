module test (
    input  clk,
    input  rst,
    input  debug_mode_i,
    output axi_resp_o
);

  reg[31:0] p_c [0:3];
  reg[31:0] state [0:3];
  reg[31:0] key0 [0:5];
  reg[31:0] key1 [0:5];
  reg[31:0] key2 [0:5];
  reg[1:0] key_sel;
  wire[127:0] p_c_big   ;
  wire[127:0] state_big ;
  wire[191:0] key_big ;
  wire [191:0] key_big0, key_big1, key_big2;

  assign p_c_big   = {p_c[0], p_c[1], p_c[2], p_c[3]};
  assign state_big = {state[0], state[1], state[2], state[3]};
  assign key_big0  = debug_mode_i ? 192'b0 : {key0[0], key0[1], key0[2], key0[3], key0[4], key0[5]};
  assign key_big1  = debug_mode_i ? 192'b0 : {key1[0], key1[1], key1[2], key1[3], key1[4], key1[5]};
  assign key_big2  = {key2[0], key2[1], key2[2], key2[3], key2[4], key2[5]};
  assign key_big   = key_sel[1] ? key_big2 : (key_sel[0] ? key_big1 : key_big0);

endmodule
