module pulse_widener
#(
    parameter PERIOD = 100
)
(
    input  clk_i,
    input  rst,
    input  pulse_i,
    output reg out_o = 0
);

    `include "auxilary_functions.v"
    
    reg  [base2(PERIOD)-1:0] cnt = 0;

    wire test = (pulse_i === 1);
    
    always @(posedge clk_i) begin
        if (rst) begin
            cnt <= 0;
            out_o <= 0;
        end
        else begin
            if (test) begin
                cnt <= PERIOD-1;
            end
            else begin
                if (cnt > 0) begin
                    cnt <= cnt - 1;
                end
            end
        
            out_o <= (cnt > 0);
        end
    end

endmodule
