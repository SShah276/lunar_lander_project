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
//   [28:24] = angle (shifted +45)
//   [23:16] = fuel 0-255
//   [15:8]  = vert velocity 0-255
//   [7:0]   = horiz velocity 0-255
// ============================================================

// Initialize all GPIOs
void interface_init(void);

void send_lander_to_hw(int render_thrust);

// Send terrain data to hardware (call once on init + after reset)
void send_terrain_to_hw(void);

#endif
