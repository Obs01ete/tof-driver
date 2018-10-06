`timescale 1ns / 1ps

module delay_reg( data_in, we, clk, data_out );
    parameter DELAY = 1;
    parameter WIDTH = 1;
    input [WIDTH-1:0] data_in;
    input clk;
    input we;
    output [WIDTH-1:0] data_out;

    genvar i;
    generate
        for (i=0; i < WIDTH; i=i+1) 
            begin: DELAY_REG
                delay1 #( .DELAY(DELAY) ) delay_reg_unit
                (
                    .data_in(data_in[i]),
                    .we(we),
                    .clk(clk), 
                    .data_out(data_out[i])
                );
            end
    endgenerate
    
endmodule


module delay1( data_in, we, clk, data_out);
    parameter DELAY = 1;

    input data_in;
    input we;
    input clk;
    output data_out;

    reg [DELAY-1:0] shift_reg;

    always @(posedge clk)
        if(we)
            shift_reg <= { data_in, shift_reg[DELAY-1:1]  };

    assign data_out = shift_reg[0];
    
    initial begin
        shift_reg <= 0;
    end
    
endmodule
