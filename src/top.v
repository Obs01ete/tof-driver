module top
(
    // misc
    input  RESET,
    output MOD_LED,

    // 156.--- mhz clock
    input  CLK_S3AN_N,
    input  CLK_S3AN_P,

    // SPI to Blackfin
    input  SPI_SEL_S3AN,
    input  SPISCK_S3AN,
    output SPIMISOS_3AN,
    input  SPIMOSIS3AN,

    // CCD
    // ROI readout
    output START_ROI,
    input  ENABLE_ROI,
    output CLK_ROI,
    // some other readout
    output CLK_C,
    output START_C,
    output CLEAR_R,
    output CLK_R,
    output START_R,
    input  END_R,
    output CLEAR_C,
    input  END_C,
    // control
    output SEL_SR,
    output HOLD,
    output RESET_CCD, // reset_1
    output G_RESET, // global_reset
    output ADC_CTRL,
    output MODSEL,
    
    output CCD_CE_A,
    output CCD_CE_D,
    output CCD_SCLK,
    output CCD_SDI,
    input  CCD_SDO,

    // ADC
    input  [7:0] ADC2_D,
    output ADC2_SCLK2,
    output ADC2_SCLK1,
    output ADC2_CCLK2,
    output SLOAD_ADC2,
    output SCLK_ADC,
    inout  SDATA_ADC,
    
    // PPI
    output PPICLK,
    output PPIFS1,
    output PPIFS2,
    output PPIFS3,
    output [15:0] PPID,

    // Test points
    output reg [25:13] TP
);

    wire clk_sys;
    // pll 104.--- mhz
    sys_clk_gen sys_clk_gen (
        .CLKIN_N_IN(CLK_S3AN_N), 
        .CLKIN_P_IN(CLK_S3AN_P), 
        .RST_IN(1'b0), 
        .CLKFX_OUT(clk_sys), 
        .CLKIN_IBUFGDS_OUT(), 
        .CLK0_OUT(), 
        .LOCKED_OUT(clk_sys_locked)
    );

    
    /*wire clk_ppi;
    // pll to 10.4 mhz
    ppi_clk_gen ppi_clk_gen (
        .CLKIN_IN(clk_sys), 
        .RST_IN(1'b0), 
        .CLKFX_OUT(clk_ppi), 
        .CLK0_OUT(), 
        .LOCKED_OUT(clk_ppi_locked)
    );*/


    wire clk_adc;
    // pll to 31.2 mhz
    adc_clk_gen adc_clk_gen (
        .CLKIN_IN(clk_sys), 
        .RST_IN(1'b0), 
        .CLKFX_OUT(clk_adc), 
        .CLK0_OUT(), 
        .LOCKED_OUT(clk_adc_locked)
    );


    wire rst_by_timer;
    reset_timer #(
        .use_rst_in(0),
        .ticks(100000)
    )
    reset_timer (
        .clk(clk_sys),
        .rst_in(0),
        .rst_out(rst_by_timer)
    );
    wire rst = (!clk_sys_locked) || (!clk_adc_locked) || rst_by_timer;
    
    wire start;
    wire [7:0] cfg_register;
    
    wire adc_sdata_o;
    wire adc_sdata_oen_o;
    assign SDATA_ADC = adc_sdata_oen_o ? adc_sdata_o : 1'bz;
    
    wire spi_masking;
    reset_timer #(
        .use_rst_in(0),
        .ticks(100000000*5)
    )
    spi_masking_timer (
        .clk(clk_sys),
        .rst_in(0),
        .rst_out(spi_masking)
    );
    wire spi_SCK;
    wire spi_MOSI;
    wire spi_MISO;
    wire spi_CSN;
    assign spi_SCK = spi_masking ? 1'b0 : SPISCK_S3AN;
    assign spi_MOSI = spi_masking ? 1'b0 : SPIMOSIS3AN;
    assign SPIMISOS_3AN = spi_masking ? 1'bz : (spi_CSN == 1'b1) ? 1'bz : spi_MISO;
    assign spi_CSN = spi_masking ? 1'b1 : SPI_SEL_S3AN;
    
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
        
        .sns_start_roi_o (START_ROI),
        .sns_enable_roi_i(ENABLE_ROI),
        .sns_clk_roi_o   (CLK_ROI),
        .sns_hold_o      (HOLD),
        .sns_reset_1_o   (RESET_CCD), // reset_1
        .sns_sel_sr_o    (SEL_SR),
        .sns_modsel_o    (MODSEL),
        .sns_modled_o    (MOD_LED),
        
        .sns_cfg_ce_a_o(CCD_CE_A),
        .sns_cfg_ce_d_o(CCD_CE_D),
        .sns_cfg_sclk_o(CCD_SCLK),
        .sns_cfg_sdi_i (CCD_SDO ), // connect vice versa
        .sns_cfg_sdo_o (CCD_SDI ),
        
        // ADC
        .adc_cfg_sdata_o    (adc_sdata_o),
        .adc_cfg_sdata_i    (SDATA_ADC),
        .adc_cfg_sdata_oen_o(adc_sdata_oen_o),
        .adc_cfg_sclk_o     (SCLK_ADC),
        .adc_cfg_sload_o    (SLOAD_ADC2),
        
        .adc_data (ADC2_D    ),
        .adc_sclk2(ADC2_SCLK2),
        .adc_sclk1(ADC2_SCLK1),
        .adc_cclk (ADC2_CCLK2),

        // PPI
        .ppi_data(PPID),
        .ppi_fs1(PPIFS1),
        .ppi_fs2(PPIFS2),
        .ppi_fs3(PPIFS3),
        .ppi_clk(PPICLK),
        
        .adc_ctrl(ADC_CTRL),
        .start(start),
        .cfg_register(cfg_register)
    );


    assign G_RESET = 1'b0; // global_reset
    //assign ADC_CTRL = 1'b0;
    
    assign CLK_C = 1'b0;
    assign START_C = 1'b0;
    assign CLEAR_R = 1'b0;
    assign CLK_R = 1'b0;
    assign START_R = 1'b0;
    assign CLEAR_C = 1'b0;

/*
//`define PERMANENT_PPI_CLK
`define PP_CLK_DISABLED_OUT_VALUE_1

`ifdef PERMANENT_PPI_CLK
    assign PPICLK = clk_ppi;
`else
`ifdef PP_CLK_DISABLED_OUT_VALUE_1
    BUFGCE_1
`else
    BUFGCE
`endif
    clk_ppi_en
    (
        .I(clk_ppi),
        .O(PPICLK),
        .CE(ppi_enable_clock)
    );
`endif
*/

    always @(*) begin
        TP <= 'bz;
        
        TP[13] <= cfg_register[3] ? cfg_register[2] : 1'bz; // P9
        TP[14] <= cfg_register[1] ? cfg_register[0] : 1'bz; // J1
        
        TP[15] <= start;
        TP[16] <= 0; //start_ppi;
        TP[17] <= clk_sys_locked;
        TP[18] <= rst_by_timer;
        TP[19] <= rst;
        TP[20] <= adc_sdata_o;
        TP[21] <= adc_sdata_oen_o;
        TP[22] <= 0;
    end
     
    
endmodule
