module color_mapper (
    input  logic [9:0]  BallX, BallY,
    input  logic [9:0]  DrawX, DrawY,
    input  logic [9:0]  Ball_size,
    // [31:30] = game_state  [29] = thrust  [28:22] = angle + 45
    // [21:14] = fuel 0-255  [13:6] = vel_y 0-255  [5:0] = vel_x 0-63
    input  logic [31:0] status_word,
    output logic [3:0]  Red, Green, Blue
);

    logic [1:0] game_state;
    logic       thrust_active;
    logic [6:0] angle_shifted;
    logic [7:0] fuel_scaled;
    logic [7:0] vel_y_scaled;
    logic [7:0] vel_x_scaled;

    assign game_state    = status_word[31:30];
    assign thrust_active = status_word[29];
    assign angle_shifted = status_word[28:22];
    assign fuel_scaled   = status_word[21:14];
    assign vel_y_scaled  = status_word[13:6];
    assign vel_x_scaled  = {2'b00, status_word[5:0]};

    // ============================================================
    // VECTOR TERRAIN
    // Matches software/src/terrain.c control points.
    // ============================================================
    function automatic signed [10:0] terrain_point_y(input logic [4:0] seg);
        case (seg)
            5'd0:  terrain_point_y = 11'sd448;
            5'd1:  terrain_point_y = 11'sd448;
            5'd2:  terrain_point_y = 11'sd368;
            5'd3:  terrain_point_y = 11'sd338;
            5'd4:  terrain_point_y = 11'sd398;
            5'd5:  terrain_point_y = 11'sd350;
            5'd6:  terrain_point_y = 11'sd350;
            5'd7:  terrain_point_y = 11'sd424;
            5'd8:  terrain_point_y = 11'sd406;
            5'd9:  terrain_point_y = 11'sd332;
            5'd10: terrain_point_y = 11'sd238;
            5'd11: terrain_point_y = 11'sd252;
            5'd12: terrain_point_y = 11'sd336;
            5'd13: terrain_point_y = 11'sd426;
            5'd14: terrain_point_y = 11'sd448;
            5'd15: terrain_point_y = 11'sd448;
            5'd16: terrain_point_y = 11'sd366;
            5'd17: terrain_point_y = 11'sd304;
            5'd18: terrain_point_y = 11'sd340;
            5'd19: terrain_point_y = 11'sd340;
            default: terrain_point_y = 11'sd448;
        endcase
    endfunction

    function automatic [9:0] get_terrain_y(input logic [9:0] x);
        logic [4:0] seg;
        logic [4:0] next_seg;
        logic [4:0] frac;
        logic signed [10:0] y0, y1;
        logic signed [15:0] interp;
        begin
            seg      = x[9:5];
            next_seg = (seg == 5'd19) ? 5'd19 : (seg + 5'd1);
            frac     = x[4:0];
            y0       = terrain_point_y(seg);
            y1       = terrain_point_y(next_seg);
            interp   = y0 + (((y1 - y0) * $signed({1'b0, frac})) >>> 5);
            get_terrain_y = interp[9:0];
        end
    endfunction

    function automatic logic is_pad(input logic [9:0] x);
        logic [4:0] seg;
        begin
            seg = x[9:5];
            is_pad = (seg >= 5'd1  && seg <= 5'd1)  ||
                     (seg >= 5'd5  && seg <= 5'd6)  ||
                     (seg >= 5'd14 && seg <= 5'd15) ||
                     (seg >= 5'd18 && seg <= 5'd19);
        end
    endfunction

    logic [9:0] terrain_y_at_x;
    logic [9:0] lander_ground_y;
    logic [9:0] altitude_value;
    logic       on_pad;
    logic       terrain_line_on;
    logic       terrain_glow_on;

    assign terrain_y_at_x  = get_terrain_y(DrawX);
    assign lander_ground_y = get_terrain_y(BallX);
    assign altitude_value  = (BallY < lander_ground_y) ? (lander_ground_y - BallY) : 10'd0;
    assign on_pad          = is_pad(DrawX);
    assign terrain_line_on = (DrawY >= terrain_y_at_x - 10'd1) &&
                             (DrawY <= terrain_y_at_x + 10'd1);
    assign terrain_glow_on = !terrain_line_on &&
                             (DrawY >= terrain_y_at_x - 10'd3) &&
                             (DrawY <= terrain_y_at_x + 10'd3);

    // ============================================================
    // SPARSE STAR FIELD
    // ============================================================
    logic star_on;
    always_comb begin
        star_on = 1'b0;
        if ((DrawX == 10'd25  && DrawY == 10'd116) ||
            (DrawX == 10'd83  && DrawY == 10'd70)  ||
            (DrawX == 10'd102 && DrawY == 10'd245) ||
            (DrawX == 10'd166 && DrawY == 10'd368) ||
            (DrawX == 10'd244 && DrawY == 10'd137) ||
            (DrawX == 10'd296 && DrawY == 10'd29)  ||
            (DrawX == 10'd346 && DrawY == 10'd267) ||
            (DrawX == 10'd426 && DrawY == 10'd52)  ||
            (DrawX == 10'd470 && DrawY == 10'd122) ||
            (DrawX == 10'd530 && DrawY == 10'd272) ||
            (DrawX == 10'd565 && DrawY == 10'd156) ||
            (DrawX == 10'd615 && DrawY == 10'd28)) begin
            star_on = 1'b1;
        end
    end

    // ============================================================
    // THIN PIXEL FONT
    // ============================================================
    localparam int FONT_SCALE = 2;
    localparam int FONT_W     = 5;
    localparam int FONT_H     = 7;
    localparam int CHAR_W     = 6 * FONT_SCALE;

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
                "Z": case (row) 0:glyph_row=5'b11111; 1:glyph_row=5'b00001; 2:glyph_row=5'b00010; 3:glyph_row=5'b00100; 4:glyph_row=5'b01000; 5:glyph_row=5'b10000; 6:glyph_row=5'b11111; endcase
                "X": case (row) 0:glyph_row=5'b10001; 1:glyph_row=5'b01010; 2:glyph_row=5'b00100; 3:glyph_row=5'b00100; 4:glyph_row=5'b00100; 5:glyph_row=5'b01010; 6:glyph_row=5'b10001; endcase
                ":": case (row) 0:glyph_row=5'b00000; 1:glyph_row=5'b00100; 2:glyph_row=5'b00100; 3:glyph_row=5'b00000; 4:glyph_row=5'b00100; 5:glyph_row=5'b00100; 6:glyph_row=5'b00000; endcase
                default: glyph_row = 5'b00000;
            endcase
        end
    endfunction

    function automatic logic glyph_pixel(input logic [7:0] ch, input logic [9:0] dx, input logic [9:0] dy);
        logic [2:0] row;
        logic [2:0] col;
        logic [4:0] bits;
        begin
            glyph_pixel = 1'b0;
            row = dy[3:1];
            col = dx[3:1];
            if ((dx < FONT_W * FONT_SCALE) && (dy < FONT_H * FONT_SCALE)) begin
                bits = glyph_row(ch, row);
                glyph_pixel = bits[FONT_W - 1 - col];
            end
        end
    endfunction

    function automatic logic [7:0] label_char(input logic [2:0] label, input logic [4:0] idx);
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
        input logic [9:0] x, input logic [9:0] y,
        input logic [9:0] ox, input logic [9:0] oy,
        input logic [2:0] label, input logic [4:0] len
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

    function automatic logic [7:0] digit_char(input logic [3:0] digit);
        begin
            digit_char = "0" + digit;
        end
    endfunction

    function automatic logic number_on(
        input logic [9:0] x, input logic [9:0] y,
        input logic [9:0] ox, input logic [9:0] oy,
        input logic [9:0] value, input logic [2:0] digits
    );
        logic [9:0] dx, dy;
        logic [2:0] idx;
        logic [3:0] d;
        begin
            dx = x - ox;
            dy = y - oy;
            idx = dx / CHAR_W;
            case (digits - idx)
                3'd4: d = (value / 10'd1000) % 10'd10;
                3'd3: d = (value / 10'd100)  % 10'd10;
                3'd2: d = (value / 10'd10)   % 10'd10;
                default: d = value % 10'd10;
            endcase
            number_on = (x >= ox) && (y >= oy) &&
                        (idx < digits) && (dy < FONT_H * FONT_SCALE) &&
                        glyph_pixel(digit_char(d), dx - idx * CHAR_W, dy);
        end
    endfunction

    function automatic logic text_2x_on(input logic [9:0] x, input logic [9:0] y, input logic [9:0] ox, input logic [9:0] oy);
        logic [9:0] dx, dy;
        logic [7:0] ch;
        logic [1:0] idx;
        begin
            dx = x - ox;
            dy = y - oy;
            idx = dx / CHAR_W;
            ch = (idx == 2'd0) ? "2" : "X";
            text_2x_on = (x >= ox) && (y >= oy) && (idx < 2) &&
                         (dy < FONT_H * FONT_SCALE) &&
                         glyph_pixel(ch, dx - idx * CHAR_W, dy);
        end
    endfunction

    function automatic logic text_4x_on(input logic [9:0] x, input logic [9:0] y, input logic [9:0] ox, input logic [9:0] oy);
        logic [9:0] dx, dy;
        logic [7:0] ch;
        logic [1:0] idx;
        begin
            dx = x - ox;
            dy = y - oy;
            idx = dx / CHAR_W;
            ch = (idx == 2'd0) ? "4" : "X";
            text_4x_on = (x >= ox) && (y >= oy) && (idx < 2) &&
                         (dy < FONT_H * FONT_SCALE) &&
                         glyph_pixel(ch, dx - idx * CHAR_W, dy);
        end
    endfunction

    logic hud_text_on;
    logic pad_text_on;
    logic [9:0] fuel_value;
    assign fuel_value = ({2'b00, fuel_scaled} * 10'd1000) >> 8;

    always_comb begin
        hud_text_on =
            label_on(DrawX, DrawY, 10'd20,  10'd38, 3'd0, 5'd5)  ||
            number_on(DrawX, DrawY, 10'd118, 10'd38, 10'd0, 3'd4) ||
            label_on(DrawX, DrawY, 10'd20,  10'd58, 3'd1, 5'd4)  ||
            glyph_pixel("0", DrawX - 10'd118, DrawY - 10'd58)     ||
            glyph_pixel(":", DrawX - 10'd132, DrawY - 10'd58)     ||
            number_on(DrawX, DrawY, 10'd146, 10'd58, 10'd3, 3'd2) ||
            label_on(DrawX, DrawY, 10'd20,  10'd78, 3'd2, 5'd4)  ||
            number_on(DrawX, DrawY, 10'd118, 10'd78, fuel_value, 3'd4) ||
            label_on(DrawX, DrawY, 10'd410, 10'd38, 3'd3, 5'd8)  ||
            number_on(DrawX, DrawY, 10'd590, 10'd38, altitude_value, 3'd3) ||
            label_on(DrawX, DrawY, 10'd410, 10'd58, 3'd4, 5'd16) ||
            number_on(DrawX, DrawY, 10'd606, 10'd58, {2'b00, vel_x_scaled}, 3'd2) ||
            label_on(DrawX, DrawY, 10'd410, 10'd78, 3'd5, 5'd14) ||
            number_on(DrawX, DrawY, 10'd606, 10'd78, {2'b00, vel_y_scaled}, 3'd2);

        pad_text_on =
            text_2x_on(DrawX, DrawY, 10'd8,   10'd456) ||
            text_4x_on(DrawX, DrawY, 10'd148, 10'd330) ||
            text_2x_on(DrawX, DrawY, 10'd368, 10'd456) ||
            text_4x_on(DrawX, DrawY, 10'd585, 10'd330);
    end

    // ============================================================
    // SPRITE
    // ============================================================
    logic       sprite_on;
    logic [3:0] sprite_r, sprite_g, sprite_b;

    lander_sprite sprite_inst (
        .BallX(BallX),
        .BallY(BallY),
        .DrawX(DrawX),
        .DrawY(DrawY),
        .sprite_on(sprite_on),
        .sprite_red(sprite_r),
        .sprite_green(sprite_g),
        .sprite_blue(sprite_b),
        .thrust_active(thrust_active),
        .angle_shifted(angle_shifted)
    );

    always_comb begin
        Red   = 4'h0;
        Green = 4'h0;
        Blue  = 4'h0;

        if (star_on) begin
            Red   = 4'hC;
            Green = 4'hC;
            Blue  = 4'hC;
        end

        if (terrain_glow_on) begin
            Red   = 4'h3;
            Green = 4'h3;
            Blue  = 4'h3;
        end

        if (terrain_line_on) begin
            Red   = on_pad ? 4'hF : 4'h9;
            Green = on_pad ? 4'hF : 4'h9;
            Blue  = on_pad ? 4'hF : 4'h9;
        end

        if (pad_text_on || hud_text_on) begin
            Red   = 4'hD;
            Green = 4'hD;
            Blue  = 4'hD;
        end

        if (sprite_on) begin
            Red   = sprite_r;
            Green = sprite_g;
            Blue  = sprite_b;
        end

        if (game_state == 2'b10 && DrawY < 10'd4) begin
            Red = 4'hF; Green = 4'h0; Blue = 4'h0;
        end
        if (game_state == 2'b01 && DrawY < 10'd4) begin
            Red = 4'h0; Green = 4'hF; Blue = 4'h0;
        end
    end

endmodule
