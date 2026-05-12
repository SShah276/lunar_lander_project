module color_mapper (
    input  logic [9:0]  BallX, BallY,
    input  logic [9:0]  DrawX, DrawY,
    input  logic [9:0]  Ball_size,          
    input  logic [31:0] hud_extra_word,
    input  logic [31:0] status_word,
    output logic [3:0]  Red, Green, Blue
);

    logic [1:0] game_state;
    logic       thrust_active;
    logic [6:0] angle_shifted;
    logic [13:0] score_value;
    logic [7:0] elapsed_seconds;
    logic [7:0] fuel_scaled;
    logic [7:0] vel_y_scaled;
    logic [7:0] vel_x_scaled;
    logic [9:0] fuel_display;

    assign game_state    = status_word[31:30];
    assign thrust_active = status_word[29];
    assign angle_shifted = status_word[28:22];
    assign score_value   = status_word[21:8];
    assign fuel_scaled   = status_word[7:0];
    assign elapsed_seconds = hud_extra_word[31:24];
    assign vel_y_scaled  = {1'b0, hud_extra_word[23:17]};
    assign vel_x_scaled  = {1'b0, hud_extra_word[16:10]};
    assign fuel_display = ((18'(fuel_scaled) * 18'd1000) / 18'd255);
    

    logic [9:0] terrain_y_at_x;
    logic [9:0] lander_ground_y;
    logic [9:0] altitude_value;
    logic       on_pad;
    logic       terrain_line_on;
    logic       terrain_glow_on;

    terrain terrain_inst (
        .DrawX           (DrawX),
        .DrawY           (DrawY),
        .BallX           (BallX),
        .BallY           (BallY),
        .terrain_y_at_x  (terrain_y_at_x),
        .lander_ground_y (lander_ground_y),
        .altitude_value  (altitude_value),
        .on_pad          (on_pad),
        .terrain_line_on (terrain_line_on),
        .terrain_glow_on (terrain_glow_on)
    );

    logic hud_on;
    logic pad_text_on;

    hud hud_inst (
        .DrawX          (DrawX),
        .DrawY          (DrawY),
        .score_value    (score_value),
        .elapsed_seconds(elapsed_seconds),
        .fuel_value     (fuel_display),
        .altitude_value (altitude_value),
        .vel_x_scaled   (vel_x_scaled),
        .vel_y_scaled   (vel_y_scaled),
        .hud_on         (hud_on),
        .pad_text_on    (pad_text_on)
    );

    logic       sprite_on;
    logic [3:0] sprite_r, sprite_g, sprite_b;

    lander_sprite sprite_inst (
        .BallX        (BallX),
        .BallY        (BallY),
        .DrawX        (DrawX),
        .DrawY        (DrawY),
        .sprite_on    (sprite_on),
        .sprite_red   (sprite_r),
        .sprite_green (sprite_g),
        .sprite_blue  (sprite_b),
        .thrust_active(thrust_active),
        .angle_shifted(angle_shifted)
    );

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

        if (sprite_on) begin
            Red   = sprite_r;
            Green = sprite_g;
            Blue  = sprite_b;
        end

        if (pad_text_on) begin
            Red   = 4'hD;
            Green = 4'hD;
            Blue  = 4'hD;
        end

        if (hud_on) begin
            Red   = 4'hD;
            Green = 4'hD;
            Blue  = 4'hD;
        end

        if (game_state == 2'b10 && DrawY < 10'd4) begin
            Red = 4'hF; Green = 4'h0; Blue = 4'h0;
        end
        if (game_state == 2'b01 && DrawY < 10'd4) begin
            Red = 4'h0; Green = 4'hF; Blue = 4'h0;
        end
    end

endmodule
