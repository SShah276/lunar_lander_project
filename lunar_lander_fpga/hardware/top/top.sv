//-------------------------------------------------------------------------
//    top.sv                                                             --
//                                                                       --
//    Minimal first-demo integration top for Lunar Lander.               --
//                                                                       --
//    Architecture:                                                      --
//    - MicroBlaze C owns keyboard input and game state                  --
//    - SystemVerilog only renders                                       --
//    - lander_x / lander_y are temporary placeholders until the         --
//      block design exports real game-state outputs                     --
//-------------------------------------------------------------------------

module top (
    input  logic clk_100MHz,
    input  logic reset_rtl_0,

    // USB / SPI / UART ports exported by the Vivado block design wrapper.
    input  logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input  logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    input  logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,

    // Optional debug outputs currently driven by the wrapper.
    output logic [31:0] gpio_usb_keycode_0_tri_o,
    output logic [31:0] gpio_usb_keycode_1_tri_o,

    // HDMI outputs.
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
    logic [9:0] lander_x;
    logic [9:0] lander_y;
    logic [1:0] angle_idx;
    logic thrust_active;
    logic [7:0] fuel_scaled;
    logic [7:0] vel_y_scaled;
    logic [7:0] vel_x_scaled;

    logic hsync;
    logic vsync;
    logic vde;

    logic [3:0] red;
    logic [3:0] green;
    logic [3:0] blue;

    logic reset_ah;
    assign reset_ah = reset_rtl_0;

    // --------------------------------------------------------------------
    // Vivado block design wrapper.
    // This currently provides USB, UART, and debug GPIO.
    //
    // Future update:
    // when the wrapper exports game-state outputs, connect them here:
    // assign lander_x = game_state_lander_x;
    // assign lander_y = game_state_lander_y;
    // --------------------------------------------------------------------
    mb_block_wrapper mb_block_i (
        .clk_100MHz(clk_100MHz),
        .reset_rtl_0(~reset_ah),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .gpio_usb_keycode_0_tri_o(gpio_usb_keycode_0_tri_o),
        .gpio_usb_keycode_1_tri_o(gpio_usb_keycode_1_tri_o),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss),
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd)
    );

    // Temporary stand-in position values for renderer bring-up.
    // Replace these with real wrapper outputs later.
    assign lander_x = 10'd320;
    assign lander_y = 10'd240;
    assign angle_idx = 2'd1;
    assign thrust_active = 1'b0;
    assign fuel_scaled = 8'hFF;
    assign vel_y_scaled = 8'h00;
    assign vel_x_scaled = 8'h00;

    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(clk_100MHz)
    );

    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );

    color_mapper color_instance (
        .lander_x(lander_x),
        .lander_y(lander_y),
        .angle_idx(angle_idx),
        .thrust_active(thrust_active),
        .fuel_scaled(fuel_scaled),
        .vel_y_scaled(vel_y_scaled),
        .vel_x_scaled(vel_x_scaled),
        .DrawX(drawX),
        .DrawY(drawY),
        .Red(red),
        .Green(green),
        .Blue(blue)
    );

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
