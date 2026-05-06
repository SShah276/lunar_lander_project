#ifndef HUD_H
#define HUD_H

// ============================================================
// HUD — Heads Up Display
//
// The HUD values are sent to hardware via GPIO channel 2.
// Hardware unpacks them and renders bars on screen.
//
// Packed format for HUD GPIO word (32 bits):
//  [31:30] = game_state (0=playing, 1=landed, 2=crashed)
//  [29]    = thrust_on
//  [28:22] = angle + 45 (0-90, so it's always positive)
//  [21:14] = fuel scaled 0-255
//  [13:6]  = vertical velocity scaled 0-255 (0=slow, 255=fast)
//  [5:0]   = horizontal velocity scaled 0-63
// ============================================================

// Build and return the packed HUD GPIO word
unsigned int hud_pack_with_thrust(int render_thrust);

#endif
