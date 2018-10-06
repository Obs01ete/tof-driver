module register_file
(
    input  clk_i,
    input  rst_i,
    
    input  [15:0] cpu_din_i,
    input         cpu_din_we_i,
    
    output reg [15:0] cpu_dout_o,
    output reg        cpu_dout_valid_o,
    input             cpu_dout_ack_i,
    
    output reg [2:0] adc_p_address_o,
    output reg [8:0] adc_p_write_data_o,
    output reg       adc_p_write_valid_o,
    output reg       adc_p_read_start_o,
    input      [8:0] adc_p_read_data_i,
    input            adc_p_busy_i,
    
    output reg [6:0] sns_p_address_o,
    output reg [7:0] sns_p_write_data_o,
    output reg       sns_p_write_valid_o,
    output reg       sns_p_read_start_o,
    input      [7:0] sns_p_read_data_i,
    input            sns_p_busy_i,
    output reg       sns_p_mux_ce_a_nd_o,
        
    output reg [7:0] cfg_register_o,
    output start_cycle_o,
    output reg [7:0] modsel_divisor_o,
    output reg [7:0] modsel_phase_o,
    output reg [23:0] integration_time_o,
    input  cycle_finished_i,
    output reg override_sns_enable_roi_o,
    output reg switch_to_cycle_emulation_o,
    output reg adc_ctrl_o,
    output reg is_multicycle_o,
    output reg [7:0] modsel_phase_1_o,
    output reg [7:0] modsel_phase_2_o,
    output reg [7:0] modsel_phase_3_o,

    input  [7:0] debug_0_i,
    input  [7:0] debug_1_i,
    input  [7:0] debug_2_i,
    input  [7:0] debug_3_i,
    input  [7:0] debug_4_i,
    input  [7:0] debug_5_i,
    input  [7:0] debug_6_i,
    input  [7:0] debug_7_i
);

    `include "register_file_address_space.v"

    localparam [0:0] write_bit = RF_WRITE_BIT;
    localparam [0:0] read_bit = RF_READ_BIT;
    
    reg  cpu_din_we_prev = 0;
    always @(posedge clk_i)
        cpu_din_we_prev <= cpu_din_we_i;
    wire cpu_din_we = cpu_din_we_i & (~cpu_din_we_prev);
    
    wire wr_nrd_comb = cpu_din_we ? cpu_din_i[15] : 0;
    wire [6:0] address_comb = cpu_din_we ? cpu_din_i[8+:7] : 0;
    wire [7:0] data_in_comb = cpu_din_we ? cpu_din_i[0+:8] : 0;
    
    reg adc_higher_byte_written = 0; // for ADC
    reg start_cycle_int = 0;

    always @(posedge clk_i) begin
        if (rst_i) begin
            cpu_dout_o <= 16'd0;
            cpu_dout_valid_o <= 0;
            
            cfg_register_o <= 0;
            modsel_divisor_o <= 6;
            modsel_phase_o <= 0;
            modsel_phase_1_o <= 0;
            modsel_phase_2_o <= 0;
            modsel_phase_3_o <= 0;
            integration_time_o <= 24'd1500;
            override_sns_enable_roi_o <= 0;
            switch_to_cycle_emulation_o <= 0;
            start_cycle_int <= 0;
            adc_ctrl_o <= 0;
            is_multicycle_o <= 0;
            
            adc_p_address_o <= 3'b0;
            adc_p_write_data_o <= 9'b0;
            adc_p_write_valid_o <= 1'b0;
            adc_p_read_start_o <= 1'b0;
            adc_higher_byte_written <= 0;

            sns_p_address_o <= 7'b0;
            sns_p_write_data_o <= 8'b0;
            sns_p_write_valid_o <= 1'b0;
            sns_p_read_start_o <= 1'b0;
            sns_p_mux_ce_a_nd_o <= 1'b1;
        end
        else begin
            // defaults
            cpu_dout_o <= 16'd0;
            cpu_dout_valid_o <= 0;
            adc_p_write_valid_o <= 0;  
            adc_p_read_start_o <= 0;
            sns_p_write_valid_o <= 0;  
            sns_p_read_start_o <= 0;
            start_cycle_int <= 0; // pulse
            
            if (cpu_din_we) begin
                case (address_comb)
                    ADDRESS_CFG_REGISTER: begin
                        if (wr_nrd_comb) begin
                            cfg_register_o <= data_in_comb[0+:8];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, cfg_register_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_MODSEL_DIVISOR: begin
                        if (wr_nrd_comb) begin
                            modsel_divisor_o <= data_in_comb[0+:8];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, modsel_divisor_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_MODLED_PHASE: begin
                        if (wr_nrd_comb) begin
                            modsel_phase_o <= data_in_comb[0+:8];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, modsel_phase_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_MODLED_PHASE_1: begin
                        if (wr_nrd_comb) begin
                            modsel_phase_1_o <= data_in_comb[0+:8];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, modsel_phase_1_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_MODLED_PHASE_2: begin
                        if (wr_nrd_comb) begin
                            modsel_phase_2_o <= data_in_comb[0+:8];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, modsel_phase_2_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_MODLED_PHASE_3: begin
                        if (wr_nrd_comb) begin
                            modsel_phase_3_o <= data_in_comb[0+:8];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, modsel_phase_3_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_START_CYCLE: begin
                        if (wr_nrd_comb) begin
                            start_cycle_int <= 1; // pulse
                        end
                    end
                    ADDRESS_CYCLE_FINISHED: begin
                        if (wr_nrd_comb) begin
                            // do nothing
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, 7'b0, cycle_finished_i};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_INTEGRATION_TIME_0: begin
                        if (wr_nrd_comb) begin
                            integration_time_o[0+:8] <= data_in_comb[0+:8];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, integration_time_o[0+:8]};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_INTEGRATION_TIME_1: begin
                        if (wr_nrd_comb) begin
                            integration_time_o[8+:8] <= data_in_comb[0+:8];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, integration_time_o[8+:8]};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_INTEGRATION_TIME_2: begin
                        if (wr_nrd_comb) begin
                            integration_time_o[16+:8] <= data_in_comb[0+:8];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, integration_time_o[16+:8]};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_OVERRIDE_ENABLE_ROI: begin
                        if (wr_nrd_comb) begin
                            override_sns_enable_roi_o <= data_in_comb[0];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, 7'b0, override_sns_enable_roi_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_ENABLE_CYCLE_EMULATION: begin
                        if (wr_nrd_comb) begin
                            switch_to_cycle_emulation_o <= data_in_comb[0];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, 7'b0, switch_to_cycle_emulation_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    
                    // ----------------------------- ADC ---------------------------------
                    ADDRESS_ADC_ADDR: begin
                        if (wr_nrd_comb) begin
                            adc_p_address_o <= data_in_comb[0+:3];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, 5'b0, adc_p_address_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_ADC_VALUE: begin
                        if (wr_nrd_comb) begin
                            if (adc_higher_byte_written) begin
                                adc_p_write_data_o[0+:8] <= data_in_comb[0+:8]; // do not overwrite higher byte (1 bit)
                            end
                            else begin
                                adc_p_write_data_o <= {1'b0, data_in_comb[0+:8]}; // force higher byte to 0
                            end
                            adc_higher_byte_written <= 0;
                            adc_p_write_valid_o <= 1;
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, adc_p_read_data_i[0+:8]};
                            cpu_dout_valid_o <= 1;     
                        end
                    end
                    ADDRESS_ADC_VALUE_HIGHER_BYTE: begin
                        if (wr_nrd_comb) begin
                            adc_p_write_data_o[8] <= data_in_comb[0];
                            adc_higher_byte_written <= 1;
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, {7'b0, adc_p_read_data_i[8]}};
                            cpu_dout_valid_o <= 1;     
                        end
                    end
                    ADDRESS_ADC_BUSY: begin
                        if (wr_nrd_comb) begin
                            // do nothing
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, 7'b0, adc_p_busy_i};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_ADC_ACQUIRE: begin
                        adc_p_read_start_o <= 1;
                    end
                    // ----------------------------- end ADC ---------------------------------
                    
                    // ----------------------------- Sensor ---------------------------------
                    ADDRESS_SNS_ADDR: begin
                        if (wr_nrd_comb) begin
                            sns_p_address_o <= data_in_comb[0+:7];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, 1'b0, sns_p_address_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_SNS_VALUE: begin
                        if (wr_nrd_comb) begin
                            sns_p_write_data_o <= data_in_comb[0+:8];
                            sns_p_write_valid_o <= 1;
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, sns_p_read_data_i[0+:8]};
                            cpu_dout_valid_o <= 1;     
                        end
                    end
                    ADDRESS_SNS_BUSY: begin
                        if (wr_nrd_comb) begin
                            // do nothing
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, 7'b0, sns_p_busy_i};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_SNS_ACQUIRE: begin
                        sns_p_read_start_o <= 1;
                    end
                    ADDRESS_MUX_CE_A_ND: begin
                        if (wr_nrd_comb) begin
                            sns_p_mux_ce_a_nd_o <= data_in_comb[0];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, 7'b0, sns_p_mux_ce_a_nd_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    // ----------------------------- end Sensor ---------------------------------
                    
                    ADDRESS_DEBUG_0: begin
                        if (!wr_nrd_comb) begin
                            cpu_dout_o <= {read_bit, address_comb, debug_0_i};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_DEBUG_1: begin
                        if (!wr_nrd_comb) begin
                            cpu_dout_o <= {read_bit, address_comb, debug_1_i};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_DEBUG_2: begin
                        if (!wr_nrd_comb) begin
                            cpu_dout_o <= {read_bit, address_comb, debug_2_i};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_DEBUG_3: begin
                        if (!wr_nrd_comb) begin
                            cpu_dout_o <= {read_bit, address_comb, debug_3_i};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_DEBUG_4: begin
                        if (!wr_nrd_comb) begin
                            cpu_dout_o <= {read_bit, address_comb, debug_4_i};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_DEBUG_5: begin
                        if (!wr_nrd_comb) begin
                            cpu_dout_o <= {read_bit, address_comb, debug_5_i};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_DEBUG_6: begin
                        if (!wr_nrd_comb) begin
                            cpu_dout_o <= {read_bit, address_comb, debug_6_i};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    ADDRESS_DEBUG_7: begin
                        if (!wr_nrd_comb) begin
                            cpu_dout_o <= {read_bit, address_comb, debug_7_i};
                            cpu_dout_valid_o <= 1;
                        end
                    end

                    ADDRESS_ADC_CTRL: begin
                        if (wr_nrd_comb) begin
                            adc_ctrl_o <= data_in_comb[0];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, 7'b0, adc_ctrl_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    
                    ADDRESS_MULTICYCLE_MODE: begin
                        if (wr_nrd_comb) begin
                            is_multicycle_o <= data_in_comb[0];
                        end
                        else begin
                            cpu_dout_o <= {read_bit, address_comb, 7'b0, is_multicycle_o};
                            cpu_dout_valid_o <= 1;
                        end
                    end
                    
                    default: begin
                        // do nothing
                    end
                endcase
            end
        end
    end

    posedge_detection front_of_start(
        .signal(start_cycle_int),
        .clk(clk_i),
        .posedge_signal(start_cycle_o)
    );
    
endmodule
