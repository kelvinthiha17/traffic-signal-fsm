// top.sv
// Board-level wrapper for the RealDigital Boolean board (Spartan-7).
// Port names match fpga/constraints/traffic_fsm.xdc.

module top (
    input  logic        clk,      // 100 MHz oscillator
    input  logic [3:0]  btn,      // btn[0] = walk, btn[1] = reset (active-high)
    output logic [15:0] led,
    output logic [2:0]  RGB0,     // main street light  {B, G, R}
    output logic [2:0]  RGB1      // cross street light {B, G, R}
);

    // ---- 2-flip-flop synchronizers for the asynchronous button inputs ----
    logic [1:0] rst_sync, walk_sync;
    always_ff @(posedge clk) begin
        rst_sync  <= {rst_sync[0],  btn[1]};
        walk_sync <= {walk_sync[0], btn[0]};
    end
    logic rst, walk;
    assign rst  = rst_sync[1];
    assign walk = walk_sync[1];

    // ---- 1 Hz tick ----
    logic tick;
    tick_gen #(.N(100_000_000)) u_tick (
        .clk  (clk),
        .rst  (rst),
        .tick (tick)
    );

    // ---- Traffic light FSM ----
    logic mr, ma, mg, cr, ca, cg;
    traffic_fsm u_fsm (
        .clk         (clk),
        .rst         (rst),
        .tick        (tick),
        .walk        (walk),
        .main_red    (mr), .main_amber  (ma), .main_green  (mg),
        .cross_red   (cr), .cross_amber (ca), .cross_green (cg)
    );

    // ---- Outputs ----
    // RGB LEDs: red = R, green = G, amber = R + G
    assign RGB0 = {1'b0, mg | ma, mr | ma};
    assign RGB1 = {1'b0, cg | ca, cr | ca};

    // Debug LEDs: LD2..LD0 = main G/A/R, LD5..LD3 = cross G/A/R
    assign led = {10'b0, cg, ca, cr, mg, ma, mr};

endmodule
