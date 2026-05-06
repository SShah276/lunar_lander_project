#ifndef INTERFACE_H
#define INTERFACE_H

#include "xparameters.h"
#include <xgpio.h>

// GPIO instances — defined in interface.c, used everywhere
extern XGpio Gpio_keycode;
extern XGpio Gpio_lander;

// Initialize both GPIOs
void interface_init(void);

// Send current game state to FPGA hardware
void send_lander_to_hw(void);

#endif
