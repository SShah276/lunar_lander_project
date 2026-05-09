`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/06/2026 05:46:24 PM
// Design Name: 
// Module Name: terrain
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
// terrain.sv
// Terrain geometry: interpolated height + landing pad detection
// Instantiate this in color_mapper.sv
//
// Outputs (combinational, per draw pixel):
//   terrain_y_at_x   — interpolated terrain Y at DrawX
//   lander_ground_y  — terrain Y directly below lander (BallX)
//   altitude_value   — pixel distance lander is above ground
//   on_pad           — DrawX is over a landing pad segment
//   terrain_line_on  — DrawX/DrawY is on the surface line (±1px)
//   terrain_glow_on  — DrawX/DrawY is in the glow halo (±3px, not line)
// ============================================================

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

    // ============================================================
    // CONTROL POINTS
    // 20 segments × 32px = 640px wide screen
    // Must stay in sync with software/src/terrain.c
    //
    // Pad segments (flat regions):
    //   seg 1        ? easy pad   (Y=448, bottom left)
    //   segs 5–6     ? easy pad   (Y=350, mid-left)
    //   segs 14–15   ? hard pad   (Y=448, bottom right)
    //   segs 18–19   ? hard pad   (Y=340, mid-right)
    // ============================================================
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

    // ============================================================
    // LINEAR INTERPOLATION between adjacent control points
    // frac = low 5 bits of x = position within the 32px segment
    // ============================================================
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

    // ============================================================
    // PAD DETECTION — flat segments only
    // ============================================================
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

    // ============================================================
    // COMBINATIONAL OUTPUTS
    // ============================================================
    logic [9:0] ty;   // terrain Y at DrawX (internal)

    always_comb begin
        ty              = get_terrain_y(DrawX);
        terrain_y_at_x  = ty;
        lander_ground_y = get_terrain_y(BallX);
        altitude_value  = (BallY < lander_ground_y) ? (lander_ground_y - BallY) : 10'd0;
        on_pad          = is_pad(DrawX);

        // Surface line  = ±1 pixel around terrain height
        terrain_line_on = (DrawY >= ty - 10'd1) && (DrawY <= ty + 10'd1);

        // Glow halo = ±3px, excluding the solid line
        terrain_glow_on = !terrain_line_on &&
                          (DrawY >= ty - 10'd3) && (DrawY <= ty + 10'd3);
    end

endmodule
