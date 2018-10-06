// SPI slave
// CPOL = 0, CPHA = 0, most significant bit first

module spi_slave
(
    // System
    input  clk,
    input  rst,
    
    // SPI interface
    input  spi_SCK,
    input  spi_MOSI,
    input  spi_CSN,
    
    output reg parallel_start_of_message,
    output reg parallel_end_of_message,
    output reg [7:0] parallel_data,
    output reg parallel_data_valid,
    
    output reg corrupt_byte
);

wire CSN;
wire MOSI;
wire SCK;

delay_reg #(.DELAY(3), .WIDTH(3)) d1
(
    .data_in({spi_CSN, spi_MOSI, spi_SCK}),
    .we(1'b1),
    .clk(clk),
    .data_out({CSN, MOSI, SCK})
);

wire CSN_pe;
posedge_detection CSN_pe_i(.signal(CSN), .clk(clk), .posedge_signal(CSN_pe));
wire CSN_ne;
negedge_detection CSN_ne_i(.signal(CSN), .clk(clk), .negedge_signal(CSN_ne));
wire SCK_pe;
posedge_detection SCK_pe_i(.signal(SCK), .clk(clk), .posedge_signal(SCK_pe));

reg  [7:0] byte;
reg  [2:0] bit;

always @(posedge clk) begin
    if (rst) begin
        parallel_data <= 8'b0;
        parallel_start_of_message <= 1'b0;
        parallel_end_of_message <= 1'b0;
        byte <= 8'b0;
        parallel_data_valid <= 1'b0;
        corrupt_byte <= 1'b0;
        bit <= 0;
    end
    else begin
        parallel_start_of_message <= 1'b0;
        parallel_end_of_message <= 1'b0;
        parallel_data_valid <= 1'b0;
        
        if (CSN_ne) begin
            parallel_start_of_message <= 1'b1;
            bit <= 0;
            corrupt_byte <= 1'b0;
            byte <= 8'b0;
        end
        else if (CSN_pe) begin
            parallel_end_of_message <= 1'b1;
            if (bit != 0) begin
                corrupt_byte <= 1'b1;
            end
            byte <= 8'b0;
            parallel_data <= 8'b0;
        end
        else begin
            if (!CSN) begin
                if (SCK_pe) begin
                    byte[7-bit] <= MOSI;
                    bit <= bit + 1; // no need to process overflow
                    if (bit == 3'd7) begin
                        parallel_data <= {byte[7:1], MOSI};
                        parallel_data_valid <= 1'b1;
                    end
                end
            end
        end
    end
end

endmodule
