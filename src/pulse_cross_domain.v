module pulse_cross_domain(
    input  in_clk,
    input  in_pulse,
    
    input  out_clk,
    output reg out_pulse = 0
);

    reg ff = 0;
    always @(posedge in_clk)
        if (in_pulse)
            ff <= ~ff;
    
    reg r1 = 0;
    reg r2 = 0;
    reg r3 = 0;
    always @(posedge out_clk) begin
        r1 <= ff;
        r2 <= r1;
        r3 <= r2;
    end
    
    always @(posedge out_clk)
        out_pulse <= r2 ^ r3; // catch both rising an falling edges
    
endmodule
