`timescale 1ns / 1ps

module sensor_intf(
    clk_i,
    rst_i,

    start_i,
    autostart_i,
    ready_o,
    
    t_pxlrst_i,
    t_rsthold_i,
    t_intprep_i,
    t_intprep2_i,
    t_inthold_i, 
    t_inthold2_i,
    t_rdoprep_i,
    t_rdohold_i,
    t_roiclk_i,
    t_int_numclocks_i,
    
    sns_reset_1_o,
    sns_hold_o,
    sns_modsel_en_o,
    
    sns_start_roi_o,
    sns_enable_roi_i,
    sns_clk_roi_o,
    sns_sel_sr_o,
    
    ppi_frame_valid_i,
    
    deb_state_o,
    deb_fsm_cnt_o,
    deb_fsm_cnt_en_o
);

// Bit with of timing parameters
localparam integer TIMING_PARAMS_WIDTH = 12;

// Master clock
input                                  clk_i;
// Master reset
input                                  rst_i;

// Start integration-readout cycle. Makes sense only when circuit is ready.
input                                  start_i;
// Autostart signal.
input                                  autostart_i;
// Ready to start signal.
output                                 ready_o;

// Pixel reset duration (with reset_1 = 1 and hold = 0)
input      [TIMING_PARAMS_WIDTH-1:0]   t_pxlrst_i; // t23 = 2us
// Hold duration after reset (with reset_1 = 1 and hold = 1)
input      [TIMING_PARAMS_WIDTH-1:0]   t_rsthold_i; // t25 = 1us
// Prepare duration before integration (with reset_1 = 0 and hold = 1)
input      [TIMING_PARAMS_WIDTH-1:0]   t_intprep_i; // t26 = 1us
// Prepare duration before integration (with reset_1 = 0 and hold = 0)
input      [TIMING_PARAMS_WIDTH-1:0]   t_intprep2_i; // t28 = 1us
// Hold duration after integration (with reset_1 = 0 and hold = 0)
input      [TIMING_PARAMS_WIDTH-1:0]   t_inthold_i; // t29 = 1us
// Hold duration after integration (with reset_1 = 0 and hold = 1)
input      [TIMING_PARAMS_WIDTH-1:0]   t_inthold2_i; // t24 = 1us
// Prepare duration before readout (with reset_1 = 1 and hold = 1)
input      [TIMING_PARAMS_WIDTH-1:0]   t_rdoprep_i; // t27 = 1us
// Hold duration after integration (dmitryh:readout) (with reset_1 = 1 and hold = 1)
input      [TIMING_PARAMS_WIDTH-1:0]   t_rdohold_i; // t31 = 10 us
// ROI Clock period.
input      [TIMING_PARAMS_WIDTH-1:0]   t_roiclk_i;
// Number of modsel pulses.
input      [24-1:0]                    t_int_numclocks_i;

// Sensor modulation signals
output                                 sns_reset_1_o;
output                                 sns_hold_o;
output reg                             sns_modsel_en_o = 0;

// Sensor ROI (Region of Interest) readout signals
output                                 sns_start_roi_o;
input                                  sns_enable_roi_i;
output                                 sns_clk_roi_o;
output                                 sns_sel_sr_o;

input ppi_frame_valid_i;

output [3:0] deb_state_o;
output [24-1:0] deb_fsm_cnt_o;
output deb_fsm_cnt_en_o;
    

//`define STATE_RESET         11'b00000000001
//`define STATE_READY         11'b00000000010
//`define STATE_RESET_DONE    11'b00000000100
//`define STATE_INT_PREPARE   11'b00000001000
//`define STATE_INT_PREPARE2  11'b00000010000
//`define STATE_INTEGRATION   11'b00000100000
//`define STATE_INT_HOLD      11'b00001000000
//`define STATE_INT_HOLD2     11'b00010000000
//`define STATE_RDO_PREPARE   11'b00100000000
//`define STATE_READOUT       11'b01000000000
//`define STATE_RDO_HOLD      11'b10000000000
`define STATE_RESET         4'd0
`define STATE_READY         4'd1
`define STATE_RESET_DONE    4'd2
`define STATE_INT_PREPARE   4'd3
`define STATE_INT_PREPARE2  4'd4
`define STATE_INTEGRATION   4'd5
`define STATE_INT_HOLD      4'd6
`define STATE_INT_HOLD2     4'd7
`define STATE_RDO_PREPARE   4'd8
`define STATE_READOUT       4'd9
`define STATE_RDO_HOLD      4'd10

    //reg [10:0] i_state;
    reg [3:0] i_state;
    assign deb_state_o = i_state;
    
    reg [24-1:0] i_fsm_cnt_load_value;
    
    reg [24-1:0] i_fsm_cnt;
    assign deb_fsm_cnt_o = i_fsm_cnt;
    reg i_fsm_cnt_en;
    assign deb_fsm_cnt_en_o = i_fsm_cnt_en;
    // Timing generator for fsm delays
    always @(posedge clk_i) begin
        if (rst_i)
            i_fsm_cnt <= {TIMING_PARAMS_WIDTH{1'b0}};
        else if (!i_fsm_cnt_en)
            i_fsm_cnt <= i_fsm_cnt_load_value;
        else
            if (i_fsm_cnt > {TIMING_PARAMS_WIDTH{1'b0}}) begin
                i_fsm_cnt <= i_fsm_cnt - 1'b1;
            end
    end
    
    //assign i_fsm_cnt_done = i_fsm_cnt[TIMING_PARAMS_WIDTH-1];//(i_fsm_cnt == {TIMING_PARAMS_WIDTH{1'b0}});
    wire  i_fsm_cnt_zero = (i_fsm_cnt == {TIMING_PARAMS_WIDTH{1'b0}});
    reg i_fsm_cnt_zero_prev = 0;
    always @(posedge clk_i)
        i_fsm_cnt_zero_prev <= i_fsm_cnt_zero;
    wire i_fsm_cnt_done = i_fsm_cnt_zero && !i_fsm_cnt_zero_prev;
    
    
    wire i_rdo_done;
    reg i_sns_reset_1, i_sns_hold;
    
    // Main FSM
    assign ready_o = (i_state == `STATE_READY);

    always @(posedge clk_i) begin

    
        if (rst_i) begin
            
            i_state                  <= `STATE_RESET;
            i_fsm_cnt_load_value     <= t_pxlrst_i;
            i_fsm_cnt_en             <= 1'b0;
            i_sns_reset_1            <= 1'b1;
            i_sns_hold               <= 1'b0;
            
        end else if (i_state == `STATE_RESET) begin // 0
            
            i_fsm_cnt_en             <= 1'b1;
            i_sns_reset_1            <= 1'b1;
            i_sns_hold               <= 1'b0;

            if (i_fsm_cnt_done) begin
                i_state              <= `STATE_READY;
                i_fsm_cnt_en         <= 1'b0;
                i_sns_reset_1        <= 1'b1;
                i_sns_hold           <= 1'b0;
            end
        
        end else if (i_state == `STATE_READY) begin // 1
            
            i_fsm_cnt_en             <= 1'b0;
            i_sns_reset_1            <= 1'b1;
            i_sns_hold               <= 1'b0;

            if (start_i | autostart_i) begin
                i_state              <= `STATE_RESET_DONE;
                i_fsm_cnt_load_value <= t_rsthold_i;
                i_fsm_cnt_en         <= 1'b0;
                i_sns_reset_1        <= 1'b1;
                i_sns_hold           <= 1'b1;
            end

        end else if (i_state == `STATE_RESET_DONE) begin // 2
        
            i_fsm_cnt_en             <= 1'b1;
            i_sns_reset_1            <= 1'b1;
            i_sns_hold               <= 1'b1;

            if (i_fsm_cnt_done) begin
                i_state              <= `STATE_INT_PREPARE;
                i_fsm_cnt_load_value <= t_intprep_i;
                i_fsm_cnt_en         <= 1'b0;
                i_sns_reset_1        <= 1'b0;
                i_sns_hold           <= 1'b1;
            end


        end else if (i_state == `STATE_INT_PREPARE) begin // 3

            i_fsm_cnt_en             <= 1'b1;
            i_sns_reset_1            <= 1'b0;
            i_sns_hold               <= 1'b1;

            if (i_fsm_cnt_done) begin
                i_state              <= `STATE_INT_PREPARE2;
                i_fsm_cnt_load_value <= t_intprep2_i;
                i_fsm_cnt_en         <= 1'b0;
                i_sns_reset_1        <= 1'b0;
                i_sns_hold           <= 1'b0;
            end

        end else if (i_state == `STATE_INT_PREPARE2) begin // 4

            i_fsm_cnt_en             <= 1'b1;
            i_sns_reset_1            <= 1'b0;
            i_sns_hold               <= 1'b0;

            if (i_fsm_cnt_done) begin
                i_state              <= `STATE_INTEGRATION;
                i_fsm_cnt_load_value <= t_int_numclocks_i;
                i_fsm_cnt_en         <= 1'b0;
                i_sns_reset_1        <= 1'b0;
                i_sns_hold           <= 1'b0;
            end

        end else if (i_state == `STATE_INTEGRATION) begin // 5

            i_fsm_cnt_en             <= 1'b1;
            i_sns_reset_1            <= 1'b0;
            i_sns_hold               <= 1'b0;

            if (i_fsm_cnt_done) begin
                i_state              <= `STATE_INT_HOLD;
                i_fsm_cnt_load_value <= t_inthold_i;
                i_fsm_cnt_en         <= 1'b0;
                i_sns_reset_1        <= 1'b0;
                i_sns_hold           <= 1'b0;
            end

        end else if (i_state == `STATE_INT_HOLD) begin // 6

            i_fsm_cnt_en             <= 1'b1;
            i_sns_reset_1            <= 1'b0;
            i_sns_hold               <= 1'b0;

            if (i_fsm_cnt_done) begin
                i_state              <= `STATE_INT_HOLD2;
                i_fsm_cnt_load_value <= t_inthold2_i;
                i_fsm_cnt_en         <= 1'b0;
                i_sns_reset_1        <= 1'b0;
                i_sns_hold           <= 1'b1;
            end

        end else if (i_state == `STATE_INT_HOLD2) begin // 7

            i_fsm_cnt_en             <= 1'b1;
            i_sns_reset_1            <= 1'b0;
            i_sns_hold               <= 1'b1;

            if (i_fsm_cnt_done) begin
                i_state              <= `STATE_RDO_PREPARE;
                i_fsm_cnt_load_value <= t_rdoprep_i;
                i_fsm_cnt_en         <= 1'b0;
                i_sns_reset_1        <= 1'b1;
                i_sns_hold           <= 1'b1;
            end

        end else if (i_state == `STATE_RDO_PREPARE) begin // 8

            i_fsm_cnt_en             <= 1'b1;
            i_sns_reset_1            <= 1'b1;
            i_sns_hold               <= 1'b1;

            if (i_fsm_cnt_done) begin
                i_state              <= `STATE_READOUT;
                i_fsm_cnt_en         <= 1'b0;
                i_sns_reset_1        <= 1'b1;
                i_sns_hold           <= 1'b1;
            end

        end else if (i_state == `STATE_READOUT) begin // 9

            i_fsm_cnt_en             <= 1'b0;
            i_sns_reset_1            <= 1'b1;
            i_sns_hold               <= 1'b1;

            if (i_rdo_done) begin
                i_state              <= `STATE_RDO_HOLD;
                i_fsm_cnt_load_value <= t_rdohold_i;
                i_fsm_cnt_en         <= 1'b0;
                i_sns_reset_1        <= 1'b1;
                i_sns_hold           <= 1'b1;
            end

        end else if (i_state == `STATE_RDO_HOLD) begin // 10

            i_fsm_cnt_en             <= 1'b1;
            i_sns_reset_1            <= 1'b1;
            i_sns_hold               <= 1'b1;

            if (i_fsm_cnt_done) begin
                i_state              <= `STATE_RESET;
                i_fsm_cnt_load_value <= t_pxlrst_i;
                i_fsm_cnt_en         <= 1'b0;
                i_sns_reset_1        <= 1'b1;
                i_sns_hold           <= 1'b0;
            end

        end
    end
    
    assign sns_reset_1_o = i_sns_reset_1;
    assign sns_hold_o    = i_sns_hold;
    

    // Integration process
    
    always @(posedge clk_i) begin
        sns_modsel_en_o <= (i_state == `STATE_INTEGRATION);
    end
    
    // Readout process

    reg  [TIMING_PARAMS_WIDTH-1:0] i_roi_clk_fdcntr;
    reg  i_roi_clk;
    wire i_roi_clk_t, i_roi_clk_re, i_roi_clk_fe;
    
    always @(posedge clk_i) begin
        if (rst_i || i_roi_clk_t)
            i_roi_clk_fdcntr <= t_roiclk_i-1;
        else
            i_roi_clk_fdcntr <= i_roi_clk_fdcntr - 1'b1;
        
        if (rst_i)
            i_roi_clk <= 1'b0;
        else if (i_roi_clk_t)
            i_roi_clk <= !i_roi_clk;
    end
    assign i_roi_clk_t = (i_roi_clk_fdcntr == {TIMING_PARAMS_WIDTH{1'b0}});
    assign i_roi_clk_fe = (i_roi_clk_t && i_roi_clk);
    assign i_roi_clk_re = (i_roi_clk_t && !i_roi_clk);
    
    reg  i_roi_start, i_roi_cycle;
    reg  [1:0] i_roi_enable;
    wire i_rdo_start;

    assign i_rdo_start = (i_state == `STATE_READOUT && i_roi_clk_fe && !i_roi_cycle);
    
    wire composite_frame_valid = sns_enable_roi_i | ppi_frame_valid_i;

    always @(posedge clk_i) begin

        if (i_state != `STATE_READOUT)
            i_roi_cycle <= 1'b0;
        else if (i_roi_clk_fe && !i_roi_cycle)
            i_roi_cycle <= 1'b1;
            
        if (rst_i || (i_roi_start && i_roi_clk_fe))
            i_roi_start <= 1'b0;
        else if (i_rdo_start)
            i_roi_start <= 1'b1;
        
        if (i_roi_clk_re)
            i_roi_enable[1:0] <= {i_roi_enable[0], composite_frame_valid};
    end
    
    assign i_rdo_done = ((i_state == `STATE_READOUT) && (i_roi_enable == 2'b10));
    
    assign sns_start_roi_o = i_roi_start;
    assign sns_clk_roi_o = i_roi_clk;
    assign sns_sel_sr_o = 1'b0;
    

endmodule
