#ifndef INTERFACE_H
#define INTERFACE_H

#include "xparameters.h"
#include <xgpio.h>

extern XGpio Gpio_keycode;
extern XGpio Gpio_lander;

void interface_init(void);

void send_lander_to_hw(int render_thrust);

void send_terrain_to_hw(void);

#endif
