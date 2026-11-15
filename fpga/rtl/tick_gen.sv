// tick_gen.sv
// Produces a one-clock-cycle pulse ("tick") once every N clock cycles.
// Used as a clock ENABLE, not as a clock: all logic stays on the 100 MHz clock.

module tick_gen #(
    parameter int N = 100_000_000      // 100 MHz / 100,000,000 = 1 tick per second
)(
    input  logic clk,
    input  logic rst,                   // synchronous, active-high
    output logic tick
);

    logic [$clog2(N)-1:0] count;

    always_ff @(posedge clk) begin
        if (rst)
            count <= '0;
        else if (count == N-1)          // last value is N-1, so the period is exactly N
            count <= '0;
        else
            count <= count + 1'b1;
    end

    assign tick = (count == N-1);

endmodule
