`timescale 1ns / 1ps

module posedge_detection(signal, clk, posedge_signal);
    input signal;
    input clk;
    output posedge_signal;

    reg l1,l2;
    
    always @*
        l1 <= signal;
    
    always @(posedge clk)
        l2 <= l1;
        
    assign posedge_signal = (l1 && !l2);
    
endmodule


module negedge_detection(signal, clk, negedge_signal);
    input signal;
    input clk;
    output negedge_signal;

    reg l1,l2;
    
    always @*
        l1 <= signal;
    
    always @(posedge clk)
        l2 <= l1;
        
    assign negedge_signal = (!l1 && l2);
    
endmodule
