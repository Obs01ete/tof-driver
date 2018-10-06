module main
(
    input  clk_sys,
    input  clk_adc,
    input  rst,
    
    // SPI interface
    input  cpu_spi_SCK,
    input  cpu_spi_MOSI,
    output cpu_spi_MISO,
    input  cpu_spi_CSN,

    // Sensor
    output sns_start_roi_o,
    input  sns_enable_roi_i,
    output sns_clk_roi_o,
    output sns_hold_o,
    output sns_reset_1_o,
    output sns_sel_sr_o,
    output sns_modsel_o,
    output sns_modled_o,
    
    output sns_cfg_ce_a_o,
    output sns_cfg_ce_d_o,
    output sns_cfg_sclk_o,
    input  sns_cfg_sdi_i,
    output sns_cfg_sdo_o,

    // ADC
    output adc_cfg_sdata_o,
    input  adc_cfg_sdata_i,
    output adc_cfg_sdata_oen_o,
    output adc_cfg_sclk_o,
    output adc_cfg_sload_o,
    
    input  [7:0] adc_data,
    output adc_sclk2,
    output adc_sclk1,
    output adc_cclk,
    
    // PPI
    output reg [15:0] ppi_data,
    output reg ppi_fs1,
    output reg ppi_fs2,
    output reg ppi_fs3,
    output ppi_clk,
    
    // Debug
    output adc_ctrl,
    output start,
    output [7:0] cfg_register
);

`define SPI
`ifdef SPI
    wire cpu_di_req;
    wire [15:0] cpu_di;
    wire cpu_wren;
    wire cpu_wr_ack;
    wire cpu_do_valid;
    wire [15:0] cpu_do;
    
    spi_slave #(   
        .N(16),                     // 32bit serial word length is default
        .CPOL(1),                   // SPI mode selection (mode 0 default)
        .CPHA(1),                   // CPOL = clock polarity, CPHA = clock phase.
        .PREFETCH(2)                // prefetch lookahead cycles
    )
    spi_slave(  
        .clk_i(clk_sys),            // internal interface clock (clocks di/do registers)
        .spi_ssel_i(cpu_spi_CSN),   // spi bus slave select line
        .spi_sck_i(cpu_spi_SCK),    // spi bus sck clock (clocks the shift register core)
        .spi_mosi_i(cpu_spi_MOSI),  // spi bus mosi input
        .spi_miso_o(cpu_spi_MISO),  // spi bus spi_miso_o output
        .di_req_o(cpu_di_req),      // preload lookahead data request line
        .di_i(cpu_di),              // parallel load data in (clocked in on rising edge of clk_i)
        .wren_i(cpu_wren),          // user data write enable
        .wr_ack_o(cpu_wr_ack),      // write acknowledge
        .do_valid_o(cpu_do_valid),  // do_o data valid strobe, valid during one clk_i rising edge.
        .do_o(cpu_do),              // parallel output (clocked out on falling clk_i)
        
        .do_transfer_o(),
        .wren_o(),
        .rx_bit_next_o(),
        .state_dbg_o(),
        .sh_reg_dbg_o()
    );
    assign start = cpu_do_valid;

`else
    counter_ms counter_ms
    (
        .clk(clk_sys),
        .rst(rst),
        .clocks_in_ms(18'd100_000_000),
        .time_ms(),
        .pulse_ms(start)
    );
`endif
    

    wire [2:0] adc_p_address;
    wire [8:0] adc_p_write_data;
    wire       adc_p_write_valid;
    wire       adc_p_read_start;
    wire [8:0] adc_p_read_data;
    wire       adc_p_busy;
    
    wire [6:0] sns_p_address;
    wire [7:0] sns_p_write_data;
    wire       sns_p_write_valid;
    wire       sns_p_read_start;
    wire [7:0] sns_p_read_data;
    wire       sns_p_busy;
    wire       sns_p_mux_ce_a_nd;
    
    wire [7:0] modsel_divisor;
    wire [7:0] modsel_phase;
    wire start_multicycle;
    wire [23:0] integration_time;
    wire multicycle_finished;
    wire override_sns_enable_roi;
    wire switch_to_cycle_emulation;
    wire is_multicycle;
    wire [7:0] modsel_phase_1;
    wire [7:0] modsel_phase_2;
    wire [7:0] modsel_phase_3;

    wire [3:0] deb_state;
    wire [23:0] deb_fsm_cnt;
    wire deb_fsm_cnt_en;

    register_file register_file
    (
        .clk_i(clk_sys),
        .rst_i(rst),
        
        .cpu_din_i(cpu_do),
        .cpu_din_we_i(cpu_do_valid),
        
        .cpu_dout_o(cpu_di),
        .cpu_dout_valid_o(cpu_wren),
        .cpu_dout_ack_i(cpu_wr_ack),
        
        .adc_p_address_o    (adc_p_address    ),
        .adc_p_write_data_o (adc_p_write_data ),
        .adc_p_write_valid_o(adc_p_write_valid),
        .adc_p_read_start_o (adc_p_read_start ),
        .adc_p_read_data_i  (adc_p_read_data  ),
        .adc_p_busy_i       (adc_p_busy       ),
        
        .sns_p_address_o    (sns_p_address    ),
        .sns_p_write_data_o (sns_p_write_data ),
        .sns_p_write_valid_o(sns_p_write_valid),
        .sns_p_read_start_o (sns_p_read_start ),
        .sns_p_read_data_i  (sns_p_read_data  ),
        .sns_p_busy_i       (sns_p_busy       ),
        .sns_p_mux_ce_a_nd_o(sns_p_mux_ce_a_nd),
        
        .cfg_register_o             (cfg_register             ),
        .start_cycle_o              (start_multicycle         ),
        .modsel_divisor_o           (modsel_divisor           ),
        .modsel_phase_o             (modsel_phase             ),
        .integration_time_o         (integration_time         ),
        .cycle_finished_i           (multicycle_finished      ),
        .override_sns_enable_roi_o  (override_sns_enable_roi  ),
        .switch_to_cycle_emulation_o(switch_to_cycle_emulation),
        .adc_ctrl_o                 (adc_ctrl),
        .is_multicycle_o            (is_multicycle),
        .modsel_phase_1_o           (modsel_phase_1),
        .modsel_phase_2_o           (modsel_phase_2),
        .modsel_phase_3_o           (modsel_phase_3),
        
        .debug_0_i({4'b0, deb_state}),
        .debug_1_i(deb_fsm_cnt[0+:8]),
        .debug_2_i(deb_fsm_cnt[8+:8]),
        .debug_3_i(deb_fsm_cnt[16+:8]),
        .debug_4_i({7'b0, deb_fsm_cnt_en}),
        .debug_5_i(8'b0),
        .debug_6_i(8'b0),
        .debug_7_i(8'b0)
    );
    

    ad9826_serial_controller ad9826_serial_controller
    (
        .clk(clk_sys),
        .rst(rst),
        
        .sdata_o    (adc_cfg_sdata_o    ),
        .sdata_i    (adc_cfg_sdata_i    ),
        .sdata_oen_o(adc_cfg_sdata_oen_o),
        .sclk_o     (adc_cfg_sclk_o     ),
        .sload_o    (adc_cfg_sload_o    ),
        
        .address_i    (adc_p_address    ),
        .write_data_i (adc_p_write_data ),
        .write_valid_i(adc_p_write_valid),
        .read_start_i (adc_p_read_start ),
        .read_data_o  (adc_p_read_data  ),
        .busy_o       (adc_p_busy       )
    );


    sensor_serial_controller sensor_serial_controller
    (
        .clk(clk_sys),
        .rst(rst),
        
        .ce_a_o(sns_cfg_ce_a_o),
        .ce_d_o(sns_cfg_ce_d_o),
        .sclk_o(sns_cfg_sclk_o),
        .sdi_i (sns_cfg_sdi_i ),
        .sdo_o (sns_cfg_sdo_o ),
        
        .address_i    (sns_p_address    ),
        .write_data_i (sns_p_write_data ),
        .write_valid_i(sns_p_write_valid),
        .read_start_i (sns_p_read_start ),
        .read_data_o  (sns_p_read_data  ),
        .busy_o       (sns_p_busy       ),
        .mux_ce_a_nd_i(sns_p_mux_ce_a_nd)
    );

    
    wire sns_modsel_en;
    wire [7:0] modsel_phase_multicycle;
    clock_divider_two_phase #(
        .DIVISOR_BITS(8)
    )
    modsel_clk_gen (
        .clk_in(clk_sys),
        .rst(rst || (!sns_modsel_en)),
        .divisor(modsel_divisor),
        .phase(modsel_phase_multicycle),
        .clk_out(sns_modsel_o),
        .clk_out_phased(sns_modled_o)
    );

    wire start_multicycle_pulse;
    posedge_detection front_of_start(
        .signal(start_multicycle),
        .clk(clk_sys),
        .posedge_signal(start_multicycle_pulse)
    );
    
    wire start_cycle;
    wire cycle_finished_sys;
    wire ppi_frame_valid_sys;
    multicycle_generator multicycle_generator(
        .clk_i(clk_sys),
        .rst_i(rst),
        
        .is_multicycle_i(is_multicycle),
        .start_multicycle_i(start_multicycle_pulse),
        .start_sycle_o(start_cycle),
        .ppi_frame_valid_i(ppi_frame_valid_sys), // required to the chain: start -> something in between -> finished
        .cycle_finished_i(cycle_finished_sys),
        .multicycle_finished_o(multicycle_finished),

        .modsel_phase_i(modsel_phase),
        .modsel_phase_1_i(modsel_phase_1),
        .modsel_phase_2_i(modsel_phase_2),
        .modsel_phase_3_i(modsel_phase_3),
        .modsel_phase_o(modsel_phase_multicycle)
    );
    
    
    wire start_ppi;
    pulse_cross_domain pulse_cross_domain(
        .in_clk(clk_sys),
        .in_pulse(start_cycle),
        .out_clk(ppi_clk),
        .out_pulse(start_ppi)
    );
    
    wire enable_roi_emulation;
    pulse_widener #(
        .PERIOD(100)
    )
    pw (
        .clk_i(ppi_clk),
        .rst(rst),
        .pulse_i(start_ppi),
        .out_o(enable_roi_emulation)
    );

    localparam integer clk_adc_freq_mhz = 30;
    localparam [11:0] t_pxlrst = clk_adc_freq_mhz * 2.0;
    localparam [11:0]  t_rsthold = clk_adc_freq_mhz * 1.0;
    localparam [11:0]  t_intprep = clk_adc_freq_mhz * 1.0;
    localparam [11:0]  t_intprep2 = clk_adc_freq_mhz * 1.0;
    localparam [11:0]  t_inthold = clk_adc_freq_mhz * 1.0;
    localparam [11:0]  t_inthold2 = clk_adc_freq_mhz * 1.0;
    localparam [11:0]  t_rdoprep = clk_adc_freq_mhz * 1.0;
    localparam [11:0]  t_rdohold = clk_adc_freq_mhz * 10.0;
    //localparam integer t_int_numclocks_i = clk_adc_freq_mhz * 20.0; // 50 us integration time
    
    wire start_sensor = switch_to_cycle_emulation ? 1'b0 :
        override_sns_enable_roi ? 1'b0 : start_ppi;
    wire ready_sensor;
    wire ppi_frame_valid;

    sensor_intf sensor_intf
    (
        .clk_i(clk_adc),
        .rst_i(rst),
        
        .start_i(start_sensor),
        .autostart_i(1'b0),
        .ready_o(ready_sensor),
        
        .t_pxlrst_i  (t_pxlrst),
        .t_rsthold_i (t_rsthold),
        .t_intprep_i (t_intprep),
        .t_intprep2_i(t_intprep2),
        .t_inthold_i (t_inthold),
        .t_inthold2_i(t_inthold2),
        .t_rdoprep_i (t_rdoprep),
        .t_rdohold_i (t_rdohold),
        .t_roiclk_i  (12'd6),
        .t_int_numclocks_i(integration_time), // t_int_numclocks_i
        
        .sns_reset_1_o   (sns_reset_1_o),
        .sns_hold_o      (sns_hold_o),
        .sns_modsel_en_o (sns_modsel_en),
        .sns_start_roi_o (sns_start_roi_o),
        .sns_enable_roi_i(sns_enable_roi_i),
        .sns_clk_roi_o   (sns_clk_roi_o),
        .sns_sel_sr_o    (sns_sel_sr_o),
        
        // required to check that both sns_enable_roi_i and real_ppi_fs2 finished to start new cycle
        .ppi_frame_valid_i(ppi_frame_valid),

        .deb_state_o(deb_state),
        .deb_fsm_cnt_o(deb_fsm_cnt),
        .deb_fsm_cnt_en_o(deb_fsm_cnt_en)
    );

    wire [15:0] real_ppi_data;
    wire        real_ppi_fs1 ;
    wire        real_ppi_fs2 ;
    wire        real_ppi_fs3 ;
    wire sns_enable_roi = override_sns_enable_roi ? enable_roi_emulation : sns_enable_roi_i;
    ad9826_data_controller ad9826_data_controller
    (
        .clk_adc_i(clk_adc),
        .rst_i(rst),
        
        .sns_enable_roi_i(sns_enable_roi),
        .sns_clk_roi_i(sns_clk_roi_o), // correct
        
        .adc_data_i(adc_data),
        .adc_sclk2_o(adc_sclk2),
        .adc_sclk1_o(adc_sclk1),
        .adc_cclk_o(adc_cclk),
        
        .ppi_data_o(real_ppi_data),
        .ppi_fs1_o (real_ppi_fs1 ),
        .ppi_fs2_o (real_ppi_fs2 ),
        .ppi_fs3_o (real_ppi_fs3 ),
        .ppi_clk_o (ppi_clk )
    );
    
    wire [15:0] generator_ppi_data;
    wire generator_ppi_fs1;
    wire generator_ppi_fs2;
    wire generator_ppi_fs3;
    
    wire start_generator = switch_to_cycle_emulation ? start_ppi : 1'b0;
    wire ready_generator;
    ppi_generator ppi_generator
    (
        .clk_ppi(ppi_clk),
        .rst(rst),
        
        .start(start_generator),
        .ready(ready_generator),
        
        .ppi_data(generator_ppi_data),
        .ppi_fs1 (generator_ppi_fs1),
        .ppi_fs2 (generator_ppi_fs2),
        .ppi_fs3 (generator_ppi_fs3)
    );
    

    always @(*) begin
        if (switch_to_cycle_emulation) begin
            ppi_data <= generator_ppi_data;
            ppi_fs1  <= generator_ppi_fs1;
            ppi_fs2  <= generator_ppi_fs2;
            ppi_fs3  <= generator_ppi_fs3;
        end
        else begin
            ppi_data <= real_ppi_data;
            ppi_fs1  <= real_ppi_fs1;
            ppi_fs2  <= real_ppi_fs2;
            ppi_fs3  <= real_ppi_fs3;
        end
    end

    assign ppi_frame_valid = ppi_fs2;
    
    wire cycle_finished = switch_to_cycle_emulation ? ready_generator : ready_sensor;
    
    cross_domain finished_ppi_to_sys(
        .clk_dst(clk_sys),
        .in(cycle_finished),
        .out(cycle_finished_sys)
    );
    
    cross_domain frame_valid_ppi_to_sys(
        .clk_dst(clk_sys),
        .in(ppi_frame_valid),
        .out(ppi_frame_valid_sys)
    );
    
endmodule
