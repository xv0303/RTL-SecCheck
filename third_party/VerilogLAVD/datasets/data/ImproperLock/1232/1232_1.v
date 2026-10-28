module test(
    input  clk_i,
    input  rst_ni,
    input  jtag_unlock,
    input  rst_9
);

reg [2:0] j;
reg [5:0] reglock_mem;

always @(posedge clk_i)
    begin
        if(~(rst_ni && ~jtag_unlock && ~rst_9))
            begin
              for (j=0; j < 6; j=j+1) begin
                reglock_mem[j] <= 'b0;
              end
            end
    end
endmodule