module ppi_generator
(
    input  clk_ppi,
    input  rst,
    
    input  start,
    output reg ready = 0,
    
    output [15:0] ppi_data,
    output ppi_fs1,
    output ppi_fs2,
    output ppi_fs3
);

    `include "auxilary_functions.v"

    localparam FRAME_WIDTH = 162;
    localparam FRAME_HEIGHT = 120;
    localparam HBI = 10;
    localparam VBI = 2;

    localparam ST_IDLE = 0;
    localparam ST_GENERATE = 1;
    reg [0:0] st = ST_IDLE;
    
    reg [base2(FRAME_WIDTH)-1:0] cnt_w = 0;
    reg [base2(FRAME_HEIGHT)-1:0] cnt_h = 0;
    reg horz_blank = 0;
    
    localparam NO_DATA = 16'hFFFF;
    reg [15:0] data = NO_DATA;
    reg line_valid = 0;
    reg frame_valid = 0;
    
    wire [15:0] common_counter = cnt_h * FRAME_WIDTH + cnt_w;

    always @(posedge clk_ppi) begin
        if (rst) begin
            st <= ST_IDLE;
            cnt_w <= 0;
            cnt_h <= 0;
            data <= NO_DATA;
            line_valid <= 0;
            frame_valid <= 0;
            horz_blank <= 0;
        end
        else begin
            case (st)
            ST_IDLE: begin
                if (start) begin
                    st <= ST_GENERATE;
                end
                
                cnt_w <= 0;
                cnt_h <= 0;
                data <= NO_DATA;
                line_valid <= 0;
                frame_valid <= 0;
                horz_blank <= 0;
            end
            ST_GENERATE: begin
                if (horz_blank) begin
                    line_valid <= 0;
                    data <= NO_DATA;

                    if (cnt_w >= HBI-1) begin
                        horz_blank <= 0;
                        cnt_w <= 0;
                        
                        if (cnt_h >= FRAME_HEIGHT-1) begin
                            cnt_h <= 0;
                            st <= ST_IDLE;
                        end
                        else begin
                            cnt_h <= cnt_h + 1;
                        end
                    end
                    else begin
                        cnt_w <= cnt_w + 1;
                    end
                end
                else begin
                    line_valid <= 1;
                    data <= common_counter;
                    
                    if (cnt_w >= FRAME_WIDTH-1) begin
                        horz_blank <= 1;
                        cnt_w <= 0;
                    end
                    else begin
                        cnt_w <= cnt_w + 1;
                    end
                end
                
                frame_valid <= 1;
            end
            endcase
        end
    end
    
    assign ppi_data = data;
    assign ppi_fs1 = line_valid;
    assign ppi_fs2 = frame_valid;
    assign ppi_fs3 = 0;
    
    always @(posedge clk_ppi)
        ready <= (st == ST_IDLE);
    
endmodule
