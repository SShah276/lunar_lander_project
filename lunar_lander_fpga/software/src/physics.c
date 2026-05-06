#include "physics.h"
#include "input.h"       // needs input_thrust, input_left, input_right
#include "game_logic.h"  // needs game_state, fuel

// ============================================================
// STATE — owned by this file
// ============================================================
int pos_x     = 0;
int pos_y     = 0;
int vel_x     = 0;
int vel_y     = 0;
int angle_deg = 0;
int angle_idx = 1;
int thrust_on = 0;

static int angle_fp = 0;

// ============================================================
// SIN/COS LOOKUP TABLE
// Precomputed: sin(degrees) * 256, for -45 to +45 degrees
// Index = degrees + 45, so index 0 = -45deg, index 45 = 0deg, index 90 = +45deg
// Generated with: round(sin(d * pi/180) * 256)
// ============================================================
const int sin_table[91] = {
    -181, -178, -175, -171, -168, -165, -161, -158, -154, -150, -147, -143, -139,
    -136, -132, -128, -124, -120, -116, -112, -108, -104, -100,  -96,  -92,  -88,
     -83,  -79,  -75,  -71,  -66,  -62,  -58,  -53,  -49,  -44,  -40,  -36,  -31,
     -27,  -22,  -18,  -13,   -9,   -4,    0,    4,    9,   13,   18,   22,   27,
      31,   36,   40,   44,   49,   53,   58,   62,   66,   71,   75,   79,   83,
      88,   92,   96,  100,  104,  108,  112,  116,  120,  124,  128,  132,  136,
     139,  143,  147,  150,  154,  158,  161,  165,  168,  171,  175,  178,  181
};

const int cos_table[91] = {
     181,  184,  187,  190,  193,  196,  199,  202,  204,  207,  210,  212,  215,
     217,  219,  222,  224,  226,  228,  230,  232,  234,  236,  237,  239,  241,
     242,  243,  245,  246,  247,  248,  249,  250,  251,  252,  253,  254,  254,
     255,  255,  255,  256,  256,  256,  256,  256,  256,  256,  255,  255,  255,
     254,  254,  253,  252,  251,  250,  249,  248,  247,  246,  245,  243,  242,
     241,  239,  237,  236,  234,  232,  230,  228,  226,  224,  222,  219,  217,
     215,  212,  210,  207,  204,  202,  199,  196,  193,  190,  187,  184,  181
};

void physics_init(void) {
    pos_x     = X_START;
    pos_y     = Y_START;
    vel_x     = 0;
    vel_y     = 0;
    thrust_on = 0;
    angle_fp  = 0;
    angle_deg = 0;
    angle_idx = 1;
}

void physics_update(void) {
    // Freeze if game is over
    if (game_state != STATE_PLAYING) return;

    // Read current input state (set by input.c each frame)
    int thrusting      = input_thrust && (fuel > 0);
    int rotating_left  = input_left   && (fuel > 0);
    int rotating_right = input_right  && (fuel > 0);

    // --- Rotation ---
    if (rotating_left && !rotating_right) {
        angle_fp -= ROTATION_STEP_FP;
    } else if (rotating_right && !rotating_left) {
        angle_fp += ROTATION_STEP_FP;
    }

    if (angle_fp < -(MAX_TILT_DEG << FIXED_SHIFT)) {
        angle_fp = -(MAX_TILT_DEG << FIXED_SHIFT);
    }
    if (angle_fp > (MAX_TILT_DEG << FIXED_SHIFT)) {
        angle_fp = (MAX_TILT_DEG << FIXED_SHIFT);
    }

    angle_deg = angle_fp / FIXED_ONE;

    if (angle_deg < -7) {
        angle_idx = 0;
    } else if (angle_deg > 7) {
        angle_idx = 2;
    } else {
        angle_idx = 1;
    }

    // --- Acceleration ---
    vel_y += GRAVITY;

    if (thrusting) {
        int angle_table_idx = ANGLE_TO_IDX(angle_deg);
        vel_x += (THRUST_POWER * sin_table[angle_table_idx]) >> FIXED_SHIFT;
        vel_y -= (THRUST_POWER * cos_table[angle_table_idx]) >> FIXED_SHIFT;
        thrust_on = 1;
    } else {
        thrust_on = 0;

        if      (vel_x >  H_DRAG) vel_x -= H_DRAG;
        else if (vel_x < -H_DRAG) vel_x += H_DRAG;
        else                       vel_x  = 0;
    }

    if (vel_x > MAX_VEL_X)  vel_x = MAX_VEL_X;
    if (vel_x < MIN_VEL_X)  vel_x = MIN_VEL_X;
    if (vel_y > MAX_VEL_Y)  vel_y = MAX_VEL_Y;
    if (vel_y < MIN_VEL_Y)  vel_y = MIN_VEL_Y;

    // --- Position ---
    pos_x += vel_x;
    pos_y += vel_y;

    // --- Boundaries ---
    if (pos_y < Y_MIN_FP) { pos_y = Y_MIN_FP; vel_y = 0; }
    if (pos_y > Y_MAX_FP) { pos_y = Y_MAX_FP; vel_y = 0; vel_x = 0; }
    if (pos_x < X_MIN_FP) { pos_x = X_MIN_FP; vel_x = 0; }
    if (pos_x > X_MAX_FP) { pos_x = X_MAX_FP; vel_x = 0; }
}
