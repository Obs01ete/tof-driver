module cross_domain(
    input clk_dst,
    input in,
    output reg out
    );
    
    reg int1 = 0, int2 = 0;
    always @(posedge clk_dst) begin
        int1 <= in;
        int2 <= int1;
        out <= int2;
    end
    
endmodule
