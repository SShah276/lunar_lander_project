#ifndef GAME_LOGIC_H
#define GAME_LOGIC_H

#include <stdbool.h>

typedef enum {
    LANDER_STATE_FLYING = 0,
    LANDER_STATE_LANDED = 1,
    LANDER_STATE_CRASHED = 2
} LanderGameState;

typedef struct {
    bool thrust_on;
    int rotate_direction;
} LanderInput;

typedef struct {
    float x;
    float y;
    float vx;
    float vy;
    float angle_deg;
    float fuel;
    LanderGameState state;
} LanderState;

typedef struct {
    float gravity;
    float thrust_accel;
    float rotation_speed_deg;
    float fuel_burn_rate;
    float ground_y;
    float min_x;
    float max_x;
    float safe_horizontal_speed;
    float safe_vertical_speed;
    float safe_angle_deg;
} LanderConfig;

void lander_init(LanderState *state);
void lander_get_default_config(LanderConfig *config);
void game_logic_step(
    LanderState *state,
    const LanderInput *input,
    const LanderConfig *config,
    float dt_seconds
);

#endif
