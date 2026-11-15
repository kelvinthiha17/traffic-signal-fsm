// traffic_fsm.sv
// 4-state Moore traffic light controller with a pedestrian walk request.
// Runs on the system clock and only advances when `tick` is high.

module traffic_fsm (
    input  logic clk,
    input  logic rst,          // synchronous, active-high
    input  logic tick,         // 1-cycle pulse once per second
    input  logic walk,         // walk button (already synchronized)
    output logic main_red, main_amber, main_green,
    output logic cross_red, cross_amber, cross_green
);

    typedef enum logic [1:0] {
        S0_MAIN_GREEN  = 2'b00,
        S1_MAIN_AMBER  = 2'b01,
        S2_CROSS_GREEN = 2'b10,
        S3_CROSS_AMBER = 2'b11
    } state_t;

    state_t     state;
    logic [3:0] counter;
    logic       walk_req;

    // Remember a walk press until the FSM serves it,
    // so a press shorter than one tick is not missed.
    always_ff @(posedge clk) begin
        if (rst)
            walk_req <= 1'b0;
        else if (walk)
            walk_req <= 1'b1;
        else if (tick && state == S0_MAIN_GREEN)
            walk_req <= 1'b0;
    end

    // State register + counter: only advance on tick (clock enable)
    always_ff @(posedge clk) begin
        if (rst) begin
            state   <= S0_MAIN_GREEN;
            counter <= '0;
        end
        else if (tick) begin
            unique case (state)
                S0_MAIN_GREEN: begin
                    if (walk_req) begin
                        state   <= S1_MAIN_AMBER;
                        counter <= '0;
                    end
                end
                S1_MAIN_AMBER: begin                // 4 s
                    if (counter == 3) begin
                        state   <= S2_CROSS_GREEN;
                        counter <= '0;
                    end
                    else counter <= counter + 1'b1;
                end
                S2_CROSS_GREEN: begin               // 8 s
                    if (counter == 7) begin
                        state   <= S3_CROSS_AMBER;
                        counter <= '0;
                    end
                    else counter <= counter + 1'b1;
                end
                S3_CROSS_AMBER: begin               // 4 s
                    if (counter == 3) begin
                        state   <= S0_MAIN_GREEN;
                        counter <= '0;
                    end
                    else counter <= counter + 1'b1;
                end
            endcase
        end
    end

    // Moore outputs: depend only on the current state.
    // All-zero default prevents latches.
    always_comb begin
        {main_red, main_amber, main_green,
         cross_red, cross_amber, cross_green} = '0;

        unique case (state)
            S0_MAIN_GREEN:  begin main_green = 1'b1; cross_red   = 1'b1; end
            S1_MAIN_AMBER:  begin main_amber = 1'b1; cross_red   = 1'b1; end
            S2_CROSS_GREEN: begin main_red   = 1'b1; cross_green = 1'b1; end
            S3_CROSS_AMBER: begin main_red   = 1'b1; cross_amber = 1'b1; end
        endcase
    end

endmodule
