#ifndef GAME_LOGIC_H
#define GAME_LOGIC_H

// ============================================================
// GAME STATES
// ============================================================
#define STATE_PLAYING    0
#define STATE_LANDED     1
#define STATE_CRASHED    2

// ============================================================
// FUEL
// ============================================================
#define MAX_FUEL              2000
#define FUEL_BURN_THRUST      2      // fuel per frame while thrusting
#define FUEL_BURN_ROTATE      1      // fuel per frame while rotating

// ============================================================
// LANDING CONSTRAINTS
// How fast can you be going to count as a safe landing?
// These are in raw fixed-point velocity units.
// Tune these to change difficulty.
// ============================================================
#define SAFE_VEL_Y       100     // max safe vertical velocity
#define SAFE_VEL_X       80      // max safe horizontal velocity
#define SAFE_ANGLE       15      // max safe tilt angle in degrees

// ============================================================
// SCORING
// ============================================================
#define BASE_SCORE       1000    // base points for landing
#define FUEL_BONUS       1       // points per remaining fuel unit

// ============================================================
// STATE VARIABLES
// ============================================================
extern int game_state;
extern int fuel;
extern int score;
extern int landed_on_pad;        // which pad index we landed on (-1 = none)

// ============================================================
// FUNCTIONS
// ============================================================
void game_logic_init(void);
void game_logic_update(void);

#endif
