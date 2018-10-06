// ****************************************************************************
// Auxilary functions
// ****************************************************************************

// Ceiling of base-2 logarithm
function automatic integer clogb2;
    input [31:0] value;
    reg [31:0] v;
    integer result;
begin
    v = value;
    for (result = 0; v > 0; result = result + 1) begin
        v = v >> 1;
    end
    clogb2 = result;
end
endfunction

// Number of bits to represent at least n values
function automatic integer base2;
    input integer n;
begin
    base2 = clogb2(n-1);
end
endfunction

function automatic integer max;
    input integer v1;
    input integer v2;
begin
    max = (v1 > v2) ? v1 : v2;
end
endfunction

function automatic integer min;
    input integer v1;
    input integer v2;
begin
    min = (v1 < v2) ? v1 : v2;
end
endfunction

function automatic integer pow;
    input integer v;
    input integer gr;
    integer i, acc;
begin
    acc = 1;
    for (i = 0; i < gr; i = i + 1) begin
        acc = acc * v;
    end
    pow = acc;
end
endfunction

function automatic integer pow2;
    input integer gr;
    integer i, acc;
begin
    acc = 1;
    for (i = 0; i < gr; i = i + 1) begin
        acc = acc * 2;
    end
    pow2 = acc;
end
endfunction

