#include "game_logic.h"
#include "physics.h"
#include "input.h"
#include "terrain.h"

#include <stdio.h>    // for xil_printf

// ============================================================
// STATE — owned by this file
// ============================================================
int game_state    = STATE_PLAYING;
int fuel          = MAX_FUEL;
int score         = 0;
int elapsed_frames = 0;
int landed_on_pad = -1;

void game_logic_init(void) {
    game_state    = STATE_PLAYING;
    fuel          = MAX_FUEL;
    score         = 0;
    elapsed_frames = 0;
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
        elapsed_frames++;

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
    // --------------------------------------------------------
    if (game_state != STATE_PLAYING) return;

    // Get current pixel position
    int pixel_x = pos_x >> FIXED_SHIFT;
    int pixel_y = pos_y >> FIXED_SHIFT;

    // Get terrain height
    int ground_y = terrain_get_y(pixel_x);

    // Check collision with ground
    if (pixel_y + LANDER_SIZE >= ground_y) {

        // Snap lander to ground
        pos_y = (ground_y - LANDER_SIZE) << FIXED_SHIFT;

        // OLD SYSTEM: get pad index
        int pad_idx = terrain_get_pad(pixel_x);

        // Absolute values for checks
        int abs_vel_y = vel_y < 0 ? -vel_y : vel_y;
        int abs_vel_x = vel_x < 0 ? -vel_x : vel_x;
        int abs_angle = angle_deg < 0 ? -angle_deg : angle_deg;

        if (pad_idx >= 0) {
            // Over a landing pad
            if (abs_vel_y <= SAFE_VEL_Y &&
                abs_vel_x <= SAFE_VEL_X &&
                abs_angle <= SAFE_ANGLE) {

                // SAFE LANDING
                game_state    = STATE_LANDED;
                landed_on_pad = pad_idx;

                score = (BASE_SCORE + fuel * FUEL_BONUS)
                        * pads[pad_idx].score_mult;

                xil_printf("=== SAFE LANDING! ===\n");
                xil_printf("Pad: %d  Multiplier: %dx\n",
                           pad_idx, pads[pad_idx].score_mult);
                xil_printf("Score: %d  Fuel left: %d\n", score, fuel);
                xil_printf("vel_y=%d  vel_x=%d  angle=%d\n",
                           vel_y, vel_x, angle_deg);

            } else {
                // Failed landing on pad
                game_state = STATE_CRASHED;

                xil_printf("=== CRASHED ON PAD! ===\n");
                xil_printf("vel_y=%d (max %d)  vel_x=%d (max %d)  angle=%d (max %d)\n",
                           abs_vel_y, SAFE_VEL_Y,
                           abs_vel_x, SAFE_VEL_X,
                           abs_angle, SAFE_ANGLE);
            }

        } else {
            // Hit terrain (not on pad)
            game_state = STATE_CRASHED;

            xil_printf("=== CRASHED ON TERRAIN! ===\n");
            xil_printf("vel_y=%d  vel_x=%d  angle=%d\n",
                       vel_y, vel_x, angle_deg);
        }

        // Stop motion
        vel_x = 0;
        vel_y = 0;
    }
}
