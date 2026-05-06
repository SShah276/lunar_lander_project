#include "hud.h"
#include "physics.h"
#include "game_logic.h"

unsigned int hud_pack_with_thrust(int render_thrust) {
    unsigned int fuel_scaled = ((unsigned int)fuel * 255) / MAX_FUEL;
    if (fuel_scaled > 255) fuel_scaled = 255;

    int abs_vy = vel_y < 0 ? -vel_y : vel_y;
    unsigned int vy_scaled = ((unsigned int)abs_vy * 255) / MAX_VEL_Y;
    if (vy_scaled > 255) vy_scaled = 255;

    int abs_vx = vel_x < 0 ? -vel_x : vel_x;
    unsigned int vx_scaled = ((unsigned int)abs_vx * 255) / MAX_VEL_X;
    if (vx_scaled > 255) vx_scaled = 255;

    // angle_deg is -45..+45; shifting by 45 gives 0..90 for hardware rendering.
    unsigned int angle_shifted = (unsigned int)(angle_deg + 45);

    return ((game_state    & 0x3)  << 30) |
           ((render_thrust & 0x1)  << 29) |
           ((angle_shifted & 0x7F) << 22) |
           ((fuel_scaled   & 0xFF) << 14) |
           ((vy_scaled     & 0xFF) <<  6) |
           ((vx_scaled     & 0x3F));
}
