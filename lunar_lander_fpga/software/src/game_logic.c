#include "game_logic.h"
#include "physics.h"
#include "input.h"

#include <stdio.h>

int game_state = STATE_PLAYING;
int fuel       = MAX_FUEL;

void game_logic_init(void) {
    game_state = STATE_PLAYING;
    fuel       = MAX_FUEL;
}

void game_logic_update(void) {
    if (input_reset) {
        game_logic_init();
        physics_init();
        return;
    }

    if (game_state == STATE_PLAYING) {
        if (input_thrust && fuel > 0) {
            fuel -= FUEL_BURN_RATE;
            if (fuel < 0) fuel = 0;
        }
    }

    if (game_state != STATE_PLAYING) return;

    int pixel_y = pos_y >> FIXED_SHIFT;

    if (pixel_y + LANDER_SIZE >= GROUND_Y) {
        pos_y = (GROUND_Y - LANDER_SIZE) << FIXED_SHIFT;

        int abs_vel_y = vel_y < 0 ? -vel_y : vel_y;
        int abs_vel_x = vel_x < 0 ? -vel_x : vel_x;

        if (abs_vel_y <= SAFE_VEL_Y && abs_vel_x <= SAFE_VEL_X) {
            game_state = STATE_LANDED;
            xil_printf("*** SAFE LANDING ***\n");
        } else {
            game_state = STATE_CRASHED;
            xil_printf("*** CRASHED ***\n");
        }

        vel_x = 0;
        vel_y = 0;
    }
}
