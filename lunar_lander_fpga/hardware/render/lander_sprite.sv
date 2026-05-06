`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2026 02:58:18 PM
// Design Name: 
// Module Name: lander_sprite
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


module lander_sprite (
    input  logic [9:0] BallX, BallY, DrawX, DrawY,
    output logic        sprite_on,
    output logic [3:0]  sprite_red, sprite_green, sprite_blue,
    // Thrust input so we can draw flame
    input  logic        thrust_active,
    input  logic [6:0]  angle_shifted
);

    // Sprite dimensions
    parameter SPRITE_W = 16;
    parameter SPRITE_H = 20;
    parameter SPRITE_CENTER_X = 8;
    parameter SPRITE_CENTER_Y = 10;
    parameter ROT_BOUNDS_HALF = 20;
    
    // Relative position of current pixel within sprite
    logic signed [10:0] draw_dx, draw_dy;
    logic signed [10:0] src_x, src_y;
    logic signed [10:0] rel_x, rel_y;
    logic [4:0] sprite_col, sprite_row;  // unsigned index into sprite
    logic in_sprite_bounds;
    logic sample_in_bounds;
    logic signed [7:0] angle_deg;
    logic signed [8:0] sin_q8, cos_q8;
    logic signed [19:0] src_x_q8, src_y_q8;
    
    // 2-bit color per pixel: 0=transparent, 1=white, 2=gray, 3=orange(engine)
    // 16 pixels wide × 20 pixels tall = 20 rows
    // Each row is 16 pixels × 2 bits = 32 bits
    
    logic [31:0] sprite_rom [0:23];  // 24 rows to include flame area
    logic [1:0] pixel_color;
    
    // Initialize the sprite ROM
    // Encoding: 2'b00=transparent, 2'b01=white, 2'b10=gray, 2'b11=orange
    // Each row: pixel[15] is leftmost ... pixel[0] is rightmost
    // Stored as {pixel15, pixel14, ..., pixel1, pixel0}
    
    initial begin
        //                 pix15 pix14 pix13 ... pix1  pix0
        // Row 0:  antenna tip
        //         .......***.......
        sprite_rom[0]  = 32'b00000000000001010100000000000000;
        // Row 1:  antenna
        sprite_rom[1]  = 32'b00000000000001010100000000000000;
        // Row 2:  capsule top
        sprite_rom[2]  = 32'b00000000000101010101000000000000;
        // Row 3:
        sprite_rom[3]  = 32'b00000000010101010101010000000000;
        // Row 4:  body top
        sprite_rom[4]  = 32'b00000001010101010101010100000000;
        // Row 5:  main body
        sprite_rom[5]  = 32'b00000001100101010101100100000000;
        // Row 6:
        sprite_rom[6]  = 32'b00000001011001010110010100000000;
        // Row 7:
        sprite_rom[7]  = 32'b00000001010101010101010100000000;
        // Row 8:  body bottom
        sprite_rom[8]  = 32'b00000001010101010101010100000000;
        // Row 9:  engine mount
        sprite_rom[9]  = 32'b00000000011001010110010000000000;
        // Row 10: legs start
        sprite_rom[10] = 32'b00000001000001010100000100000000;
        // Row 11:
        sprite_rom[11] = 32'b00000100000001010100000001000000;
        // Row 12: legs spread
        sprite_rom[12] = 32'b00010000000001010100000000010000;
        // Row 13: feet
        sprite_rom[13] = 32'b01010000000000100000000000010100;
        // Row 14: feet pads
        sprite_rom[14] = 32'b01010100000000000000000001010100;
        // Row 15: empty (below lander)
        sprite_rom[15] = 32'b00000000000000000000000000000000;
        // Rows 16-19: flame (only shown when thrusting)
        // Row 16: flame top
        sprite_rom[16] = 32'b00000000000011111100000000000000;
        // Row 17:
        sprite_rom[17] = 32'b00000000000000111100000000000000;
        // Row 18:
        sprite_rom[18] = 32'b00000000000000111000000000000000;
        // Row 19: flame tip
        sprite_rom[19] = 32'b00000000000000010000000000000000;
        // Unused
        sprite_rom[20] = 32'b00000000000000000000000000000000;
        sprite_rom[21] = 32'b00000000000000000000000000000000;
        sprite_rom[22] = 32'b00000000000000000000000000000000;
        sprite_rom[23] = 32'b00000000000000000000000000000000;
    end

    function automatic signed [8:0] approx_sin_q8;
        input signed [7:0] deg;
        begin
            // Valid for the game range, -45..+45 degrees. Scale is 256.
            approx_sin_q8 = deg * 4;
        end
    endfunction

    function automatic signed [8:0] approx_cos_q8;
        input signed [7:0] deg;
        logic signed [7:0] abs_deg;
        begin
            abs_deg = (deg < 0) ? -deg : deg;
            // Linear fit from cos(0)=256 to cos(45)=181, good enough for sprite sampling.
            approx_cos_q8 = 9'sd256 - ((abs_deg * 9'sd107) >>> 6);
        end
    endfunction

    assign angle_deg = $signed({1'b0, angle_shifted}) - 8'sd45;
    assign sin_q8 = approx_sin_q8(angle_deg);
    assign cos_q8 = approx_cos_q8(angle_deg);

    assign draw_dx = $signed({1'b0, DrawX}) - $signed({1'b0, BallX});
    assign draw_dy = $signed({1'b0, DrawY}) - $signed({1'b0, BallY});

    // Inverse-rotate the current screen pixel back into unrotated sprite space.
    assign src_x_q8 = (draw_dx * cos_q8) + (draw_dy * sin_q8);
    assign src_y_q8 = (draw_dy * cos_q8) - (draw_dx * sin_q8);
    assign src_x = src_x_q8 >>> 8;
    assign src_y = src_y_q8 >>> 8;

    assign rel_x = src_x + SPRITE_CENTER_X;
    assign rel_y = src_y + SPRITE_CENTER_Y;
    
    // Check if we're within sprite bounds
    assign sample_in_bounds = (draw_dx >= -ROT_BOUNDS_HALF) &&
                              (draw_dx <=  ROT_BOUNDS_HALF) &&
                              (draw_dy >= -ROT_BOUNDS_HALF) &&
                              (draw_dy <=  ROT_BOUNDS_HALF) &&
                              (rel_x >= 0) && (rel_x < SPRITE_W) &&
                              (rel_y >= 0) && (rel_y < (thrust_active ? SPRITE_H : 15));
    assign in_sprite_bounds = sample_in_bounds;

    assign sprite_col = sample_in_bounds ? rel_x[4:0] : 5'd0;
    assign sprite_row = sample_in_bounds ? rel_y[4:0] : 5'd0;
    
    // Look up pixel color from ROM
    // Each pixel is 2 bits, pixel[15] is at bits [31:30], pixel[0] is at bits [1:0]
    // For pixel N (0-15): bits are at position [N*2 +: 2]
    assign pixel_color = sprite_rom[sprite_row][(sprite_col * 2) +: 2];
    
    // Output
    always_comb begin
        sprite_on = 1'b0;
        sprite_red   = 4'h0;
        sprite_green = 4'h0;
        sprite_blue  = 4'h0;
        
        if (in_sprite_bounds && pixel_color != 2'b00) begin
            sprite_on = 1'b1;
            case (pixel_color)
                2'b01: begin // White - main body
                    sprite_red   = 4'hf;
                    sprite_green = 4'hf;
                    sprite_blue  = 4'hf;
                end
                2'b10: begin // Gray - detail/windows
                    sprite_red   = 4'h8;
                    sprite_green = 4'h8;
                    sprite_blue  = 4'hc;
                end
                2'b11: begin // Orange/Red - flame
                    sprite_red   = 4'hf;
                    sprite_green = 4'h6;
                    sprite_blue  = 4'h0;
                end
                default: begin
                    sprite_on = 1'b0;
                end
            endcase
        end
    end

endmodule
