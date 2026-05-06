#include "interface.h"
#include "game_logic.h"   // needs game_state, fuel
#include "physics.h"      // needs pos_x, pos_y, thrust_on

XGpio Gpio_keycode;
XGpio Gpio_lander;

void interface_init(void) {
    // Keycode GPIO (existing — sends keycodes to hex display + hardware)
    XGpio_Initialize(&Gpio_keycode, XPAR_GPIO_USB_KEYCODE_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio_keycode, 1, 0x00000000);
    XGpio_SetDataDirection(&Gpio_keycode, 2, 0x00000000);

    // Lander position GPIO (new — sends position to color_mapper)
    // ⚠️ Replace with your actual device ID from xparameters.h
    XGpio_Initialize(&Gpio_lander, XPAR_GPIO_LANDER_POS_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio_lander, 1, 0x00000000);
    XGpio_SetDataDirection(&Gpio_lander, 2, 0x00000000);
}

void send_lander_to_hw(void) {
    // Convert fixed-point to pixel coordinates
    unsigned int pixel_x = (pos_x >> FIXED_SHIFT) & 0x3FF;
    unsigned int pixel_y = (pos_y >> FIXED_SHIFT) & 0x3FF;

    // Channel 1: pack X and Y into one 32-bit word
    // Bits [9:0]  = X (0-639)
    // Bits [19:10] = Y (0-479)
    u32 position_word = (pixel_y << 10) | pixel_x;

    // Channel 2: game status
    // Bits [25:24] = game_state (0=playing, 1=landed, 2=crashed)
    // Bit  [16]    = thrust_on
    // Bits [7:0]   = fuel scaled to 0-255
    u32 fuel_scaled = ((unsigned int)fuel * 255) / MAX_FUEL;
    u32 status_word = ((game_state & 0x3)  << 24) |
                      ((thrust_on  & 0x1)  << 16) |
                      (fuel_scaled & 0xFF);

    XGpio_DiscreteWrite(&Gpio_lander, 1, position_word);
    XGpio_DiscreteWrite(&Gpio_lander, 2, status_word);
}
