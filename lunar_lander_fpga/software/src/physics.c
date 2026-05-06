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

// ============================================================
// SIN/COS LOOKUP TABLE
// Precomputed: sin(degrees) * 256, for -45 to +45 degrees
// Index = degrees + 45, so index 0 = -45deg, index 45 = 0deg, index 90 = +45deg
// Generated with: round(sin(d * pi/180) * 256)
// ============================================================
const int sin_table[91] = {
    -181, -178, -176, -173, -171, -168, -165, -162,  // -45 to -38
    -160, -157, -154, -151, -148, -145, -142, -139,  // -37 to -30
    -136, -133, -130, -127, -124, -120, -117, -114,  // -29 to -22
    -111, -108, -104, -101,  -98,  -94,  -91,  -87,  // -21 to -14
     -84,  -80,  -77,  -73,  -69,  -66,  -62,  -58,  // -13 to -6
     -54,  -50,  -47,  -43,  -39,  -35,   0,         // -5 to 0
      35,   39,   43,   47,   50,   54,   58,   62,  // +1 to +8
      66,   69,   73,   77,   80,   84,   87,   91,  // +9 to +16
      94,   98,  101,  104,  108,  111,  114,  117,  // +17 to +24
     120,  124,  127,  130,  133,  136,  139,  142,  // +25 to +32
     145,  148,  151,  154,  157,  160,              // +33 to +38
     162,  165,  168,  171,  173,                    // +39 to +43
     176,  178,  181                                 // +44 to +45
};

const int cos_table[91] = {
     181,  183,  185,  187,  189,  191,  193,  195,  // -45 to -38
     197,  199,  201,  203,  205,  206,  208,  210,  // -37 to -30
     211,  213,  214,  216,  217,  219,  220,  221,  // -29 to -22
     223,  224,  225,  226,  227,  228,  229,  230,  // -21 to -14
     231,  232,  233,  234,  235,  236,  237,  238,  // -13 to -6
     239,  240,  241,  242,  243,  244,  256,        // -5 to 0
     244,  243,  242,  241,  240,  239,  238,  237,  // +1 to +8
     236,  235,  234,  233,  232,  231,  230,  229,  // +9 to +16
     228,  227,  226,  225,  224,  223,  221,  220,  // +17 to +24
     219,  217,  216,  214,  213,  211,  210,  208,  // +25 to +32
     206,  205,  203,  201,  199,  197,              // +33 to +38
     195,  193,  191,  189,  187,                    // +39 to +43
     185,  183,  181                                 // +44 to +45
};

void physics_init(void) {
    pos_x     = X_START;
    pos_y     = Y_START;
    vel_x     = 0;
    vel_y     = 0;
    thrust_on = 0;
    angle_deg = 0;
    angle_idx = 1;
}

void physics_update(void) {
    // Freeze if game is over
    if (game_state != STATE_PLAYING) return;

    // Read current input state (set by input.c each frame)
    int thrusting   = input_thrust && (fuel > 0);
    int going_left  = input_left   && (fuel > 0);
    int going_right = input_right  && (fuel > 0);

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

    if (going_left && !going_right) {
        angle_deg = -15;
        angle_idx = 0;
    } else if (going_right && !going_left) {
        angle_deg = 15;
        angle_idx = 2;
    } else {
        angle_deg = 0;
        angle_idx = 1;
    }

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
