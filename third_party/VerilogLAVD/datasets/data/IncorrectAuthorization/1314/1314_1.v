module test (
    input             clk, rst_n,
    input             we_select, wr_en,
    input       [7:0] data_in,
    input       [7:0] sensor_raw, 
    output wire [9:0] temp_celsius,
    output      reg   critical_alarm 
);

    reg  [7:0] offset_coeff = 8'b0;
    reg  [7:0] gain_coeff   = 8'b1;

    assign temp_celsius = offset_coeff + gain_coeff * sensor_raw;

    always @(*) critical_alarm = (temp_celsius >= 10'd100);

    always @(posedge clk or negedge rst_n)
        if (!rst_n) {offset_coeff, gain_coeff} <= {8'b0,8'b1};
        else if ((wr_en == 1) & we_select) offset_coeff <= data_in;
        else if ((wr_en == 1) & ~we_select) gain_coeff  <= data_in;

endmodule