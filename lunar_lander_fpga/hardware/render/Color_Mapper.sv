//-------------------------------------------------------------------------
//    Color_Mapper.sv                                                    --
//                                                                       --
//    Lunar Lander renderer. Software owns game state; hardware converts --
//    exported state into terrain, sprite, and HUD pixels.               --
//-------------------------------------------------------------------------

module color_mapper (
    input  logic [9:0] lander_x,
    input  logic [9:0] lander_y,
    input  logic [1:0] angle_idx,
    input  logic       thrust_active,
    input  logic [7:0] fuel_scaled,
    input  logic [7:0] vel_y_scaled,
    input  logic [7:0] vel_x_scaled,
    input  logic [9:0] DrawX,
    input  logic [9:0] DrawY,
    output logic [3:0] Red,
    output logic [3:0] Green,
    output logic [3:0] Blue
);

    localparam logic [9:0] SEG_W = 10'd32;
    localparam logic [9:0] HUD_X = 10'd5;
    localparam logic [9:0] HUD_FUEL_Y = 10'd5;
    localparam logic [9:0] HUD_VY_Y = 10'd30;
    localparam logic [9:0] HUD_VX_Y = 10'd55;
    localparam logic [9:0] HUD_BAR_W = 10'd200;
    localparam logic [9:0] HUD_BAR_H = 10'd20;
    localparam logic [9:0] HUD_DANGER_X = HUD_X + 10'd80;

    logic sprite_on;
    logic [3:0] sprite_red;
    logic [3:0] sprite_green;
    logic [3:0] sprite_blue;

    logic [9:0] terrain_y;
    logic terrain_on;
    logic terrain_edge_on;
    logic hud_on;
    logic [3:0] hud_red;
    logic [3:0] hud_green;
    logic [3:0] hud_blue;

    function automatic logic [9:0] terrain_point(input logic [4:0] seg);
        begin
            case (seg)
                5'd0:  terrain_point = 10'd380;
                5'd1:  terrain_point = 10'd390;
                5'd2:  terrain_point = 10'd410;
                5'd3:  terrain_point = 10'd430;
                5'd4:  terrain_point = 10'd430;
                5'd5:  terrain_point = 10'd405;
                5'd6:  terrain_point = 10'd380;
                5'd7:  terrain_point = 10'd360;
                5'd8:  terrain_point = 10'd360;
                5'd9:  terrain_point = 10'd360;
                5'd10: terrain_point = 10'd380;
                5'd11: terrain_point = 10'd405;
                5'd12: terrain_point = 10'd430;
                5'd13: terrain_point = 10'd420;
                5'd14: terrain_point = 10'd390;
                5'd15: terrain_point = 10'd370;
                5'd16: terrain_point = 10'd370;
                5'd17: terrain_point = 10'd400;
                5'd18: terrain_point = 10'd430;
                5'd19: terrain_point = 10'd450;
                default: terrain_point = 10'd450;
            endcase
        end
    endfunction

    function automatic logic [9:0] terrain_y_at_x(input logic [9:0] x);
        logic [4:0] seg;
        logic [9:0] x_offset;
        logic [9:0] y0;
        logic [9:0] y1;
        logic signed [10:0] dy;
        logic signed [20:0] interp;
        begin
            seg = x / SEG_W;
            if (seg >= 5'd19) begin
                terrain_y_at_x = terrain_point(5'd19);
            end else begin
                x_offset = x - (seg * SEG_W);
                y0 = terrain_point(seg);
                y1 = terrain_point(seg + 5'd1);
                dy = $signed({1'b0, y1}) - $signed({1'b0, y0});
                interp = $signed({1'b0, y0}) + ((dy * $signed({1'b0, x_offset})) / $signed({1'b0, SEG_W}));
                terrain_y_at_x = interp[9:0];
            end
        end
    endfunction

    function automatic logic in_bar(input logic [9:0] y_top);
        begin
            in_bar = (DrawX >= HUD_X) &&
                     (DrawX < HUD_X + HUD_BAR_W) &&
                     (DrawY >= y_top) &&
                     (DrawY < y_top + HUD_BAR_H);
        end
    endfunction

    function automatic logic bar_filled(input logic [7:0] value);
        logic [17:0] filled_w;
        begin
            filled_w = value * HUD_BAR_W;
            bar_filled = (value == 8'hFF) ||
                         ((DrawX - HUD_X) < (filled_w / 18'd255));
        end
    endfunction

    lander_sprite lander_sprite_i (
        .BallX(lander_x),
        .BallY(lander_y),
        .DrawX(DrawX),
        .DrawY(DrawY),
        .angle_idx(angle_idx),
        .thrust_active(thrust_active),
        .sprite_on(sprite_on),
        .sprite_red(sprite_red),
        .sprite_green(sprite_green),
        .sprite_blue(sprite_blue)
    );

    always_comb begin
        terrain_y = terrain_y_at_x(DrawX);
        terrain_on = DrawY >= terrain_y;
        terrain_edge_on = (DrawY >= terrain_y) && (DrawY < terrain_y + 10'd2);

        hud_on = 1'b0;
        hud_red = 4'h0;
        hud_green = 4'h0;
        hud_blue = 4'h0;

        if (in_bar(HUD_FUEL_Y)) begin
            hud_on = 1'b1;
            if (DrawX == HUD_DANGER_X) begin
                hud_red = 4'hF;
                hud_green = 4'hF;
                hud_blue = 4'hF;
            end else if (bar_filled(fuel_scaled)) begin
                hud_red = 4'hF - fuel_scaled[7:4];
                hud_green = fuel_scaled[7:4];
                hud_blue = 4'h1;
            end else begin
                hud_red = 4'h2;
                hud_green = 4'h2;
                hud_blue = 4'h2;
            end
        end else if (in_bar(HUD_VY_Y)) begin
            hud_on = 1'b1;
            if (DrawX == HUD_DANGER_X) begin
                hud_red = 4'hF;
                hud_green = 4'hF;
                hud_blue = 4'hF;
            end else if (bar_filled(vel_y_scaled)) begin
                hud_red = vel_y_scaled[7:4];
                hud_green = 4'h2;
                hud_blue = 4'hF - vel_y_scaled[7:4];
            end else begin
                hud_red = 4'h2;
                hud_green = 4'h2;
                hud_blue = 4'h2;
            end
        end else if (in_bar(HUD_VX_Y)) begin
            hud_on = 1'b1;
            if (DrawX == HUD_DANGER_X) begin
                hud_red = 4'hF;
                hud_green = 4'hF;
                hud_blue = 4'hF;
            end else if (bar_filled(vel_x_scaled)) begin
                hud_red = vel_x_scaled[7:4];
                hud_green = vel_x_scaled[6:3];
                hud_blue = 4'hF - vel_x_scaled[7:4];
            end else begin
                hud_red = 4'h2;
                hud_green = 4'h2;
                hud_blue = 4'h2;
            end
        end
    end

    always_comb begin : RGB_Display
        if (hud_on) begin
            Red = hud_red;
            Green = hud_green;
            Blue = hud_blue;
        end else if (sprite_on) begin
            Red = sprite_red;
            Green = sprite_green;
            Blue = sprite_blue;
        end else if (terrain_edge_on) begin
            Red = 4'h9;
            Green = 4'h8;
            Blue = 4'h6;
        end else if (terrain_on) begin
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
