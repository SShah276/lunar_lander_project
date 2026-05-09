#include "hud.h"
#include "physics.h"
#include "game_logic.h"

unsigned int hud_pack_with_thrust(int render_thrust) {
    unsigned int fuel_scaled = ((unsigned int)fuel * 255) / MAX_FUEL;
    if (fuel_scaled > 255) fuel_scaled = 255;

    unsigned int score_display = score < 0 ? 0u : (unsigned int)score;
    if (score_display > 9999u) score_display = 9999u;

    // angle_deg is -45..+45; shifting by 45 gives 0..90 for hardware rendering.
    unsigned int angle_shifted = (unsigned int)(angle_deg);

    return ((game_state    & 0x3)  << 30) |
           ((render_thrust & 0x1)  << 29) |
           ((angle_shifted & 0x7F) << 22) |
           ((score_display & 0x3FFF) << 8) |
           ((fuel_scaled   & 0xFF));
}

unsigned int hud_pack_extra_word(void) {
    unsigned int elapsed_seconds = (unsigned int)(elapsed_frames / 60);
    if (elapsed_seconds > 255u) elapsed_seconds = 255u;

    int abs_vy = vel_y < 0 ? -vel_y : vel_y;
    unsigned int vy_scaled = ((unsigned int)abs_vy * 99) / MAX_VEL_Y;
    if (vy_scaled > 99u) vy_scaled = 99u;

    int abs_vx = vel_x < 0 ? -vel_x : vel_x;
    unsigned int vx_scaled = ((unsigned int)abs_vx * 99) / MAX_VEL_X;
    if (vx_scaled > 99u) vx_scaled = 99u;

    return ((elapsed_seconds & 0xFFu) << 24) |
           ((vy_scaled       & 0xFFu) << 17) |
           ((vx_scaled       & 0xFFu) <<  10);
}
