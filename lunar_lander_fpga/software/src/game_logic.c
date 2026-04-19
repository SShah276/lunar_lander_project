#include "game_logic.h"

#include "physics.h"

static float absolute_value(float value)
{
    return (value < 0.0f) ? -value : value;
}

static void resolve_touchdown(LanderState *state, const LanderConfig *config)
{
    const bool safe_horizontal =
        absolute_value(state->vx) <= config->safe_horizontal_speed;
    const bool safe_vertical =
        absolute_value(state->vy) <= config->safe_vertical_speed;
    const bool safe_angle =
        absolute_value(state->angle_deg) <= config->safe_angle_deg;

    state->y = config->ground_y;
    state->vx = 0.0f;
    state->vy = 0.0f;
    state->state =
        (safe_horizontal && safe_vertical && safe_angle)
            ? LANDER_STATE_LANDED
            : LANDER_STATE_CRASHED;
}

void lander_init(LanderState *state)
{
    if (state == 0) {
        return;
    }

    state->x = 320.0f;
    state->y = 60.0f;
    state->vx = 0.0f;
    state->vy = 0.0f;
    state->angle_deg = 0.0f;
    state->fuel = 100.0f;
    state->state = LANDER_STATE_FLYING;
}

void lander_get_default_config(LanderConfig *config)
{
    if (config == 0) {
        return;
    }

    config->gravity = 18.0f;
    config->thrust_accel = 30.0f;
    config->rotation_speed_deg = 120.0f;
    config->fuel_burn_rate = 18.0f;
    config->ground_y = 430.0f;
    config->min_x = 0.0f;
    config->max_x = 639.0f;
    config->safe_horizontal_speed = 18.0f;
    config->safe_vertical_speed = 24.0f;
    config->safe_angle_deg = 12.0f;
}

void game_logic_step(
    LanderState *state,
    const LanderInput *input,
    const LanderConfig *config,
    float dt_seconds
)
{
    if ((state == 0) || (input == 0) || (config == 0)) {
        return;
    }

    if (state->state != LANDER_STATE_FLYING) {
        return;
    }

    physics_update(state, input, config, dt_seconds);

    if (state->y >= config->ground_y) {
        resolve_touchdown(state, config);
    }
}
