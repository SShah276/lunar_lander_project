`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/06/2026 05:47:23 PM
// Design Name: 
// Module Name: hud
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// ============================================================
// hud.sv
// Bitmap font HUD renderer — matches Lunar Lander arcade style
//
// Inputs: all game values (pre-scaled by color_mapper)
// Output: hud_on  — 1 if this pixel is a HUD text pixel
//
// Layout (mirrors the reference screenshot):
//
//  TOP-LEFT                      TOP-RIGHT
//  SCORE  XXXX                   ALTITUDE         XXX
//  TIME   X:XX                   HORIZONTAL SPEED  XX
//  FUEL   XXXX                   VERTICAL SPEED    XX
//
//  Pad labels drawn on the terrain ("2X", "4X") are
//  handled separately via pad_text_on.
// ============================================================

module hud (
    input  logic [9:0]  DrawX, DrawY,

    // Game values (caller scales/converts these)
    input  logic [13:0] score_value,     // 0-9999 display value
    input  logic [7:0]  elapsed_seconds, // 0-255 seconds
    input  logic [9:0]  fuel_value,      // 0-1000 display value
    input  logic [9:0]  altitude_value,  // pixels above ground
    input  logic [7:0]  vel_x_scaled,    // 0-99
    input  logic [7:0]  vel_y_scaled,    // 0-99

    output logic        hud_on,
    output logic        pad_text_on
);

    // ============================================================
    // FONT PARAMETERS
    // 5×7 bitmap, rendered 2× scaled ? each char is 10×14px
    // CHAR_W = 6 cols × 2 = 12px  (1px gap between chars)
    // ============================================================
    localparam int FONT_SCALE = 2;
    localparam int FONT_W     = 5;
    localparam int FONT_H     = 7;
    localparam int CHAR_W     = 6 * FONT_SCALE;   // 12px per character cell

    // ============================================================
    // GLYPH ROM  (5-bit rows, MSB = leftmost pixel)
    // ============================================================
    function automatic [4:0] glyph_row(input logic [7:0] ch, input logic [2:0] row);
        begin
            glyph_row = 5'b00000;
            case (ch)
                "0": case (row) 0:glyph_row=5'b01110; 1:glyph_row=5'b10001; 2:glyph_row=5'b10011; 3:glyph_row=5'b10101; 4:glyph_row=5'b11001; 5:glyph_row=5'b10001; 6:glyph_row=5'b01110; endcase
                "1": case (row) 0:glyph_row=5'b00100; 1:glyph_row=5'b01100; 2:glyph_row=5'b00100; 3:glyph_row=5'b00100; 4:glyph_row=5'b00100; 5:glyph_row=5'b00100; 6:glyph_row=5'b01110; endcase
                "2": case (row) 0:glyph_row=5'b01110; 1:glyph_row=5'b10001; 2:glyph_row=5'b00001; 3:glyph_row=5'b00110; 4:glyph_row=5'b01000; 5:glyph_row=5'b10000; 6:glyph_row=5'b11111; endcase
                "3": case (row) 0:glyph_row=5'b11110; 1:glyph_row=5'b00001; 2:glyph_row=5'b00001; 3:glyph_row=5'b01110; 4:glyph_row=5'b00001; 5:glyph_row=5'b00001; 6:glyph_row=5'b11110; endcase
                "4": case (row) 0:glyph_row=5'b00010; 1:glyph_row=5'b00110; 2:glyph_row=5'b01010; 3:glyph_row=5'b10010; 4:glyph_row=5'b11111; 5:glyph_row=5'b00010; 6:glyph_row=5'b00010; endcase
                "5": case (row) 0:glyph_row=5'b11111; 1:glyph_row=5'b10000; 2:glyph_row=5'b10000; 3:glyph_row=5'b11110; 4:glyph_row=5'b00001; 5:glyph_row=5'b00001; 6:glyph_row=5'b11110; endcase
                "6": case (row) 0:glyph_row=5'b01110; 1:glyph_row=5'b10000; 2:glyph_row=5'b10000; 3:glyph_row=5'b11110; 4:glyph_row=5'b10001; 5:glyph_row=5'b10001; 6:glyph_row=5'b01110; endcase
                "7": case (row) 0:glyph_row=5'b11111; 1:glyph_row=5'b00001; 2:glyph_row=5'b00010; 3:glyph_row=5'b00100; 4:glyph_row=5'b01000; 5:glyph_row=5'b01000; 6:glyph_row=5'b01000; endcase
                "8": case (row) 0:glyph_row=5'b01110; 1:glyph_row=5'b10001; 2:glyph_row=5'b10001; 3:glyph_row=5'b01110; 4:glyph_row=5'b10001; 5:glyph_row=5'b10001; 6:glyph_row=5'b01110; endcase
                "9": case (row) 0:glyph_row=5'b01110; 1:glyph_row=5'b10001; 2:glyph_row=5'b10001; 3:glyph_row=5'b01111; 4:glyph_row=5'b00001; 5:glyph_row=5'b00001; 6:glyph_row=5'b01110; endcase
                "A": case (row) 0:glyph_row=5'b01110; 1:glyph_row=5'b10001; 2:glyph_row=5'b10001; 3:glyph_row=5'b11111; 4:glyph_row=5'b10001; 5:glyph_row=5'b10001; 6:glyph_row=5'b10001; endcase
                "C": case (row) 0:glyph_row=5'b01111; 1:glyph_row=5'b10000; 2:glyph_row=5'b10000; 3:glyph_row=5'b10000; 4:glyph_row=5'b10000; 5:glyph_row=5'b10000; 6:glyph_row=5'b01111; endcase
                "D": case (row) 0:glyph_row=5'b11110; 1:glyph_row=5'b10001; 2:glyph_row=5'b10001; 3:glyph_row=5'b10001; 4:glyph_row=5'b10001; 5:glyph_row=5'b10001; 6:glyph_row=5'b11110; endcase
                "E": case (row) 0:glyph_row=5'b11111; 1:glyph_row=5'b10000; 2:glyph_row=5'b10000; 3:glyph_row=5'b11110; 4:glyph_row=5'b10000; 5:glyph_row=5'b10000; 6:glyph_row=5'b11111; endcase
                "F": case (row) 0:glyph_row=5'b11111; 1:glyph_row=5'b10000; 2:glyph_row=5'b10000; 3:glyph_row=5'b11110; 4:glyph_row=5'b10000; 5:glyph_row=5'b10000; 6:glyph_row=5'b10000; endcase
                "G": case (row) 0:glyph_row=5'b01110; 1:glyph_row=5'b10001; 2:glyph_row=5'b10000; 3:glyph_row=5'b10111; 4:glyph_row=5'b10001; 5:glyph_row=5'b10001; 6:glyph_row=5'b01110; endcase
                "H": case (row) 0:glyph_row=5'b10001; 1:glyph_row=5'b10001; 2:glyph_row=5'b10001; 3:glyph_row=5'b11111; 4:glyph_row=5'b10001; 5:glyph_row=5'b10001; 6:glyph_row=5'b10001; endcase
                "I": case (row) 0:glyph_row=5'b11111; 1:glyph_row=5'b00100; 2:glyph_row=5'b00100; 3:glyph_row=5'b00100; 4:glyph_row=5'b00100; 5:glyph_row=5'b00100; 6:glyph_row=5'b11111; endcase
                "L": case (row) 0:glyph_row=5'b10000; 1:glyph_row=5'b10000; 2:glyph_row=5'b10000; 3:glyph_row=5'b10000; 4:glyph_row=5'b10000; 5:glyph_row=5'b10000; 6:glyph_row=5'b11111; endcase
                "M": case (row) 0:glyph_row=5'b10001; 1:glyph_row=5'b11011; 2:glyph_row=5'b10101; 3:glyph_row=5'b10101; 4:glyph_row=5'b10001; 5:glyph_row=5'b10001; 6:glyph_row=5'b10001; endcase
                "N": case (row) 0:glyph_row=5'b10001; 1:glyph_row=5'b11001; 2:glyph_row=5'b10101; 3:glyph_row=5'b10011; 4:glyph_row=5'b10001; 5:glyph_row=5'b10001; 6:glyph_row=5'b10001; endcase
                "O": case (row) 0:glyph_row=5'b01110; 1:glyph_row=5'b10001; 2:glyph_row=5'b10001; 3:glyph_row=5'b10001; 4:glyph_row=5'b10001; 5:glyph_row=5'b10001; 6:glyph_row=5'b01110; endcase
                "P": case (row) 0:glyph_row=5'b11110; 1:glyph_row=5'b10001; 2:glyph_row=5'b10001; 3:glyph_row=5'b11110; 4:glyph_row=5'b10000; 5:glyph_row=5'b10000; 6:glyph_row=5'b10000; endcase
                "R": case (row) 0:glyph_row=5'b11110; 1:glyph_row=5'b10001; 2:glyph_row=5'b10001; 3:glyph_row=5'b11110; 4:glyph_row=5'b10100; 5:glyph_row=5'b10010; 6:glyph_row=5'b10001; endcase
                "S": case (row) 0:glyph_row=5'b01111; 1:glyph_row=5'b10000; 2:glyph_row=5'b10000; 3:glyph_row=5'b01110; 4:glyph_row=5'b00001; 5:glyph_row=5'b00001; 6:glyph_row=5'b11110; endcase
                "T": case (row) 0:glyph_row=5'b11111; 1:glyph_row=5'b00100; 2:glyph_row=5'b00100; 3:glyph_row=5'b00100; 4:glyph_row=5'b00100; 5:glyph_row=5'b00100; 6:glyph_row=5'b00100; endcase
                "U": case (row) 0:glyph_row=5'b10001; 1:glyph_row=5'b10001; 2:glyph_row=5'b10001; 3:glyph_row=5'b10001; 4:glyph_row=5'b10001; 5:glyph_row=5'b10001; 6:glyph_row=5'b01110; endcase
                "V": case (row) 0:glyph_row=5'b10001; 1:glyph_row=5'b10001; 2:glyph_row=5'b10001; 3:glyph_row=5'b10001; 4:glyph_row=5'b10001; 5:glyph_row=5'b01010; 6:glyph_row=5'b00100; endcase
                "X": case (row) 0:glyph_row=5'b10001; 1:glyph_row=5'b01010; 2:glyph_row=5'b00100; 3:glyph_row=5'b00100; 4:glyph_row=5'b00100; 5:glyph_row=5'b01010; 6:glyph_row=5'b10001; endcase
                "Z": case (row) 0:glyph_row=5'b11111; 1:glyph_row=5'b00001; 2:glyph_row=5'b00010; 3:glyph_row=5'b00100; 4:glyph_row=5'b01000; 5:glyph_row=5'b10000; 6:glyph_row=5'b11111; endcase
                ":": case (row) 0:glyph_row=5'b00000; 1:glyph_row=5'b00100; 2:glyph_row=5'b00100; 3:glyph_row=5'b00000; 4:glyph_row=5'b00100; 5:glyph_row=5'b00100; 6:glyph_row=5'b00000; endcase
                " ": glyph_row = 5'b00000;
                default: glyph_row = 5'b00000;
            endcase
        end
    endfunction

    // ============================================================
    // PIXEL TEST — is (dx, dy) within the glyph for ch?
    // dx/dy are pixel offsets from the character's top-left corner.
    // ============================================================
    function automatic logic glyph_pixel(
        input logic [7:0] ch,
        input logic [9:0] dx, dy
    );
        logic [2:0] row, col;
        logic [4:0] bits;
        begin
            glyph_pixel = 1'b0;
            if (dx < FONT_W * FONT_SCALE && dy < FONT_H * FONT_SCALE) begin
                row  = dy[3:1];          // divide by 2 (scale factor)
                col  = dx[3:1];
                bits = glyph_row(ch, row);
                glyph_pixel = bits[FONT_W - 1 - col];
            end
        end
    endfunction

    // ============================================================
    // LABEL RENDERER
    // Draws a string at screen position (ox, oy).
    // label selects which string; len = character count.
    //
    // label IDs:
    //   0 = "SCORE"          (5 chars)
    //   1 = "TIME"           (4 chars)
    //   2 = "FUEL"           (4 chars)
    //   3 = "ALTITUDE"       (8 chars)
    //   4 = "HORIZONTAL SPEED" (16 chars)
    //   5 = "VERTICAL SPEED"  (14 chars)
    // ============================================================
    function automatic [7:0] label_char(
        input logic [2:0] label,
        input logic [4:0] idx
    );
        begin
            label_char = " ";
            case (label)
                3'd0: case (idx) 0:label_char="S"; 1:label_char="C"; 2:label_char="O"; 3:label_char="R"; 4:label_char="E"; default:label_char=" "; endcase
                3'd1: case (idx) 0:label_char="T"; 1:label_char="I"; 2:label_char="M"; 3:label_char="E"; default:label_char=" "; endcase
                3'd2: case (idx) 0:label_char="F"; 1:label_char="U"; 2:label_char="E"; 3:label_char="L"; default:label_char=" "; endcase
                3'd3: case (idx) 0:label_char="A"; 1:label_char="L"; 2:label_char="T"; 3:label_char="I"; 4:label_char="T"; 5:label_char="U"; 6:label_char="D"; 7:label_char="E"; default:label_char=" "; endcase
                3'd4: case (idx) 0:label_char="H"; 1:label_char="O"; 2:label_char="R"; 3:label_char="I"; 4:label_char="Z"; 5:label_char="O"; 6:label_char="N"; 7:label_char="T"; 8:label_char="A"; 9:label_char="L"; 10:label_char=" "; 11:label_char="S"; 12:label_char="P"; 13:label_char="E"; 14:label_char="E"; 15:label_char="D"; default:label_char=" "; endcase
                3'd5: case (idx) 0:label_char="V"; 1:label_char="E"; 2:label_char="R"; 3:label_char="T"; 4:label_char="I"; 5:label_char="C"; 6:label_char="A"; 7:label_char="L"; 8:label_char=" "; 9:label_char="S"; 10:label_char="P"; 11:label_char="E"; 12:label_char="E"; 13:label_char="D"; default:label_char=" "; endcase
                default: label_char = " ";
            endcase
        end
    endfunction

    function automatic logic label_on(
        input logic [9:0] x, y, ox, oy,
        input logic [2:0] label,
        input logic [4:0] len
    );
        logic [9:0] dx, dy;
        logic [4:0] idx;
        begin
            dx = x - ox;
            dy = y - oy;
            idx = dx / CHAR_W;
            label_on = (x >= ox) && (y >= oy) &&
                       (idx < len) && (dy < FONT_H * FONT_SCALE) &&
                       glyph_pixel(label_char(label, idx), dx - idx * CHAR_W, dy);
        end
    endfunction

    // ============================================================
    // NUMBER RENDERER
    // Draws a right-aligned decimal number at (ox, oy).
    // `digits` = total digit columns to render.
    // ============================================================
    function automatic logic number_on(
        input logic [9:0] x, y, ox, oy,
        input logic [13:0] value,
        input logic [2:0] digits
    );
        logic [9:0] dx, dy;
        logic [2:0] idx;
        logic [3:0] d;
        begin
            dx  = x - ox;
            dy  = y - oy;
            idx = dx / CHAR_W;
            case (digits - idx)
                3'd4: d = (value / 14'd1000) % 14'd10;
                3'd3: d = (value / 14'd100)  % 14'd10;
                3'd2: d = (value / 14'd10)   % 14'd10;
                default: d = value % 14'd10;
            endcase
            number_on = (x >= ox) && (y >= oy) &&
                        (idx < digits) && (dy < FONT_H * FONT_SCALE) &&
                        glyph_pixel("0" + d, dx - idx * CHAR_W, dy);
        end
    endfunction

    // ============================================================
    // PAD MULTIPLIER TEXT  ("2X" or "4X")
    // These labels float just above each landing pad
    // ============================================================
    function automatic logic padtext_on(
        input logic [9:0] x, y, ox, oy,
        input logic [7:0] ch0         // first char: "2" or "4"
    );
        logic [9:0] dx, dy;
        logic [1:0] idx;
        logic [7:0] ch;
        begin
            dx  = x - ox;
            dy  = y - oy;
            idx = dx / CHAR_W;
            ch  = (idx == 2'd0) ? ch0 : "X";
            padtext_on = (x >= ox) && (y >= oy) && (idx < 2) &&
                         (dy < FONT_H * FONT_SCALE) &&
                         glyph_pixel(ch, dx - idx * CHAR_W, dy);
        end
    endfunction

    // ============================================================
    // HUD PIXEL LOGIC
    // All positions match the reference screenshot layout.
    //
    //  Top-left  column:  x=20   labels,  x=118/146/118 numbers
    //  Top-right column:  x=410  labels,  x=590/606/606 numbers
    //  Row Y offsets: 38 / 58 / 78  (3 rows, 20px spacing)
    //
    //  Pad labels:
    //    "2X" at (  8, 456) — easy bottom-left pad
    //    "4X" at (148, 330) — easy mid pad
    //    "2X" at (368, 456) — hard bottom-right pad
    //    "4X" at (585, 330) — hard mid pad
    //
    // ============================================================
    logic [7:0] time_minutes;
    logic [7:0] time_seconds_part;

    assign time_minutes = elapsed_seconds / 8'd60;
    assign time_seconds_part = elapsed_seconds % 8'd60;

    always_comb begin
        hud_on =
            // ---- TOP-LEFT ----
            label_on (DrawX, DrawY, 10'd20,  10'd38, 3'd0, 5'd5)   ||   // SCORE
            number_on(DrawX, DrawY, 10'd118, 10'd38, score_value, 3'd4) ||
            label_on (DrawX, DrawY, 10'd20,  10'd58, 3'd1, 5'd4)   ||   // TIME
            number_on(DrawX, DrawY, 10'd118, 10'd58, {6'b0, time_minutes}, 3'd1) ||
            glyph_pixel(":",  DrawX - 10'd132, DrawY - 10'd58)     ||
            number_on(DrawX, DrawY, 10'd146, 10'd58, {6'b0, time_seconds_part}, 3'd2) ||
            label_on (DrawX, DrawY, 10'd20,  10'd78, 3'd2, 5'd4)   ||   // FUEL
            number_on(DrawX, DrawY, 10'd118, 10'd78, fuel_value, 3'd4)  ||   // fuel 0-1000

            // ---- TOP-RIGHT ----
            label_on (DrawX, DrawY, 10'd410, 10'd38, 3'd3, 5'd8)   ||   // ALTITUDE
            number_on(DrawX, DrawY, 10'd590, 10'd38, altitude_value, 3'd3) ||
            label_on (DrawX, DrawY, 10'd410, 10'd58, 3'd4, 5'd16)  ||   // HORIZONTAL SPEED
            number_on(DrawX, DrawY, 10'd606, 10'd58, {2'b00, vel_x_scaled}, 3'd2) ||
            label_on (DrawX, DrawY, 10'd410, 10'd78, 3'd5, 5'd14)  ||   // VERTICAL SPEED
            number_on(DrawX, DrawY, 10'd606, 10'd78, {2'b00, vel_y_scaled}, 3'd2);

        // Pad multiplier labels, drawn near each pad surface
        pad_text_on =
            padtext_on(DrawX, DrawY, 10'd8,   10'd456, "2") ||   // easy bottom-left
            padtext_on(DrawX, DrawY, 10'd148, 10'd330, "4") ||   // easy mid
            padtext_on(DrawX, DrawY, 10'd368, 10'd456, "2") ||   // hard bottom-right
            padtext_on(DrawX, DrawY, 10'd585, 10'd330, "4");     // hard mid
    end

endmodule
