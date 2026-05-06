#ifndef HUD_H
#define HUD_H

// ============================================================
// HUD — Heads Up Display
//
// The HUD values are sent to hardware via GPIO channel 2 plus an
// extra word on the existing keycode GPIO channel 2.
//
// Gpio_lander channel 2 status word:
//  [31:30] = game_state (0=playing, 1=landed, 2=crashed)
//  [29]    = thrust_on
//  [28:22] = angle + 45 (0-90, so it's always positive)
//  [21:8]  = score, clamped to 9999
//  [7:0]   = fuel scaled 0-255
//
// Gpio_keycode channel 2 HUD-extra word:
//  [31:24] = elapsed seconds, clamped to 255
//  [23:16] = vertical speed display 0-99
//  [15:8]  = horizontal speed display 0-99
// ============================================================

unsigned int hud_pack_with_thrust(int render_thrust);
unsigned int hud_pack_extra_word(void);

#endif
