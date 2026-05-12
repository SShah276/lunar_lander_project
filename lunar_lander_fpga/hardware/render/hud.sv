`timescale 1ns / 1ps

module hud (
    input  logic [9:0]  DrawX, DrawY,

    // Game values 
    input  logic [13:0] score_value,     
    input  logic [7:0]  elapsed_seconds, 
    input  logic [9:0]  fuel_value,     
    input  logic [9:0]  altitude_value,  
    input  logic [7:0]  vel_x_scaled,    
    input  logic [7:0]  vel_y_scaled,    

    output logic        hud_on,
    output logic        pad_text_on
);

    localparam int FONT_SCALE = 2;
    localparam int FONT_W     = 5;
    localparam int FONT_H     = 7;
    localparam int CHAR_W     = 6 * FONT_SCALE;   // 12px per character cell

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

    function automatic logic glyph_pixel(
        input logic [7:0] ch,
        input logic [9:0] dx, dy
    );
        logic [2:0] row, col;
        logic [4:0] bits;
        begin
            glyph_pixel = 1'b0;
            if (dx < FONT_W * FONT_SCALE && dy < FONT_H * FONT_SCALE) begin
                row  = dy[3:1];         
                col  = dx[3:1];
                bits = glyph_row(ch, row);
                glyph_pixel = bits[FONT_W - 1 - col];
            end
        end
    endfunction

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

    function automatic logic padtext_on(
        input logic [9:0] x, y, ox, oy,
        input logic [7:0] ch0        
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

    logic [7:0] time_minutes;
    logic [7:0] time_seconds_part;

    assign time_minutes = elapsed_seconds / 8'd60;
    assign time_seconds_part = elapsed_seconds % 8'd60;

    always_comb begin
        hud_on =
            label_on (DrawX, DrawY, 10'd20,  10'd38, 3'd0, 5'd5)   ||   // score
            number_on(DrawX, DrawY, 10'd118, 10'd38, score_value, 3'd4) ||
            label_on (DrawX, DrawY, 10'd20,  10'd58, 3'd1, 5'd4)   ||   // time
            number_on(DrawX, DrawY, 10'd118, 10'd58, {6'b0, time_minutes}, 3'd1) ||
            glyph_pixel(":",  DrawX - 10'd132, DrawY - 10'd58)     ||
            number_on(DrawX, DrawY, 10'd146, 10'd58, {6'b0, time_seconds_part}, 3'd2) ||
            label_on (DrawX, DrawY, 10'd20,  10'd78, 3'd2, 5'd4)   ||   // fuel
            number_on(DrawX, DrawY, 10'd118, 10'd78, fuel_value, 3'd4)  ||   // fuel 0-1000

            label_on (DrawX, DrawY, 10'd410, 10'd38, 3'd3, 5'd8)   ||   // altitude
            number_on(DrawX, DrawY, 10'd590, 10'd38, altitude_value, 3'd3) ||
            label_on (DrawX, DrawY, 10'd410, 10'd58, 3'd4, 5'd16)  ||   // horzi speed
            number_on(DrawX, DrawY, 10'd606, 10'd58, {2'b00, vel_x_scaled}, 3'd2) ||
            label_on (DrawX, DrawY, 10'd410, 10'd78, 3'd5, 5'd14)  ||   // vert speed
            number_on(DrawX, DrawY, 10'd606, 10'd78, {2'b00, vel_y_scaled}, 3'd2);

        pad_text_on =
            padtext_on(DrawX, DrawY, 10'd8,   10'd456, "2") ||   // easy bottom left
            padtext_on(DrawX, DrawY, 10'd148, 10'd330, "4") ||   // easy mid
            padtext_on(DrawX, DrawY, 10'd368, 10'd456, "2") ||   // hard bottom right
            padtext_on(DrawX, DrawY, 10'd585, 10'd330, "4");     // hard mid
    end

endmodule
