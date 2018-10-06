module clock_divider
(
    input clk_in,
    input rst,
    output reg clk_out
);

    `include "auxilary_functions.v"

    parameter divisor = 10;
    
    reg  [base2(divisor)-1:0] cnt = 0;
    
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
