module lander_sprite (
    input  logic [9:0] BallX,
    input  logic [9:0] BallY,
    input  logic [9:0] DrawX,
    input  logic [9:0] DrawY,
    input  logic [1:0] angle_idx,
    input  logic       thrust_active,
    output logic       sprite_on,
    output logic [3:0] sprite_red,
    output logic [3:0] sprite_green,
    output logic [3:0] sprite_blue
);

    localparam logic [4:0] SPRITE_W = 5'd16;
    localparam logic [4:0] SPRITE_H = 5'd20;
    localparam logic [4:0] SPRITE_HALF_W = 5'd8;
    localparam logic [4:0] SPRITE_HALF_H = 5'd10;

    localparam logic [1:0] PIX_TRANSPARENT = 2'b00;
    localparam logic [1:0] PIX_WHITE       = 2'b01;
    localparam logic [1:0] PIX_GRAY        = 2'b10;
    localparam logic [1:0] PIX_ORANGE      = 2'b11;

    logic [31:0] sprite_center[0:19];
    logic [31:0] sprite_left[0:19];
    logic [31:0] sprite_right[0:19];

    logic [9:0] sprite_left_x;
    logic [9:0] sprite_top_y;
    logic in_bounds;
    logic [4:0] sprite_row;
    logic [4:0] sprite_col;
    logic [31:0] active_row;
    logic [1:0] pixel_code;

    initial begin
        sprite_center[0]  = 32'b00000000000000010100000000000000;
        sprite_center[1]  = 32'b00000000000101010101000000000000;
        sprite_center[2]  = 32'b00000000010110101010010000000000;
        sprite_center[3]  = 32'b00000001011010011010010100000000;
        sprite_center[4]  = 32'b00000001011010101010010100000000;
        sprite_center[5]  = 32'b00000101010101010101010101000000;
        sprite_center[6]  = 32'b00000101101001010101100101000000;
        sprite_center[7]  = 32'b00000101011001010110010101000000;
        sprite_center[8]  = 32'b00010101010101010101010101010000;
        sprite_center[9]  = 32'b00011010010101010101011010010000;
        sprite_center[10] = 32'b00011010010101010101011010010000;
        sprite_center[11] = 32'b01010101000101010100010101010000;
        sprite_center[12] = 32'b01010000000101010100000001010000;
        sprite_center[13] = 32'b00000000010101010101000000000000;
        sprite_center[14] = 32'b00000001010100000101010000000000;
        sprite_center[15] = 32'b00000000000011111100000000000000;
        sprite_center[16] = 32'b00000000001111111111000000000000;
        sprite_center[17] = 32'b00000000111100110011110000000000;
        sprite_center[18] = 32'b00000000000011111100000000000000;
        sprite_center[19] = 32'b00000000000000000000000000000000;

        sprite_left[0]  = 32'b00000000000001010000000000000000;
        sprite_left[1]  = 32'b00000000010101010100000000000000;
        sprite_left[2]  = 32'b00000001011010101001000000000000;
        sprite_left[3]  = 32'b00000101101001101001010000000000;
        sprite_left[4]  = 32'b00000101101010101001010000000000;
        sprite_left[5]  = 32'b00010101010101010101010000000000;
        sprite_left[6]  = 32'b00010110100101010110010100000000;
        sprite_left[7]  = 32'b00010101100101011001010100000000;
        sprite_left[8]  = 32'b01010101010101010101010000000000;
        sprite_left[9]  = 32'b01101001010101010110100100000000;
        sprite_left[10] = 32'b01101001010101010110100100000000;
        sprite_left[11] = 32'b01010100010101010001010101000000;
        sprite_left[12] = 32'b00000000010101010000000101000000;
        sprite_left[13] = 32'b00000001010101010100000000000000;
        sprite_left[14] = 32'b00000101010000010101000000000000;
        sprite_left[15] = 32'b00000000001111111100000000000000;
        sprite_left[16] = 32'b00000000111111111111000000000000;
        sprite_left[17] = 32'b00000011110011001111000000000000;
        sprite_left[18] = 32'b00000000001111111100000000000000;
        sprite_left[19] = 32'b00000000000000000000000000000000;

        sprite_right[0]  = 32'b00000000000000000101000000000000;
        sprite_right[1]  = 32'b00000000000001010101010000000000;
        sprite_right[2]  = 32'b00000000000101101010100100000000;
        sprite_right[3]  = 32'b00000000010110100110100101000000;
        sprite_right[4]  = 32'b00000000010110101010100101000000;
        sprite_right[5]  = 32'b00000000010101010101010101010000;
        sprite_right[6]  = 32'b00000001011010010101011001010000;
        sprite_right[7]  = 32'b00000001010110010110010101010000;
        sprite_right[8]  = 32'b00000000010101010101010101010100;
        sprite_right[9]  = 32'b00000001011010010101010101101001;
        sprite_right[10] = 32'b00000001011010010101010101101001;
        sprite_right[11] = 32'b00000101010100010101010001010101;
        sprite_right[12] = 32'b00000101000000010101010000000000;
        sprite_right[13] = 32'b00000000000001010101010100000000;
        sprite_right[14] = 32'b00000000000101010000010101000000;
        sprite_right[15] = 32'b00000000000011111100000000000000;
        sprite_right[16] = 32'b00000000001111111111000000000000;
        sprite_right[17] = 32'b00000000111100110011110000000000;
        sprite_right[18] = 32'b00000000000011111100000000000000;
        sprite_right[19] = 32'b00000000000000000000000000000000;
    end

    always_comb begin
        sprite_left_x = (BallX >= SPRITE_HALF_W) ? (BallX - SPRITE_HALF_W) : 10'd0;
        sprite_top_y  = (BallY >= SPRITE_HALF_H) ? (BallY - SPRITE_HALF_H) : 10'd0;

        in_bounds = (DrawX >= sprite_left_x) &&
                    (DrawX < sprite_left_x + SPRITE_W) &&
                    (DrawY >= sprite_top_y) &&
                    (DrawY < sprite_top_y + SPRITE_H);

        sprite_row = in_bounds ? DrawY - sprite_top_y : 5'd0;
        sprite_col = in_bounds ? DrawX - sprite_left_x : 5'd0;

        case (angle_idx)
            2'd0: active_row = sprite_left[sprite_row];
            2'd1: active_row = sprite_center[sprite_row];
            2'd2: active_row = sprite_right[sprite_row];
            default: active_row = sprite_center[sprite_row];
        endcase

        pixel_code = active_row[31 - (sprite_col * 2) -: 2];
        if (!thrust_active && sprite_row >= 5'd15) begin
            pixel_code = PIX_TRANSPARENT;
        end

        sprite_on = in_bounds && (pixel_code != PIX_TRANSPARENT);

        case (pixel_code)
            PIX_WHITE: begin
                sprite_red = 4'hF;
                sprite_green = 4'hF;
                sprite_blue = 4'hF;
            end
            PIX_GRAY: begin
                sprite_red = 4'h8;
                sprite_green = 4'h9;
                sprite_blue = 4'hA;
            end
            PIX_ORANGE: begin
                sprite_red = 4'hF;
                sprite_green = 4'h7;
                sprite_blue = 4'h1;
            end
            default: begin
                sprite_red = 4'h0;
                sprite_green = 4'h0;
                sprite_blue = 4'h0;
            end
        endcase
    end

endmodule
