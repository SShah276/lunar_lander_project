#ifndef PHYSICS_H
#define PHYSICS_H

#define FIXED_SHIFT       8
#define FIXED_ONE         (1 << FIXED_SHIFT)   // = 256

#define GRAVITY           2       
#define THRUST_POWER      6        
#define ROTATION_STEP_FP     ((FIXED_ONE * 3) / 4) // degrees changed per update while rotating
#define MAX_TILT_DEG      45         // lookup table supports -45..+45 degrees
#define H_DRAG            1          // drag and stops horizontal drift
#define MAX_VEL_Y         400        // terminal velocity
#define MIN_VEL_Y         (-400)
#define MAX_VEL_X         256        // horizontal speed limit
#define MIN_VEL_X         (-256)

#define LANDER_SIZE       15        
#define LANDER_HALF_W     8
#define LANDER_TOP_OFFSET 10
#define LANDER_BODY_BOTTOM_OFFSET 4

#define X_START           (320 << FIXED_SHIFT)
#define Y_START           (60  << FIXED_SHIFT)

#define X_MIN_FP          (LANDER_HALF_W << FIXED_SHIFT)
#define X_MAX_FP          ((639 - LANDER_HALF_W) << FIXED_SHIFT)
#define Y_MIN_FP          (LANDER_TOP_OFFSET << FIXED_SHIFT)
#define Y_MAX_FP          ((479 - LANDER_BODY_BOTTOM_OFFSET) << FIXED_SHIFT)


extern const int sin_table[91];  
extern const int cos_table[91];

#define ANGLE_TO_IDX(a)   ((a) + 45)

extern int pos_x;        
extern int pos_y;
extern int vel_x;   
extern int vel_y;
extern int angle_deg;      // degrees: -45=left tilt, 0=upright, +45=right tilt
extern int angle_idx;      // sprite index: 0=left, 1=upright, 2=right
extern int thrust_on;      // 1 if thrusting this frame, 0 otherwise
extern int fuel;           // current fuel level, read by physics for thrust gating

void physics_init(void);
void physics_update(void);   // call once per game frame

#endif
