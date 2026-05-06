#include "game_logic.h"
#include "physics.h"
#include "input.h"
#include "terrain.h"

#include <xil_printf.h>

// ============================================================
// STATE — owned by this file
// ============================================================
int game_state    = STATE_PLAYING;
int fuel          = MAX_FUEL;
int score         = 0;
int landed_on_pad = -1;

void game_logic_init(void) {
    game_state    = STATE_PLAYING;
    fuel          = MAX_FUEL;
    score         = 0;
    landed_on_pad = -1;
}

void game_logic_update(void) {

    // --------------------------------------------------------
    // RESET — always check regardless of game state
    // --------------------------------------------------------
    if (input_reset) {
        game_logic_init();
        physics_init();
        xil_printf("=== GAME RESET ===\n");
        return;
    }

    // --------------------------------------------------------
    // FUEL — burn when thrusting or rotating
    // --------------------------------------------------------
    if (game_state == STATE_PLAYING) {
        if (input_thrust && fuel > 0) {
            fuel -= FUEL_BURN_THRUST;
            if (fuel < 0) fuel = 0;
        }
        if ((input_left || input_right) && fuel > 0) {
            fuel -= FUEL_BURN_ROTATE;
            if (fuel < 0) fuel = 0;
        }
    }

    // --------------------------------------------------------
    // COLLISION DETECTION
    // Skip if game already over
    // --------------------------------------------------------
    if (game_state != STATE_PLAYING) return;

    // Get current pixel position
    int pixel_x = pos_x >> FIXED_SHIFT;
    int pixel_y = pos_y >> FIXED_SHIFT;

    // Get terrain height at lander's X position
    int ground_y = terrain_y_at_x(pixel_x);

    // Check if the visible lander body/feet have touched terrain.
    // Flame rows are not part of the collision box.
    if (pixel_y + LANDER_BODY_BOTTOM_OFFSET >= ground_y) {

        // Snap to ground
        pos_y = (ground_y - LANDER_BODY_BOTTOM_OFFSET) << FIXED_SHIFT;

        // Check if we're over a landing pad
        const LandingPad *pad = terrain_pad_at_x(pixel_x);
        int pad_idx = -1;
        if (pad != 0) {
            pad_idx = (int)(pad - terrain_current_pads());
        }

        // Get absolute velocities for comparison
        int abs_vel_y = vel_y < 0 ? -vel_y : vel_y;
        int abs_vel_x = vel_x < 0 ? -vel_x : vel_x;
        int abs_angle = angle_deg < 0 ? -angle_deg : angle_deg;  // was: angle

        if (pad_idx >= 0) {
            // Over a pad — check landing conditions
            if (abs_vel_y <= SAFE_VEL_Y &&
                abs_vel_x <= SAFE_VEL_X &&
                abs_angle <= SAFE_ANGLE) {

                // SAFE LANDING!
                game_state    = STATE_LANDED;
                landed_on_pad = pad_idx;

                // Score = base + fuel bonus + pad multiplier
                score = (BASE_SCORE + fuel * FUEL_BONUS) * pad->multiplier;

                xil_printf("=== SAFE LANDING! ===\n");
                xil_printf("Pad: %d  Multiplier: %dx\n",
                           pad_idx, pad->multiplier);
                xil_printf("Score: %d  Fuel left: %d\n", score, fuel);
                xil_printf("vel_y=%d  vel_x=%d  angle=%d\n",
                           vel_y, vel_x, angle_deg);  // was: angle

            } else {
                // Over a pad but came in too fast or at wrong angle
                game_state = STATE_CRASHED;
                xil_printf("=== CRASHED ON PAD! ===\n");
                xil_printf("vel_y=%d (max %d)  vel_x=%d (max %d)  angle=%d (max %d)\n",
                           abs_vel_y, SAFE_VEL_Y,
                           abs_vel_x, SAFE_VEL_X,
                           abs_angle, SAFE_ANGLE);  // abs_angle already updated above
            }

        } else {
            // Hit terrain outside a pad — always crash
            game_state = STATE_CRASHED;
            xil_printf("=== CRASHED ON TERRAIN! ===\n");
            xil_printf("vel_y=%d  vel_x=%d  angle=%d\n",
                       vel_y, vel_x, angle_deg);  // was: angle
        }

        // Stop lander motion either way
        vel_x = 0;
        vel_y = 0;
    }
}
