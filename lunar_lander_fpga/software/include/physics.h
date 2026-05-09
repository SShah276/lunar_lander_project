#ifndef PHYSICS_H
#define PHYSICS_H

// ============================================================
// FIXED-POINT ARITHMETIC
// All positions and velocities use 8 fractional bits.
// Real pixel position = value >> FIXED_SHIFT
// Store as integer: 320 pixels = 320 << 8 = 81920
// ============================================================

#define FIXED_SHIFT       8
#define FIXED_ONE         (1 << FIXED_SHIFT)   // = 256

// ============================================================
// PHYSICS CONSTANTS
// Tuned to feel good at the USB polling rate.
// Adjust GRAVITY and THRUST if movement feels too fast/slow.
// ============================================================

#define GRAVITY           2          // lighter gravity, more forgiving
#define THRUST_POWER      6          // slightly less explosive thrust
#define ROTATION_STEP_FP     ((FIXED_ONE * 3) / 4)       // degrees changed per update while rotating
#define MAX_TILT_DEG      45         // lookup table supports -45..+45 degrees
#define H_DRAG            1          // drag — stops horizontal drift
#define MAX_VEL_Y         400        // terminal velocity
#define MIN_VEL_Y         (-400)
#define MAX_VEL_X         256        // horizontal speed cap
#define MIN_VEL_X         (-256)

// Lander sprite extents relative to the rendered center point.
// Flame rows are visual-only; collision uses the body/feet bottom.
#define LANDER_SIZE       15         // compatibility alias for legacy checks
#define LANDER_HALF_W     8
#define LANDER_TOP_OFFSET 10
#define LANDER_BODY_BOTTOM_OFFSET 4

// Starting position (fixed-point)
#define X_START           (320 << FIXED_SHIFT)
#define Y_START           (60  << FIXED_SHIFT)

// Screen boundary limits (fixed-point)
#define X_MIN_FP          (LANDER_HALF_W << FIXED_SHIFT)
#define X_MAX_FP          ((639 - LANDER_HALF_W) << FIXED_SHIFT)
#define Y_MIN_FP          (LANDER_TOP_OFFSET << FIXED_SHIFT)
#define Y_MAX_FP          ((479 - LANDER_BODY_BOTTOM_OFFSET) << FIXED_SHIFT)

// ============================================================
// SIN/COS LOOKUP TABLE
// Rotation needs sin/cos but MicroBlaze has no FPU.
// We use a lookup table scaled by 256.
// sin_table[angle_degrees + 45] gives sin * 256
// Valid for -45 to +45 degrees (our MAX_ANGLE range).
// ============================================================
extern const int sin_table[91];   // index 0..90 = -45..+45 degrees
extern const int cos_table[91];

// Convert angle (-45 to +45) to table index
#define ANGLE_TO_IDX(a)   ((a) + 45)

// ============================================================
// STATE VARIABLES
// Defined in physics.c, extern here for other modules to read.
// Only physics.c should WRITE to these.
// ============================================================
extern int pos_x;          // fixed-point position
extern int pos_y;
extern int vel_x;          // fixed-point velocity
extern int vel_y;
extern int angle_deg;      // degrees: -45=left tilt, 0=upright, +45=right tilt
extern int angle_idx;      // sprite index: 0=left, 1=upright, 2=right
extern int thrust_on;      // 1 if thrusting this frame, 0 otherwise
extern int fuel;           // current fuel level, read by physics for thrust gating

// ============================================================
// FUNCTIONS
// ============================================================
void physics_init(void);
void physics_update(void);   // call once per game frame

#endif
