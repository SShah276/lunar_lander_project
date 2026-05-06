module lander (
    input logic Reset,
    input logic frame_clk,
    input logic [7:0] keycode0, keycode1, keycode2, keycode3,
    output logic [9:0] LanderX, LanderY, LanderS,
    output logic [9:0] velocity_out,
    output logic thrust_active
);

    parameter [9:0] X_Min = 10'd0;
    parameter [9:0] X_Max = 10'd639;
    parameter [9:0] Y_Min = 10'd0;
    parameter [9:0] Y_Max = 10'd479;
    parameter [9:0] Lander_Size = 10'd15;

    parameter [9:0] X_Start = 10'd320;
    parameter [9:0] Y_Start = 10'd60;

    parameter signed [15:0] GRAVITY    = 16'sd4;
    parameter signed [15:0] THRUST     = 16'sd10;
    parameter signed [15:0] H_THRUST   = 16'sd6;
    parameter signed [15:0] MAX_VEL_Y  = 16'sd768;
    parameter signed [15:0] MIN_VEL_Y  = -16'sd768;
    parameter signed [15:0] MAX_VEL_X  = 16'sd512;
    parameter signed [15:0] MIN_VEL_X  = -16'sd512;
    parameter signed [15:0] H_DRAG     = 16'sd1;

    // Fixed-point: [17:8] = pixel, [7:0] = subpixel
    // Use 19 bits to avoid overflow (max pixel = 639, 639 << 8 = 163584, needs 18 bits unsigned)
    logic signed [19:0] pos_x, pos_y;
    logic signed [19:0] pos_x_next, pos_y_next;
    logic signed [15:0] vel_x, vel_y;
    logic signed [15:0] vel_x_next, vel_y_next;

    // Boundary limits in fixed-point (computed as constants)
    localparam signed [19:0] X_MIN_FP = 20'(Lander_Size) * 20'd256;
    localparam signed [19:0] X_MAX_FP = 20'(X_Max - Lander_Size) * 20'd256;
    localparam signed [19:0] Y_MIN_FP = 20'(Lander_Size) * 20'd256;
    localparam signed [19:0] Y_MAX_FP = 20'(Y_Max - Lander_Size) * 20'd256;
    localparam signed [19:0] X_START_FP = 20'(X_Start) * 20'd256;
    localparam signed [19:0] Y_START_FP = 20'(Y_Start) * 20'd256;

    // Pixel position
    logic [9:0] pixel_x, pixel_y;
    assign pixel_x = pos_x[17:8];
    assign pixel_y = pos_y[17:8];

    assign LanderX = pixel_x;
    assign LanderY = pixel_y;
    assign LanderS = Lander_Size;
    assign velocity_out = vel_y[15:6];

    // Key detection
    logic thrust_on, move_left, move_right;
    
    assign thrust_active = thrust_on;

    always_comb begin
        thrust_on  = 1'b0;
        move_left  = 1'b0;
        move_right = 1'b0;

        if (keycode0 == 8'h1A || keycode1 == 8'h1A || 
            keycode2 == 8'h1A || keycode3 == 8'h1A)
            thrust_on = 1'b1;

        if (keycode0 == 8'h04 || keycode1 == 8'h04 || 
            keycode2 == 8'h04 || keycode3 == 8'h04)
            move_left = 1'b1;

        if (keycode0 == 8'h07 || keycode1 == 8'h07 || 
            keycode2 == 8'h07 || keycode3 == 8'h07)
            move_right = 1'b1;
    end

    // Physics
    always_comb begin
        // --- Vertical ---
        vel_y_next = vel_y + GRAVITY;

        if (thrust_on)
            vel_y_next = vel_y_next - THRUST;

        if (vel_y_next > MAX_VEL_Y)
            vel_y_next = MAX_VEL_Y;
        else if (vel_y_next < MIN_VEL_Y)
            vel_y_next = MIN_VEL_Y;

        // --- Horizontal ---
        vel_x_next = vel_x;

        if (move_left)
            vel_x_next = vel_x_next - H_THRUST;
        if (move_right)
            vel_x_next = vel_x_next + H_THRUST;

        if (!move_left && !move_right) begin
            if (vel_x > H_DRAG)
                vel_x_next = vel_x - H_DRAG;
            else if (vel_x < -H_DRAG)
                vel_x_next = vel_x + H_DRAG;
            else
                vel_x_next = 16'sd0;
        end

        if (vel_x_next > MAX_VEL_X)
            vel_x_next = MAX_VEL_X;
        else if (vel_x_next < MIN_VEL_X)
            vel_x_next = MIN_VEL_X;

        // --- Position update (sign-extend velocity to 20 bits) ---
        pos_x_next = pos_x + {{4{vel_x_next[15]}}, vel_x_next};
        pos_y_next = pos_y + {{4{vel_y_next[15]}}, vel_y_next};

        // --- Boundary checks ---
        // Top
        if (pos_y_next < Y_MIN_FP) begin
            pos_y_next = Y_MIN_FP;
            vel_y_next = 16'sd0;
        end
        // Bottom (ground)
        if (pos_y_next > Y_MAX_FP) begin
            pos_y_next = Y_MAX_FP;
            vel_y_next = 16'sd0;
            vel_x_next = 16'sd0;
        end
        // Left
        if (pos_x_next < X_MIN_FP) begin
            pos_x_next = X_MIN_FP;
            vel_x_next = 16'sd0;
        end
        // Right
        if (pos_x_next > X_MAX_FP) begin
            pos_x_next = X_MAX_FP;
            vel_x_next = 16'sd0;
        end
    end

    // State update
    always_ff @(posedge frame_clk) begin
        if (Reset) begin
            pos_x <= X_START_FP;
            pos_y <= Y_START_FP;
            vel_x <= 16'sd0;
            vel_y <= 16'sd0;
        end
        else begin
            pos_x <= pos_x_next;
            pos_y <= pos_y_next;
            vel_x <= vel_x_next;
            vel_y <= vel_y_next;
        end
    end

endmodule