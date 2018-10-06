module ad9826_serial_controller
(
    input  clk,
    input  rst,
    
    output sdata_o,
    input  sdata_i,
    output reg sdata_oen_o,
    output sclk_o,
    output sload_o,
    
    input  [2:0]     address_i,
    input  [8:0]     write_data_i, // 9-bit
    input            write_valid_i,
    input            read_start_i,
    output reg [8:0] read_data_o, // 9-bit
    output reg       busy_o
);

    reg  rd_nwr = 0;
    
    wire di_req;
    reg  [15:0] di;
    reg  wren;
    wire wr_ack;
    wire do_valid;
    wire [15:0] do;
    
    localparam [0:0] write_bit = 1'b0;
    localparam [0:0] read_bit = 1'b1;
    
    always @(posedge clk) begin
        if (rst) begin
            wren <= 0;
            busy_o <= 0;
            read_data_o <= 'b0;
            rd_nwr <= 0;
            di <= 'b0;
        end
        else begin
            wren <= 0;
            
            if (busy_o) begin
                if (do_valid) begin
                    busy_o <= 0;
                    
                    if (rd_nwr) begin
                        read_data_o <= do[8:0];
                    end
                end
            end
            else begin
                if (write_valid_i) begin
                    rd_nwr <= 0;
                    di <= {write_bit, address_i, 3'b0, write_data_i};
                    wren <= 1;
                    busy_o <= 1;
                end
                else if (read_start_i) begin
                    rd_nwr <= 1;
                    di <= {read_bit, address_i, 3'b0, 9'b0};
                    wren <= 1;
                    busy_o <= 1;
                end
            end
        end
    end

    wire [7:0] state_dbg;
    
    spi_master #(   
        .N(16),                         // 32bit serial word length is default
        .CPOL(0),                       // SPI mode selection (mode 0 default)
        .CPHA(0),                       // CPOL = clock polarity, CPHA = clock phase.
        .PREFETCH(2),                   // prefetch lookahead cycles
        .SPI_2X_CLK_DIV(/*10*/50)             // for a 100MHz sclk_i, yields a 5MHz SCK
    )
    spi_master (  
        .sclk_i(clk),               // high-speed serial interface system clock
        .pclk_i(clk),               // high-speed parallel interface system clock
        .rst_i(rst),                    // reset core
        
        //// serial interface ////
        .spi_ssel_o(sload_o),           // spi bus slave select line
        .spi_sck_o (sclk_o),           // spi bus sck
        .spi_mosi_o(sdata_o),          // spi bus mosi output
        .spi_miso_i(sdata_i),          // spi bus spi_miso_i input
        
        //// parallel interface ////
        .di_req_o  (di_req),              // preload lookahead data request line
        .di_i      (di),                      // parallel data in (clocked on rising spi_clk after last bit)
        .wren_i    (wren),                  // user data write enable, starts transmission when interface is idle
        .wr_ack_o  (wr_ack),              // write acknowledge
        .do_valid_o(do_valid),          // do_o data valid signal, valid during one spi_clk rising edge.
        .do_o      (do),                      // parallel output (clocked on rising spi_clk after last bit)
        
        .sck_ena_o(),
        .sck_ena_ce_o(),
        .do_transfer_o(),
        .wren_o(),
        .rx_bit_reg_o(),
        .state_dbg_o(state_dbg),
        .core_clk_o(),
        .core_n_clk_o(),
        .core_ce_o(),
        .core_n_ce_o(),
        .sh_reg_dbg_o()
    );
    
    always @(posedge clk)
        sdata_oen_o <= rd_nwr ? ((state_dbg > 8'h0B) || (state_dbg == 8'h00)) : 1'b1;

endmodule
