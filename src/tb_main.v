`timescale 1 ns/1 ps

module tb();

    `include "register_file_address_space.v"
    
    reg clk_sys = 1;
    reg clk_adc = 1;
    reg rst = 1;

    always #5 clk_sys = ~clk_sys; // 100 MHz
    //always #17 clk_adc = ~clk_adc; // 30 MHz
    always #8 clk_adc = ~clk_adc; // 60 MHz
    
    initial #200 rst = 0;
    
    wire spi_SCK;
    wire spi_MOSI;
    wire spi_MISO;
    wire spi_CSN;
    
    wire di_req;
    reg  [15:0] di = 16'hXXXX;
    reg  wren = 0;
    wire wr_ack;
    wire do_valid;
    wire [15:0] do;
    
    initial begin
        @(negedge rst);
        #1;
        repeat (10) @(posedge clk_sys);
        
        //di = {1'b1, 7'h71, 8'h55};
        //wren = 1;
        @(posedge clk_sys);
        di = 16'hXXXX;
        wren = 0;

        /*
        repeat (2) begin
            repeat (500) @(posedge clk_sys);
            
            di = {RF_READ_BIT, ADDRESS_CFG_REGISTER, 8'h12};
            wren = 1;
            @(posedge clk_sys);
            wren = 0;
        end
        */
        
        /*
        // --------------- ADC -------------------
        repeat (500) @(posedge clk_sys);
        di = {RF_WRITE_BIT, ADDRESS_ADC_ADDR, 8'h01};
        wren = 1;
        @(posedge clk_sys);
        wren = 0;

        repeat (500) @(posedge clk_sys);
        di = {RF_WRITE_BIT, ADDRESS_ADC_VALUE, 8'hAA};
        wren = 1;
        @(posedge clk_sys);
        wren = 0;

        repeat (8) begin
            repeat (500) @(posedge clk_sys);
            
            di = {RF_READ_BIT, ADDRESS_ADC_BUSY, 8'h00};
            wren = 1;
            @(posedge clk_sys);
            wren = 0;
        end

        repeat (500) @(posedge clk_sys);
        di = {RF_WRITE_BIT, ADDRESS_ADC_VALUE_HIGHER_BYTE, 8'hFF};
        wren = 1;
        @(posedge clk_sys);
        wren = 0;

        repeat (500) @(posedge clk_sys);
        di = {RF_WRITE_BIT, ADDRESS_ADC_VALUE, 8'hBB};
        wren = 1;
        @(posedge clk_sys);
        wren = 0;

        repeat (8) begin
            repeat (500) @(posedge clk_sys);
            
            di = {RF_READ_BIT, ADDRESS_ADC_BUSY, 8'h00};
            wren = 1;
            @(posedge clk_sys);
            wren = 0;
        end

        repeat (500) @(posedge clk_sys);
        di = {RF_WRITE_BIT, ADDRESS_ADC_ACQUIRE, 8'h01};
        wren = 1;
        @(posedge clk_sys);
        wren = 0;

        repeat (8) begin
            repeat (500) @(posedge clk_sys);
            
            di = {RF_READ_BIT, ADDRESS_ADC_BUSY, 8'h00};
            wren = 1;
            @(posedge clk_sys);
            wren = 0;
        end

        repeat (2) begin
            repeat (500) @(posedge clk_sys);
            di = {RF_READ_BIT, ADDRESS_ADC_VALUE_HIGHER_BYTE, 8'h00};
            wren = 1;
            @(posedge clk_sys);
            wren = 0;
        end

        repeat (2) begin
            repeat (500) @(posedge clk_sys);
            di = {RF_READ_BIT, ADDRESS_ADC_VALUE, 8'h00};
            wren = 1;
            @(posedge clk_sys);
            wren = 0;
        end
        // --------------- end ADC -------------------
        */

        /*
        // --------------- Sensor -------------------
        repeat (500) @(posedge clk_sys);
        di = {RF_WRITE_BIT, ADDRESS_SNS_ADDR, 8'h01};
        wren = 1;
        @(posedge clk_sys);
        wren = 0;

        repeat (500) @(posedge clk_sys);
        di = {RF_WRITE_BIT, ADDRESS_SNS_VALUE, 8'hAA};
        wren = 1;
        @(posedge clk_sys);
        wren = 0;

        repeat (8) begin
            repeat (500) @(posedge clk_sys);
            
            di = {RF_READ_BIT, ADDRESS_SNS_BUSY, 8'h00};
            wren = 1;
            @(posedge clk_sys);
            wren = 0;
        end

        repeat (8) begin
            repeat (500) @(posedge clk_sys);
            
            di = {RF_READ_BIT, ADDRESS_SNS_BUSY, 8'h00};
            wren = 1;
            @(posedge clk_sys);
            wren = 0;
        end

        repeat (500) @(posedge clk_sys);
        di = {RF_WRITE_BIT, ADDRESS_SNS_ACQUIRE, 8'h01};
        wren = 1;
        @(posedge clk_sys);
        wren = 0;

        repeat (8) begin
            repeat (500) @(posedge clk_sys);
            
            di = {RF_READ_BIT, ADDRESS_SNS_BUSY, 8'h00};
            wren = 1;
            @(posedge clk_sys);
            wren = 0;
        end

        repeat (2) begin
            repeat (500) @(posedge clk_sys);
            di = {RF_READ_BIT, ADDRESS_SNS_VALUE, 8'h00};
            wren = 1;
            @(posedge clk_sys);
            wren = 0;
        end
        // --------------- end Sensor -------------------
        */
        
        //repeat (500) @(posedge clk_sys);
        //di = {RF_WRITE_BIT, ADDRESS_ENABLE_CYCLE_EMULATION, 8'h01};
        //wren = 1;
        //@(posedge clk_sys);
        //wren = 0;
        
        //repeat (2) begin
        //    repeat (500) @(posedge clk_sys);
        //    di = {RF_READ_BIT, ADDRESS_OVERRIDE_ENABLE_ROI, 8'h00};
        //    wren = 1;
        //    @(posedge clk_sys);
        //    wren = 0;
        //end
        
        repeat (500) @(posedge clk_sys);
        di = {RF_WRITE_BIT, ADDRESS_MODLED_PHASE, 8'h01};
        wren = 1;
        @(posedge clk_sys);
        wren = 0;
        
        //repeat (500) @(posedge clk_sys);
        //di = {RF_WRITE_BIT, ADDRESS_MODLED_PHASE_1, 8'h02};
        //wren = 1;
        //@(posedge clk_sys);
        //wren = 0;
        //
        //repeat (500) @(posedge clk_sys);
        //di = {RF_WRITE_BIT, ADDRESS_MODLED_PHASE_2, 8'h03};
        //wren = 1;
        //@(posedge clk_sys);
        //wren = 0;
        //
        //repeat (500) @(posedge clk_sys);
        //di = {RF_WRITE_BIT, ADDRESS_MODLED_PHASE_3, 8'h04};
        //wren = 1;
        //@(posedge clk_sys);
        //wren = 0;
        //
        //repeat (500) @(posedge clk_sys);
        //di = {RF_WRITE_BIT, ADDRESS_MULTICYCLE_MODE, 8'h01};
        //wren = 1;
        //@(posedge clk_sys);
        //wren = 0;
        
        repeat (500) @(posedge clk_sys);
        di = {RF_WRITE_BIT, ADDRESS_START_CYCLE, 8'h01};
        wren = 1;
        @(posedge clk_sys);
        wren = 0;
        
        //#4000000;
        //
        //repeat (500) @(posedge clk_sys);
        //di = {RF_WRITE_BIT, ADDRESS_START_CYCLE, 8'h01};
        //wren = 1;
        //@(posedge clk_sys);
        //wren = 0;
        
    end

    spi_master #(   
        .N(16),                         // 32bit serial word length is default
        .CPOL(1),                       // SPI mode selection (mode 0 default)
        .CPHA(1),                       // CPOL = clock polarity, CPHA = clock phase.
        .PREFETCH(2),                   // prefetch lookahead cycles
        .SPI_2X_CLK_DIV(5)              // for a 100MHz sclk_i, yields a 10MHz SCK
    )
    spi_master (  
        .sclk_i(clk_sys),               // high-speed serial interface system clock
        .pclk_i(clk_sys),               // high-speed parallel interface system clock
        .rst_i(rst),                    // reset core
        
        //// serial interface ////
        .spi_ssel_o(spi_CSN),           // spi bus slave select line
        .spi_sck_o(spi_SCK),            // spi bus sck
        .spi_mosi_o(spi_MOSI),          // spi bus mosi output
        .spi_miso_i(spi_MISO),          // spi bus spi_miso_i input
        
        //// parallel interface ////
        .di_req_o(di_req),              // preload lookahead data request line
        .di_i(di),                      // parallel data in (clocked on rising spi_clk after last bit)
        .wren_i(wren),                  // user data write enable, starts transmission when interface is idle
        .wr_ack_o(wr_ack),              // write acknowledge
        .do_valid_o(do_valid),          // do_o data valid signal, valid during one spi_clk rising edge.
        .do_o(do),                      // parallel output (clocked on rising spi_clk after last bit)
        
        .sck_ena_o(),
        .sck_ena_ce_o(),
        .do_transfer_o(),
        .wren_o(),
        .rx_bit_reg_o(),
        .state_dbg_o(),
        .core_clk_o(),
        .core_n_clk_o(),
        .core_ce_o(),
        .core_n_ce_o(),
        .sh_reg_dbg_o()
    );                      

    wire [15:0] PPID;
    wire PPIFS1;
    wire PPIFS2;
    wire PPIFS3;
    //wire ppi_enable_clock;
    wire ppi_clk;
    
    wire sns_start_roi;
    reg  sns_enable_roi = 1'b0;
    wire sns_clk_roi;
    wire sns_hold;
    wire sns_reset_ccd;
    wire sns_sel_sr;
    wire sns_modsel;
    wire sns_modled;
    
    wire sns_ce_a;
    wire sns_ce_d;
    wire sns_sclk;
    reg  sns_sdi = 1;
    wire sns_sdo;
    
    wire adc_sdata_i;
    reg  adc_sdata_o = 1;
    wire adc_sdata_oen;
    wire adc_sclk;
    wire adc_sload;
    
    reg  [7:0] adc_data;
    always @(posedge clk_adc) adc_data <= $random;
    wire adc_sclk2;
    wire adc_sclk1;
    wire adc_cclk;
    
    main main
    (
        .clk_sys(clk_sys),
        .clk_adc(clk_adc),
        .rst(rst),
        
        // Blackfin SPI interface
        .cpu_spi_SCK (spi_SCK),
        .cpu_spi_MOSI(spi_MOSI),
        .cpu_spi_MISO(spi_MISO),
        .cpu_spi_CSN (spi_CSN),

        .sns_start_roi_o (sns_start_roi),
        .sns_enable_roi_i(sns_enable_roi),
        .sns_clk_roi_o   (sns_clk_roi),
        .sns_hold_o      (sns_hold),
        .sns_reset_1_o   (sns_reset_ccd), // reset_1
        .sns_sel_sr_o    (sns_sel_sr),
        .sns_modsel_o    (sns_modsel),
        .sns_modled_o    (sns_modled),

        .sns_cfg_ce_a_o(sns_ce_a),
        .sns_cfg_ce_d_o(sns_ce_d),
        .sns_cfg_sclk_o(sns_sclk),
        .sns_cfg_sdi_i (sns_sdi ),
        .sns_cfg_sdo_o (sns_sdo ),
        
        // ADC
        .adc_cfg_sdata_o    (adc_sdata_i),
        .adc_cfg_sdata_i    (adc_sdata_o),
        .adc_cfg_sdata_oen_o(adc_sdata_oen),
        .adc_cfg_sclk_o     (adc_sclk),
        .adc_cfg_sload_o    (adc_sload),

        .adc_data (adc_data),
        .adc_sclk2(adc_sclk2),
        .adc_sclk1(adc_sclk1),
        .adc_cclk (adc_cclk),
    
        // PPI
        .ppi_data(PPID),
        .ppi_fs1 (PPIFS1),
        .ppi_fs2 (PPIFS2),
        .ppi_fs3 (PPIFS3),
        .ppi_clk (ppi_clk),
        
        .adc_ctrl(),
        .start(),
        .cfg_register()
    );
    
    //initial sns_enable_roi = #100 1'b1;
    
    always begin
        @(posedge sns_start_roi);
        #10000;
        sns_enable_roi = 1;
        //#(2692800+400*100);
        #(2692800/2-400*1000);
        sns_enable_roi = 0;
        #1;
    end


endmodule
