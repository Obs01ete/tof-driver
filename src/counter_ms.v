`timescale 1ns / 1ps

module counter_ms
(
    input clk,
    input rst,
    input [17:0] clocks_in_ms,
    output reg [31:0] time_ms,
    output reg pulse_ms
);

    reg [17:0] cnt_ms;
    
    always @(posedge clk)
        if(rst)
            begin
                cnt_ms <= 0;
                time_ms <= 0;
                pulse_ms <= 0;
            end
        else
            if(cnt_ms >= clocks_in_ms)
                begin
                    cnt_ms <= 1;
                    time_ms <= time_ms + 1;
                    pulse_ms <= 1;
                end
            else
                begin
                    cnt_ms <= cnt_ms + 1;
                    pulse_ms <= 0;
                end

endmodule
