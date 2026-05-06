#ifndef PHYSICS_H
#define PHYSICS_H

// Fixed-point shift — 8 fractional bits (multiply pixels by 256)
#define FIXED_SHIFT     8

// Physics constants (matching your old lander.sv values)
#define GRAVITY         4
#define THRUST_POWER    10
#define H_THRUST_POWER  6
#define H_DRAG          1
#define MAX_VEL_Y       768
#define MIN_VEL_Y       (-768)
#define MAX_VEL_X       512
#define MIN_VEL_X       (-512)

// Screen limits in fixed-point
#define LANDER_SIZE     15
#define X_MIN_FP        (LANDER_SIZE << FIXED_SHIFT)
#define X_MAX_FP        ((639 - LANDER_SIZE) << FIXED_SHIFT)
#define Y_MIN_FP        (LANDER_SIZE << FIXED_SHIFT)
#define Y_MAX_FP        ((479 - LANDER_SIZE) << FIXED_SHIFT)

// Starting position
#define X_START         (320 << FIXED_SHIFT)
#define Y_START         (60  << FIXED_SHIFT)

// Game state variables — defined in physics.c, readable everywhere
extern int pos_x, pos_y;
extern int vel_x, vel_y;
extern int thrust_on;

// Functions
void physics_init(void);
void physics_update(void);    // Note: no argument — reads from input.h

#endif
