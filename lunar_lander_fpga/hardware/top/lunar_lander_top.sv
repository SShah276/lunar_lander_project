//-------------------------------------------------------------------------
//    lunar_lander_top.sv                                               --
//                                                                       --
//    First integration milestone top-level skeleton for the ECE 385     --
//    Lunar Lander project.                                              --
//                                                                       --
//    Purpose:                                                           --
//    - keep the video pipeline alive                                    --
//    - render a tiny temporary player sprite                            --
//    - show where MicroBlaze / block design signals will connect later  --
//-------------------------------------------------------------------------

module lunar_lander_top (
    input  logic Clk,
    input  logic reset_rtl_0,

    // HDMI outputs
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0] hdmi_tmds_data_n,
    output logic [2:0] hdmi_tmds_data_p
);

    logic clk_25MHz;
    logic clk_125MHz;
    logic locked;

    logic [9:0] drawX;
    logic [9:0] drawY;

    logic hsync;
    logic vsync;
    logic vde;

    logic [3:0] red;
    logic [3:0] green;
    logic [3:0] blue;

    logic [9:0] lander_x;
    logic [9:0] lander_y;

    logic reset_ah;
    assign reset_ah = reset_rtl_0;

    // --------------------------------------------------------------------
    // Temporary stand-in game state for renderer bring-up.
    // Replace these assignments later with the real MicroBlaze / AXI
    // register outputs from the Vivado block design.
    //
    // Example future hookup:
    // assign lander_x = game_state_lander_x;
    // assign lander_y = game_state_lander_y;
    // --------------------------------------------------------------------
    assign lander_x = 10'd320;
    assign lander_y = 10'd120;

    // Clock wizard configured with a 1x and 5x clock for HDMI.
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );

    // VGA timing generator.
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );

    // Temporary renderer input wiring for milestone 1.
    // Later, lander_x and lander_y will come from memory-mapped registers
    // written by MicroBlaze software.
    color_mapper color_instance (
        .lander_x(lander_x),
        .lander_y(lander_y),
        .DrawX(drawX),
        .DrawY(drawY),
        .Red(red),
        .Green(green),
        .Blue(blue)
    );

    // HDMI output wrapper.
    hdmi_tx_0 vga_to_hdmi (
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        .rst(reset_ah),
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        .TMDS_CLK_P(hdmi_tmds_clk_p),
        .TMDS_CLK_N(hdmi_tmds_clk_n),
        .TMDS_DATA_P(hdmi_tmds_data_p),
        .TMDS_DATA_N(hdmi_tmds_data_n)
    );

endmodule
