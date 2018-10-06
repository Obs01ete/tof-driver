module multicycle_generator(
    input  clk_i,
    input  rst_i,
    
    input  is_multicycle_i,
    input  start_multicycle_i,
    output reg start_sycle_o,
    input  ppi_frame_valid_i,
    input  cycle_finished_i,
    output reg multicycle_finished_o,

    input  [7:0] modsel_phase_i, // also modsel_phase_0_i
    input  [7:0] modsel_phase_1_i,
    input  [7:0] modsel_phase_2_i,
    input  [7:0] modsel_phase_3_i,
    output reg [7:0] modsel_phase_o
);

    `include "auxilary_functions.v"

    localparam NUM_CYCLES = 4;
    reg [base2(NUM_CYCLES)-1:0] cnt;
    
    localparam ST_IDLE = 0;
    localparam ST_CYCLES_START = 1;
    localparam ST_CYCLES_WAIT_MODSEL = 2;
    localparam ST_CYCLES_WAIT_FINISHED = 3;
    reg [1:0] st;
    
    reg [base2(NUM_CYCLES)-1:0] last_cycle;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            start_sycle_o <= 0;
            multicycle_finished_o <= 1;
            cnt <= 0;
            st <= ST_IDLE;
        end
        else begin
            start_sycle_o <= 0;
            
            case (st)
            ST_IDLE: begin
                if (start_multicycle_i) begin
                    multicycle_finished_o <= 0;
                    st <= ST_CYCLES_START;
                    cnt <= 0;
                end
            end
            ST_CYCLES_START: begin
                start_sycle_o <= 1;
                st <= ST_CYCLES_WAIT_MODSEL;
            end
            ST_CYCLES_WAIT_MODSEL: begin
                if (ppi_frame_valid_i) begin
                    st <= ST_CYCLES_WAIT_FINISHED;
                end
            end
            ST_CYCLES_WAIT_FINISHED: begin
                last_cycle = is_multicycle_i ? NUM_CYCLES-1 : 0;
                
                if (cycle_finished_i) begin
                    if (cnt >= last_cycle) begin
                        st <= ST_IDLE;
                        multicycle_finished_o <= 1;
                        cnt <= 0;
                    end
                    else begin
                        st <= ST_CYCLES_START;
                        cnt <= cnt + 1;
                    end
                end
            end
            default: begin
                st <= ST_IDLE;
            end
            endcase
        end
    end
    
    always @(posedge clk_i) begin
        modsel_phase_o <=
            is_multicycle_i ? (
                (cnt == 0) ? modsel_phase_i :
                (cnt == 1) ? modsel_phase_1_i :
                (cnt == 2) ? modsel_phase_2_i :
                modsel_phase_3_i) :
            modsel_phase_i;
    end

endmodule
