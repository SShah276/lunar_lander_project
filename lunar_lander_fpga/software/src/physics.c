#include "physics.h"
#include "input.h"       // needs thrust, move_left, move_right
#include "game_logic.h"  // needs game_state

// State variables — these are THE source of truth for position/velocity
int pos_x, pos_y;
int vel_x, vel_y;
int thrust_on;

void physics_init(void) {
    pos_x     = X_START;
    pos_y     = Y_START;
    vel_x     = 0;
    vel_y     = 0;
    thrust_on = 0;
}

void physics_update(void) {
    // Freeze if game is over
    if (game_state != STATE_PLAYING) return;

    // Read current input state (set by input.c each frame)
    int thrusting = input_thrust && (fuel > 0);
    int going_left  = input_left  && (fuel > 0);
    int going_right = input_right && (fuel > 0);

    // --- Vertical ---
    vel_y += GRAVITY;

    if (thrusting) {
        vel_y    -= THRUST_POWER;
        thrust_on = 1;
    } else {
        thrust_on = 0;
    }

    if (vel_y > MAX_VEL_Y)  vel_y = MAX_VEL_Y;
    if (vel_y < MIN_VEL_Y)  vel_y = MIN_VEL_Y;

    // --- Horizontal ---
    if (going_left)  vel_x -= H_THRUST_POWER;
    if (going_right) vel_x += H_THRUST_POWER;

    if (!going_left && !going_right) {
        if      (vel_x >  H_DRAG) vel_x -= H_DRAG;
        else if (vel_x < -H_DRAG) vel_x += H_DRAG;
        else                       vel_x  = 0;
    }

    if (vel_x > MAX_VEL_X)  vel_x = MAX_VEL_X;
    if (vel_x < MIN_VEL_X)  vel_x = MIN_VEL_X;

    // --- Position ---
    pos_x += vel_x;
    pos_y += vel_y;

    // --- Boundaries ---
    if (pos_y < Y_MIN_FP) { pos_y = Y_MIN_FP; vel_y = 0; }
    if (pos_y > Y_MAX_FP) { pos_y = Y_MAX_FP; vel_y = 0; vel_x = 0; }
    if (pos_x < X_MIN_FP) { pos_x = X_MIN_FP; vel_x = 0; }
    if (pos_x > X_MAX_FP) { pos_x = X_MAX_FP; vel_x = 0; }
}
