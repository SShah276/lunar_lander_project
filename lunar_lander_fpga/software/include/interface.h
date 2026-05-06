#ifndef INTERFACE_H
#define INTERFACE_H

#include "xparameters.h"
#include <xgpio.h>

// ============================================================
// GPIO INSTANCES
// gpio_keycode: existing — sends keycodes to hex display
// gpio_lander:  new — sends lander state to color_mapper
// gpio_terrain: new — sends terrain heights to hardware renderer
// ============================================================
extern XGpio Gpio_keycode;
extern XGpio Gpio_lander;

// ============================================================
// GPIO CHANNEL LAYOUT
//
// Gpio_lander Channel 1 (position):
//   [19:10] = pixel_y
//   [9:0]   = pixel_x
//
// Gpio_lander Channel 2 (HUD/status):
//   [31:30] = game_state
//   [29]    = thrust_on
//   [28:22] = angle (shifted +45, 0..90)
//   [21:8]  = score 0-9999
//   [7:0]   = fuel 0-255
//
// Gpio_keycode Channel 2 (HUD extra):
//   [31:24] = elapsed seconds
//   [23:16] = vertical speed 0-99
//   [15:8]  = horizontal speed 0-99
// ============================================================

// Initialize all GPIOs
void interface_init(void);

void send_lander_to_hw(int render_thrust);

// Send terrain data to hardware (call once on init + after reset)
void send_terrain_to_hw(void);

#endif
