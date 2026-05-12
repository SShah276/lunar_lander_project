#include "interface.h"
#include "physics.h"
#include "game_logic.h"
#include "terrain.h"
#include "hud.h"
#include "input.h"

XGpio Gpio_keycode;
XGpio Gpio_lander;

void interface_init(void) {
    XGpio_Initialize(&Gpio_keycode, XPAR_GPIO_USB_KEYCODE_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio_keycode, 1, 0x00000000);
    XGpio_SetDataDirection(&Gpio_keycode, 2, 0x00000000);

    XGpio_Initialize(&Gpio_lander, XPAR_GPIO_LANDER_POS_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio_lander, 1, 0x00000000);   
    XGpio_SetDataDirection(&Gpio_lander, 2, 0x00000000);   
}


void send_lander_to_hw(int render_thrust) {
    unsigned int pixel_x = (unsigned int)(pos_x >> FIXED_SHIFT) & 0x3FF;
    unsigned int pixel_y = (unsigned int)(pos_y >> FIXED_SHIFT) & 0x3FF;

    u32 position_word = (pixel_y << 10) | pixel_x;
    u32 status_word = hud_pack_with_thrust(render_thrust);

    XGpio_DiscreteWrite(&Gpio_lander, 1, position_word);
    XGpio_DiscreteWrite(&Gpio_lander, 2, status_word);
}

void send_terrain_to_hw(void) {
    (void)terrain_y;  
}
