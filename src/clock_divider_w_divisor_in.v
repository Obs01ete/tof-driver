module clock_divider_w_divisor_in
#(
    parameter DIVISOR_BITS = 8
)
(
    input clk_in,
    input rst,
    input [DIVISOR_BITS-1:0] divisor,
    output reg clk_out
);

    `include "auxilary_functions.v"

    reg  [DIVISOR_BITS-1:0] cnt = 0;
    
    always @(posedge clk_in) begin
        if (rst) begin
            cnt <= 0;
            clk_out <= 0;
        end
        else begin
            if (cnt >= divisor-1) begin
                cnt <= 0;
            end
            else begin
                cnt <= cnt + 1;
            end
            
            clk_out <= (cnt >= divisor/2);
        end
    end
    
endmodule
