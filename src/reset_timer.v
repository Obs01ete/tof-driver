module reset_timer(
    input  clk,
    input  rst_in,
    output reg rst_out = 1'b1
);
    
    `include "auxilary_functions.v"

    parameter use_rst_in = 0;
    parameter ticks = 100000;
    
    reg [clogb2(ticks)-1:0] cnt = 0;
    reg rst_n = 1'b0;

    generate
        if (use_rst_in) begin
            always @(posedge clk or posedge rst_in) begin
                if (rst_in) begin
                    cnt <= 0;
                    rst_n <= 1'b0;
                end
                else begin
                    if (!(&cnt)) begin
                        cnt <= cnt + 1;
                        rst_n <= 1'b0;
                    end
                    else begin
                        rst_n <= 1'b1;
                    end
                end
            end
        end
        else begin
            always @(posedge clk) begin
                if (!(&cnt)) begin
                    cnt <= cnt + 1;
                    rst_n <= 1'b0;
                end
                else begin
                    rst_n <= 1'b1;
                end
            end
        end
    endgenerate

    always @(posedge clk)
        rst_out <= !rst_n;

endmodule
