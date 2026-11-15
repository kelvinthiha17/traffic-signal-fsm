// tick_gen_tb.sv
// Self-checking testbench: measures the number of cycles between ticks
// and reports an error if it is not exactly N. Prints PASS or FAIL.

`timescale 1ns/1ps

module tick_gen_tb;

    localparam int N = 5;          // small N keeps the simulation short

    logic clk = 0;
    logic rst;
    logic tick;

    tick_gen #(.N(N)) dut (
        .clk  (clk),
        .rst  (rst),
        .tick (tick)
    );

    always #5 clk = ~clk;          // 10 ns period = 100 MHz

    // ---- Checker ----
    int cycle      = 0;
    int last_tick  = -1;
    int num_ticks  = 0;
    int errors     = 0;

    always @(posedge clk) begin
        cycle++;
        if (!rst && tick) begin
            if (last_tick >= 0 && (cycle - last_tick) != N) begin
                $error("Tick period was %0d cycles, expected %0d",
                       cycle - last_tick, N);
                errors++;
            end
            last_tick = cycle;
            num_ticks++;
        end
    end

    // ---- Stimulus ----
    initial begin
        rst = 1;
        repeat (3) @(posedge clk);
        rst <= 0;                  // nonblocking: avoids a race with the DUT on this edge

        repeat (N * 5) @(posedge clk);

        if (errors == 0 && num_ticks >= 2)
            $display("PASS: %0d ticks, every %0d cycles", num_ticks, N);
        else
            $display("FAIL: %0d errors, %0d ticks", errors, num_ticks);
        $finish;
    end

endmodule
