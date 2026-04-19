#include "physics.h"

static float clamp_float(float value, float min_value, float max_value)
{
    if (value < min_value) {
        return min_value;
    }

    if (value > max_value) {
        return max_value;
    }

    return value;
}

void physics_update(
    LanderState *state,
    const LanderInput *input,
    const LanderConfig *config,
    float dt_seconds
)
{
    float accel_x;
    float accel_y;

    if ((state == 0) || (input == 0) || (config == 0) || (dt_seconds <= 0.0f)) {
        return;
    }

    accel_x = 0.0f;
    accel_y = config->gravity;

    /*
     * Gravity-only test mode:
     * leave thrust, rotation, and fuel consumption disabled so the
     * renderer can be validated with a simple falling object.
     *
     * state->angle_deg +=
     *     (float)input->rotate_direction * config->rotation_speed_deg * dt_seconds;
     * state->angle_deg = normalize_angle(state->angle_deg);
     *
     * if (input->thrust_on && (state->fuel > 0.0f)) {
     *     const float requested_fuel = config->fuel_burn_rate * dt_seconds;
     *     const float used_fuel =
     *         (requested_fuel < state->fuel) ? requested_fuel : state->fuel;
     *     const float thrust_scale =
     *         (requested_fuel > 0.0f) ? (used_fuel / requested_fuel) : 0.0f;
     *     const float angle_rad = state->angle_deg * (LANDER_PI / 180.0f);
     *     const float thrust_accel = config->thrust_accel * thrust_scale;
     *
     *     accel_x += sinf(angle_rad) * thrust_accel;
     *     accel_y -= cosf(angle_rad) * thrust_accel;
     *     state->fuel -= used_fuel;
     * }
     */

    state->vx += accel_x * dt_seconds;
    state->vy += accel_y * dt_seconds;
    state->x += state->vx * dt_seconds;
    state->y += state->vy * dt_seconds;

    state->x = clamp_float(state->x, config->min_x, config->max_x);
}
