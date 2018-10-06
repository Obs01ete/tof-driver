module clock_divider_two_phase
#(
    parameter DIVISOR_BITS = 8
)
(
    input clk_in,
    input rst,
    input [DIVISOR_BITS-1:0] divisor,
    input [DIVISOR_BITS-1:0] phase,
    output reg clk_out,
    output reg clk_out_phased
);

    `include "auxilary_functions.v"

    reg  [DIVISOR_BITS-1:0] cnt = 0;
    reg  [DIVISOR_BITS-1:0] cnt_unphased = 0;
    reg  [DIVISOR_BITS-1:0] cnt_phased = 0;
    
    wire [DIVISOR_BITS-1+1:0] cnt_phased_unbounded = {1'b0, cnt} + {1'b0, phase};
    
    always @(posedge clk_in) begin
        if (rst) begin
            cnt <= 0;
            cnt_unphased <= 0;
            cnt_phased <= 0;
            clk_out <= 0;
            clk_out_phased <= 0;
        end
        else begin
            if (cnt >= divisor-1) begin
                cnt <= 0;
            end
            else begin
                cnt <= cnt + 1;
            end
            
            cnt_unphased <= cnt;
            if (cnt_phased_unbounded >= divisor) begin
                cnt_phased <= cnt_phased_unbounded - divisor;
            end
            else begin
                cnt_phased <= cnt_phased_unbounded;
            end
            
            clk_out <= (cnt_unphased >= divisor/2);
            clk_out_phased <= (cnt_phased >= divisor/2);
        end
    end
    
endmodule
