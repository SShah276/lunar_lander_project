module color_mapper (
    input  logic [9:0]  BallX, BallY,
    input  logic [9:0]  DrawX, DrawY,
    input  logic [9:0]  Ball_size,
    // Full status word from MicroBlaze
    // [31:30] = game_state  [29] = thrust  [28:24] = angle
    // [23:16] = fuel 0-255  [15:8] = vel_y 0-255  [7:0] = vel_x 0-255
    input  logic [31:0] status_word,
    output logic [3:0]  Red, Green, Blue
);

    // ============================================================
    // UNPACK STATUS WORD
    // ============================================================
    logic [1:0]  game_state;
    logic        thrust_active;
    logic [5:0]  angle_shifted;    // angle + 45, so 0-90
    logic [7:0]  fuel_scaled;      // 0=empty, 255=full
    logic [7:0]  vel_y_scaled;     // 0=slow, 255=fast
    logic [7:0]  vel_x_scaled;

    assign game_state    = status_word[31:30];
    assign thrust_active = status_word[29];
    assign angle_shifted = status_word[28:24];
    assign fuel_scaled   = status_word[23:16];
    assign vel_y_scaled  = status_word[15:8];
    assign vel_x_scaled  = status_word[7:0];

    // ============================================================
    // TERRAIN
    // Must match terrain.c array EXACTLY:
    // int terrain_y[20] = {
    //   370,360,340, 320,300, 350,350, 330,310,320,
    //   290,280, 280,280, 300,330,350, 360,370,370 };
    // Segments are 32px wide. Screen is 640px = 20 segments.
    // ============================================================
    function automatic [9:0] get_terrain_y;
        input [9:0] x;
        logic [4:0] seg;
        seg = x[9:5];   // x / 32 = top 5 bits of 10-bit x
        case (seg)
            5'd0:  get_terrain_y = 10'd370;
            5'd1:  get_terrain_y = 10'd360;
            5'd2:  get_terrain_y = 10'd340;
            5'd3:  get_terrain_y = 10'd320;
            5'd4:  get_terrain_y = 10'd300;
            5'd5:  get_terrain_y = 10'd350;   // PAD 1
            5'd6:  get_terrain_y = 10'd350;   // PAD 1
            5'd7:  get_terrain_y = 10'd330;
            5'd8:  get_terrain_y = 10'd310;
            5'd9:  get_terrain_y = 10'd320;
            5'd10: get_terrain_y = 10'd290;
            5'd11: get_terrain_y = 10'd280;
            5'd12: get_terrain_y = 10'd280;   // PAD 2
            5'd13: get_terrain_y = 10'd280;   // PAD 2
            5'd14: get_terrain_y = 10'd300;
            5'd15: get_terrain_y = 10'd330;
            5'd16: get_terrain_y = 10'd350;
            5'd17: get_terrain_y = 10'd360;
            5'd18: get_terrain_y = 10'd370;
            5'd19: get_terrain_y = 10'd370;
            default: get_terrain_y = 10'd400;
        endcase
    endfunction

    // Is current pixel a landing pad?
    function automatic is_pad;
        input [9:0] x;
        logic [4:0] seg;
        seg = x[9:5];
        // Pad 1: segs 5-6, Pad 2: segs 12-13
        is_pad = (seg >= 5'd5  && seg <= 5'd6) ||
                 (seg >= 5'd12 && seg <= 5'd13);
    endfunction

    // Terrain height at current draw pixel
    logic [9:0] terrain_y_at_x;
    logic       on_pad;
    assign terrain_y_at_x = get_terrain_y(DrawX);
    assign on_pad          = is_pad(DrawX);

    // Terrain rendering logic
    logic terrain_on;         // solid ground fill
    logic terrain_edge_on;    // bright surface line
    logic pad_on;             // landing pad surface

    // Surface line = top 3 pixels of terrain
    assign terrain_edge_on = (DrawY >= terrain_y_at_x) &&
                              (DrawY <  terrain_y_at_x + 10'd3) &&
                              !on_pad;

    // Pad surface = top 3 pixels of pad
    assign pad_on = on_pad &&
                    (DrawY >= terrain_y_at_x) &&
                    (DrawY <  terrain_y_at_x + 10'd3);

    // Solid ground fill below surface
    assign terrain_on = (DrawY >= terrain_y_at_x + 10'd3);

    // ============================================================
    // STARS
    // ============================================================
    logic star_on;
    logic [9:0] star_hash;
    assign star_hash = (DrawX * 10'd7) ^ (DrawY * 10'd13) ^ 10'd137;
    assign star_on   = (star_hash == 10'd0) &&
                       (DrawY < terrain_y_at_x);

    // ============================================================
    // SPRITE RENDERER
    // ============================================================
    logic        sprite_on;
    logic [3:0]  sprite_r, sprite_g, sprite_b;

    lander_sprite sprite_inst (
        .BallX(BallX),
        .BallY(BallY),
        .DrawX(DrawX),
        .DrawY(DrawY),
        .sprite_on(sprite_on),
        .sprite_red(sprite_r),
        .sprite_green(sprite_g),
        .sprite_blue(sprite_b),
        .thrust_active(thrust_active)
    );

// ============================================================
// HUD LAYOUT
// Left side of screen, larger bars, color-coded labels
//
//  Y=10-24:   [FUEL LABEL][========fuel bar========        ]
//  Y=28-42:   [VVEL LABEL][========vert vel bar====        ]
//  Y=46-60:   [HVEL LABEL][========horiz vel bar===        ]
//
// Label block = 6px wide, same color as bar
// Bar max width = 150px
// Bar height = 14px (readable)
// ============================================================

parameter HUD_X        = 10;     // left edge
parameter HUD_LABEL_W  = 6;      // label color block width
parameter HUD_BAR_MAXW = 150;    // max bar width
parameter HUD_BAR_H    = 14;     // bar height — was 8, now 14

// Row Y positions
parameter FUEL_Y_TOP  = 10;
parameter FUEL_Y_BOT  = FUEL_Y_TOP  + HUD_BAR_H;   // 24
parameter VELY_Y_TOP  = 28;
parameter VELY_Y_BOT  = VELY_Y_TOP  + HUD_BAR_H;   // 42
parameter VELX_Y_TOP  = 46;
parameter VELX_Y_BOT  = VELX_Y_TOP  + HUD_BAR_H;   // 60

// Scale 0-255 → 0-150 pixels
// width = scaled * 150 / 255 ≈ scaled * 150 >> 8
logic [9:0] fuel_bar_w, vely_bar_w, velx_bar_w;
assign fuel_bar_w = ({2'b0, fuel_scaled}  * 10'd150) >> 8;
assign vely_bar_w = ({2'b0, vel_y_scaled} * 10'd150) >> 8;
assign velx_bar_w = ({2'b0, vel_x_scaled} * 10'd150) >> 8;

// Background panel — dark rectangle behind entire HUD for readability
logic hud_bg_on;
assign hud_bg_on = (DrawX >= HUD_X - 2) && 
                   (DrawX <= HUD_X + HUD_LABEL_W + HUD_BAR_MAXW + 2) &&
                   (DrawY >= FUEL_Y_TOP - 2) && 
                   (DrawY <= VELX_Y_BOT + 2);

// Label blocks (solid color, left of bar)
logic fuel_label_on, vely_label_on, velx_label_on;
assign fuel_label_on = (DrawX >= HUD_X) && 
                        (DrawX <  HUD_X + HUD_LABEL_W) &&
                        (DrawY >= FUEL_Y_TOP) && 
                        (DrawY <= FUEL_Y_BOT);

assign vely_label_on = (DrawX >= HUD_X) && 
                        (DrawX <  HUD_X + HUD_LABEL_W) &&
                        (DrawY >= VELY_Y_TOP) && 
                        (DrawY <= VELY_Y_BOT);

assign velx_label_on = (DrawX >= HUD_X) && 
                        (DrawX <  HUD_X + HUD_LABEL_W) &&
                        (DrawY >= VELX_Y_TOP) && 
                        (DrawY <= VELX_Y_BOT);

// Bar outlines — 1px border around each bar area
logic fuel_outline_on, vely_outline_on, velx_outline_on;
parameter BAR_X = HUD_X + HUD_LABEL_W;   // where bars start

assign fuel_outline_on = (DrawX >= BAR_X - 1) && 
                          (DrawX <= BAR_X + HUD_BAR_MAXW + 1) &&
                          (DrawY >= FUEL_Y_TOP - 1) && 
                          (DrawY <= FUEL_Y_BOT + 1) &&
                          ((DrawX == BAR_X - 1) || 
                           (DrawX == BAR_X + HUD_BAR_MAXW + 1) ||
                           (DrawY == FUEL_Y_TOP - 1) || 
                           (DrawY == FUEL_Y_BOT + 1));

assign vely_outline_on = (DrawX >= BAR_X - 1) && 
                          (DrawX <= BAR_X + HUD_BAR_MAXW + 1) &&
                          (DrawY >= VELY_Y_TOP - 1) && 
                          (DrawY <= VELY_Y_BOT + 1) &&
                          ((DrawX == BAR_X - 1) || 
                           (DrawX == BAR_X + HUD_BAR_MAXW + 1) ||
                           (DrawY == VELY_Y_TOP - 1) || 
                           (DrawY == VELY_Y_BOT + 1));

assign velx_outline_on = (DrawX >= BAR_X - 1) && 
                          (DrawX <= BAR_X + HUD_BAR_MAXW + 1) &&
                          (DrawY >= VELX_Y_TOP - 1) && 
                          (DrawY <= VELX_Y_BOT + 1) &&
                          ((DrawX == BAR_X - 1) || 
                           (DrawX == BAR_X + HUD_BAR_MAXW + 1) ||
                           (DrawY == VELX_Y_TOP - 1) || 
                           (DrawY == VELX_Y_BOT + 1));

// Filled bar areas
logic fuel_bar_on, vely_bar_on, velx_bar_on;
assign fuel_bar_on = (DrawX >= BAR_X) && 
                      (DrawX <  BAR_X + fuel_bar_w) &&
                      (DrawY >= FUEL_Y_TOP) && 
                      (DrawY <= FUEL_Y_BOT);

assign vely_bar_on = (DrawX >= BAR_X) && 
                      (DrawX <  BAR_X + vely_bar_w) &&
                      (DrawY >= VELY_Y_TOP) && 
                      (DrawY <= VELY_Y_BOT);

assign velx_bar_on = (DrawX >= BAR_X) && 
                      (DrawX <  BAR_X + velx_bar_w) &&
                      (DrawY >= VELX_Y_TOP) && 
                      (DrawY <= VELX_Y_BOT);

// Danger threshold line for velocity bars — at 40% = safe landing zone
// If bar exceeds this line, you'll crash
parameter DANGER_X = BAR_X + (HUD_BAR_MAXW * 4 / 10);  // 40% mark

logic danger_line_on;
assign danger_line_on = (DrawX == DANGER_X) &&
                         ((DrawY >= VELY_Y_TOP - 1 && DrawY <= VELY_Y_BOT + 1) ||
                          (DrawY >= VELX_Y_TOP - 1 && DrawY <= VELX_Y_BOT + 1));
    // ============================================================
    // GAME STATE OVERLAYS
    // Flash the entire screen tint on crash or win
    // Use a slow counter to create a flashing effect
    // ============================================================

    // ============================================================
    // PIXEL COLOR PRIORITY (highest priority first)
    // 1. Game state overlay (crash red / win green flash)
    // 2. HUD bars
    // 3. Lander sprite
    // 4. Landing pad surface
    // 5. Terrain surface edge
    // 6. Terrain fill
    // 7. Stars
    // 8. Space background
    // ============================================================
    always_comb begin
        // Defaults
        Red   = 4'h0;
        Green = 4'h0;
        Blue  = 4'h1;

        // --- 8. Space background ---
        // (already set above as default)

        // --- 7. Stars ---
        if (star_on) begin
            Red   = 4'hf;
            Green = 4'hf;
            Blue  = 4'hf;
        end

        // --- 6. Terrain fill ---
        if (terrain_on) begin
            Red   = 4'h5;
            Green = 4'h4;
            Blue  = 4'h2;
        end

        // --- 5. Terrain surface edge ---
        if (terrain_edge_on) begin
            Red   = 4'h8;
            Green = 4'h7;
            Blue  = 4'h4;
        end

        // --- 4. Landing pad surface ---
        if (pad_on) begin
            // Yellow landing pad
            Red   = 4'hf;
            Green = 4'hf;
            Blue  = 4'h0;
        end

        // --- 3. Lander sprite ---
        if (sprite_on) begin
            Red   = sprite_r;
            Green = sprite_g;
            Blue  = sprite_b;
        end

        // --- HUD background panel ---
if (hud_bg_on) begin
    Red   = 4'h1;
    Green = 4'h1;
    Blue  = 4'h2;   // very dark blue panel
end

// --- Bar outlines (white) ---
if (fuel_outline_on || vely_outline_on || velx_outline_on) begin
    Red   = 4'h7;
    Green = 4'h7;
    Blue  = 4'h7;
end

// --- Danger threshold line (yellow) ---
if (danger_line_on) begin
    Red   = 4'hf;
    Green = 4'hf;
    Blue  = 4'h0;
end

// --- FUEL BAR (green → red as it depletes) ---
if (fuel_label_on) begin
    // Bright green label block
    Red   = 4'h0;
    Green = 4'hf;
    Blue  = 4'h0;
end
if (fuel_bar_on) begin
    // Color shifts green→yellow→red as fuel depletes
    // fuel_scaled: 255=full(green), 128=half(yellow), 0=empty(red)
    if (fuel_scaled > 8'd170) begin
        Red = 4'h0; Green = 4'ha; Blue = 4'h0;   // green
    end else if (fuel_scaled > 8'd85) begin
        Red = 4'ha; Green = 4'ha; Blue = 4'h0;   // yellow
    end else begin
        Red = 4'hc; Green = 4'h2; Blue = 4'h0;   // red — almost empty!
    end
end

// --- VERTICAL VELOCITY BAR (blue → red as speed increases) ---
if (vely_label_on) begin
    Red   = 4'hf;
    Green = 4'h0;
    Blue  = 4'h0;   // red label = danger indicator
end
if (vely_bar_on) begin
    // Bar color shifts blue→red as vel increases past safe zone
    if (vel_y_scaled < 8'd100) begin
        Red = 4'h0; Green = 4'h6; Blue = 4'hc;   // safe: blue
    end else begin
        Red = 4'hc; Green = 4'h2; Blue = 4'h2;   // danger: red
    end
end

// --- HORIZONTAL VELOCITY BAR (blue → orange) ---
if (velx_label_on) begin
    Red   = 4'h0;
    Green = 4'h6;
    Blue  = 4'hf;   // blue label
end
if (velx_bar_on) begin
    if (vel_x_scaled < 8'd100) begin
        Red = 4'h0; Green = 4'h6; Blue = 4'hc;   // safe: blue
    end else begin
        Red = 4'hf; Green = 4'h6; Blue = 4'h0;   // danger: orange
    end
end

        // --- 1. Game state overlay ---
        // Crashed: tint top strip red
        if (game_state == 2'b10) begin
            if (DrawY < 10'd8) begin
                Red   = 4'hf;
                Green = 4'h0;
                Blue  = 4'h0;
            end
        end
        // Landed: tint top strip green
        if (game_state == 2'b01) begin
            if (DrawY < 10'd8) begin
                Red   = 4'h0;
                Green = 4'hf;
                Blue  = 4'h0;
            end
        end
    end

endmodule