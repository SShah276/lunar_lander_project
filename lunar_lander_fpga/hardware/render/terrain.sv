`timescale 1ns / 1ps

module terrain (
    input  logic [9:0] DrawX,
    input  logic [9:0] DrawY,
    input  logic [9:0] BallX,
    input  logic [9:0] BallY,

    output logic [9:0] terrain_y_at_x,
    output logic [9:0] lander_ground_y,
    output logic [9:0] altitude_value,
    output logic       on_pad,
    output logic       terrain_line_on,
    output logic       terrain_glow_on
);

    // Control points match software/src/terrain.c.
    function automatic signed [10:0] terrain_point_y(input logic [4:0] seg);
        case (seg)
            5'd0:  terrain_point_y = 11'sd448;
            5'd1:  terrain_point_y = 11'sd448;   // PAD easy-left
            5'd2:  terrain_point_y = 11'sd368;
            5'd3:  terrain_point_y = 11'sd338;
            5'd4:  terrain_point_y = 11'sd398;
            5'd5:  terrain_point_y = 11'sd350;   // PAD easy-mid start
            5'd6:  terrain_point_y = 11'sd350;   // PAD easy-mid end
            5'd7:  terrain_point_y = 11'sd424;
            5'd8:  terrain_point_y = 11'sd406;
            5'd9:  terrain_point_y = 11'sd332;
            5'd10: terrain_point_y = 11'sd238;
            5'd11: terrain_point_y = 11'sd252;
            5'd12: terrain_point_y = 11'sd336;
            5'd13: terrain_point_y = 11'sd426;
            5'd14: terrain_point_y = 11'sd448;   // PAD hard-right start
            5'd15: terrain_point_y = 11'sd448;   // PAD hard-right end
            5'd16: terrain_point_y = 11'sd366;
            5'd17: terrain_point_y = 11'sd304;
            5'd18: terrain_point_y = 11'sd340;   // PAD hard-mid start
            5'd19: terrain_point_y = 11'sd340;   // PAD hard-mid end
            default: terrain_point_y = 11'sd448;
        endcase
    endfunction

    function automatic [9:0] get_terrain_y(input logic [9:0] x);
        logic [4:0]  seg, next_seg, frac;
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
            seg    = x[9:5];
            is_pad = (seg == 5'd1)                      ||   // easy bottom-left
                     (seg >= 5'd5  && seg <= 5'd6)      ||   // easy mid
                     (seg >= 5'd14 && seg <= 5'd15)     ||   // hard bottom-right
                     (seg >= 5'd18 && seg <= 5'd19);         // hard mid-right
        end
    endfunction

    logic [9:0] ty;   // terrain Y at DrawX (internal)

    always_comb begin
        ty              = get_terrain_y(DrawX);
        terrain_y_at_x  = ty;
        lander_ground_y = get_terrain_y(BallX);
        altitude_value  = (BallY < lander_ground_y) ? (lander_ground_y - BallY) : 10'd0;
        on_pad          = is_pad(DrawX);

        terrain_line_on = (DrawY >= ty - 10'd1) && (DrawY <= ty + 10'd1);
        terrain_glow_on = !terrain_line_on &&
                          (DrawY >= ty - 10'd3) && (DrawY <= ty + 10'd3);
    end

endmodule
