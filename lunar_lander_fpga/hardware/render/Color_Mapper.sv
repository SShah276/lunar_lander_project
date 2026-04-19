//-------------------------------------------------------------------------
//    Color_Mapper.sv                                                    --
//    Stephen Kempf                                                      --
//    3-1-06                                                             --
//                                                                       --
//    Modified by David Kesler  07-16-2008                               --
//    Translated by Joe Meng    07-07-2013                               --
//    Modified by Zuofu Cheng   08-19-2023                               --
//                                                                       --
//    Fall 2023 Distribution                                             --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------
//
// Friday-demo Lunar Lander renderer:
// - hardware only renders pixels
// - software owns all motion and physics
// - the lander is a tiny fixed bitmap sprite for first integration
//
// Current scene:
// - dark background
// - flat ground near the bottom of the screen
// - 8x8 sprite centered at (lander_x, lander_y)
//-------------------------------------------------------------------------

module color_mapper (
    input  logic [9:0] lander_x,
    input  logic [9:0] lander_y,
    input  logic [9:0] DrawX,
    input  logic [9:0] DrawY,
    output logic [3:0] Red,
    output logic [3:0] Green,
    output logic [3:0] Blue
);

    localparam logic [9:0] SCREEN_X_MAX = 10'd639;
    localparam logic [9:0] SCREEN_Y_MAX = 10'd479;
    localparam logic [9:0] GROUND_Y     = 10'd430;
    localparam logic [3:0] SPRITE_SIZE  = 4'd8;
    localparam logic [3:0] SPRITE_HALF  = 4'd4;

    logic lander_bbox_on;
    logic lander_on;
    logic ground_on;
    logic [2:0] sprite_row;
    logic [2:0] sprite_col;
    logic [7:0] sprite_bits;

    logic [9:0] lander_left;
    logic [9:0] lander_right;
    logic [9:0] lander_top;
    logic [9:0] lander_bottom;

    always_comb begin
        lander_left   = (lander_x >= SPRITE_HALF) ? (lander_x - SPRITE_HALF) : 10'd0;
        lander_right  = (lander_left + SPRITE_SIZE - 10'd1 < SCREEN_X_MAX) ?
                        (lander_left + SPRITE_SIZE - 10'd1) : SCREEN_X_MAX;
        lander_top    = (lander_y >= SPRITE_HALF) ? (lander_y - SPRITE_HALF) : 10'd0;
        lander_bottom = (lander_top + SPRITE_SIZE - 10'd1 < SCREEN_Y_MAX) ?
                        (lander_top + SPRITE_SIZE - 10'd1) : SCREEN_Y_MAX;

        lander_bbox_on =
            (DrawX >= lander_left) &&
            (DrawX <= lander_right) &&
            (DrawY >= lander_top) &&
            (DrawY <= lander_bottom);

        ground_on = (DrawY >= GROUND_Y);

        if (lander_bbox_on) begin
            sprite_row = DrawY - lander_top;
            sprite_col = DrawX - lander_left;
        end else begin
            sprite_row = 3'd0;
            sprite_col = 3'd0;
        end

        // Tiny self-contained bitmap sprite.
        // 1 bits are visible pixels; 0 bits are transparent.
        case (sprite_row)
            3'd0: sprite_bits = 8'b00011000;
            3'd1: sprite_bits = 8'b00111100;
            3'd2: sprite_bits = 8'b01111110;
            3'd3: sprite_bits = 8'b11011011;
            3'd4: sprite_bits = 8'b11111111;
            3'd5: sprite_bits = 8'b00111100;
            3'd6: sprite_bits = 8'b01100110;
            3'd7: sprite_bits = 8'b11000011;
            default: sprite_bits = 8'b00000000;
        endcase

        lander_on = lander_bbox_on && sprite_bits[7 - sprite_col];
    end

    always_comb begin : RGB_Display
        if (lander_on) begin
            Red = 4'hF;
            Green = 4'hF;
            Blue = 4'hF;
        end else if (ground_on) begin
            Red = 4'h4;
            Green = 4'h3;
            Blue = 4'h2;
        end else begin
            Red = 4'h0;
            Green = 4'h0;
            Blue = 4'h1;
        end
    end

endmodule
