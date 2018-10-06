module ad9826_data_controller
(
    input  clk_adc_i, // about 30 MHz
    input  rst_i,
    
    input  sns_enable_roi_i,
    input  sns_clk_roi_i,
    
    input  [7:0] adc_data_i,
    output reg   adc_sclk2_o = 1'b0, // about 2.5 MHz, 1/12 fill
    output       adc_sclk1_o, // = 0
    output reg   adc_cclk_o = 1'b0, // about 7.5 MHz
    
    output reg [15:0] ppi_data_o,
    output ppi_fs1_o,
    output ppi_fs2_o,
    output ppi_fs3_o,
    output reg ppi_clk_o = 1'b0
);

    // 3-channel SHA mode

    localparam NUM_PHASES = 12;
    reg [3:0] phase;
    
    reg  sns_clk_roi_prev = 1'b1;
    always @(posedge clk_adc_i) begin
        sns_clk_roi_prev <= sns_clk_roi_i;
    end
    wire sns_clk_roi_posedge = sns_clk_roi_i & (~sns_clk_roi_prev);
    
    always @(posedge clk_adc_i) begin
        if (rst_i) begin
            phase <= 0;
        end
        else begin
            if (sns_clk_roi_posedge) begin
                phase <= 1;
            end
            else begin
                if (phase >= NUM_PHASES-1) phase <= 0;
                else phase <= phase + 1;
            end
        end
    end
    
    reg  generating_frame = 0;
    reg  line_valid;
    reg  frame_valid;
    
    localparam NUM_IDX_COL = 54+1; // ceil(160/3)=54
    localparam NUM_IDX_ROW = 120;
    
    reg  [6:0] idx_col;
    reg  [6:0] idx_row;
    reg  [7:0] high_byte;
    reg sns_enable_roi_prev;
    
    always @(posedge clk_adc_i) begin
        if (rst_i) begin
            adc_cclk_o <= 0;
            adc_sclk2_o <= 0;
            ppi_clk_o <= 0;
            high_byte <= 0;
            ppi_data_o <= 0;
            generating_frame <= 0;
            idx_row <= 0;
            idx_col <= 0;
            line_valid <= 0;
            frame_valid <= 0;
            sns_enable_roi_prev <= 0;
        end
        else begin
            if ((phase % 4) == 1) begin
                adc_cclk_o <= 0;
            end
            if ((phase % 4) == 3) begin
                adc_cclk_o <= 1;
            end
            adc_sclk2_o <= (phase == NUM_PHASES-2); // 10
            
            if ((phase % 4) == 1) begin
                ppi_clk_o <= 0;
            end
            if ((phase % 4) == 3) begin
                ppi_clk_o <= 1;
            end
            
            if (generating_frame) begin
                if (phase == 1) begin
                    high_byte <= adc_data_i;
                end
                if (phase == 3) begin
                    ppi_data_o <= {high_byte, adc_data_i};
                end
                if (phase == 5) begin
                    high_byte <= adc_data_i;
                end
                if (phase == 7) begin
                    ppi_data_o <= {high_byte, adc_data_i};
                end
                if (phase == 9) begin
                    high_byte <= adc_data_i;
                end
                if (phase == 11) begin
                    ppi_data_o <= {high_byte, adc_data_i};
                end
            end
            else begin
                ppi_data_o <= 0;
            end
            
            if (phase == 11) begin
                sns_enable_roi_prev <= sns_enable_roi_i;
                
                if (sns_enable_roi_i && !sns_enable_roi_prev) begin
                    generating_frame <= 1;
                end
                
                if (generating_frame) begin
                    if (idx_col > 0) begin
                        line_valid <= 1;
                    end
                    else begin
                        line_valid <= 0;
                    end
                    
                    frame_valid <= 1;
                    
                    if (idx_col >= NUM_IDX_COL-1) begin
                        idx_col <= 0;
                        
                        if (idx_row >= NUM_IDX_ROW-1) begin
                            idx_row <= 0;
                            idx_col <= 0;
                            line_valid <= 0;
                            frame_valid <= 0;
                            generating_frame <= 0;
                        end
                        else begin
                            idx_row <= idx_row + 1;
                        end
                    end
                    else begin
                        idx_col <= idx_col + 1;
                    end
                end
            end
        end
    end
    
    assign adc_sclk1_o = 0;

    assign ppi_fs1_o = line_valid;
    assign ppi_fs2_o = frame_valid;
    assign ppi_fs3_o = 0;
    
endmodule
