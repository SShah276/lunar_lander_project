#include "interface.h"
#include "physics.h"
#include "game_logic.h"
#include "terrain.h"
#include "hud.h"
#include "input.h"

XGpio Gpio_keycode;
XGpio Gpio_lander;

void interface_init(void) {
    // Existing keycode GPIO
    XGpio_Initialize(&Gpio_keycode, XPAR_GPIO_USB_KEYCODE_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio_keycode, 1, 0x00000000);
    XGpio_SetDataDirection(&Gpio_keycode, 2, 0x00000000);

    // Replace with your actual lander GPIO device ID from xparameters.h
    XGpio_Initialize(&Gpio_lander, XPAR_GPIO_LANDER_POS_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio_lander, 1, 0x00000000);   // position: output
    XGpio_SetDataDirection(&Gpio_lander, 2, 0x00000000);   // HUD: output
}


void send_lander_to_hw(int render_thrust) {
    unsigned int pixel_x = (unsigned int)(pos_x >> FIXED_SHIFT) & 0x3FF;
    unsigned int pixel_y = (unsigned int)(pos_y >> FIXED_SHIFT) & 0x3FF;

    u32 position_word = (pixel_y << 10) | pixel_x;

    // Use the explicitly passed render_thrust — never stale
    u32 status_word = hud_pack_with_thrust(render_thrust);

    XGpio_DiscreteWrite(&Gpio_lander, 1, position_word);
    XGpio_DiscreteWrite(&Gpio_lander, 2, status_word);
}

void send_terrain_to_hw(void) {
    // ============================================================
    // Terrain data is too large to fit in simple GPIO registers.
    //
    // Option A (simple): Terrain is hardcoded in color_mapper.sv
    //   → No GPIO needed, hardware matches terrain.c array exactly
    //   → You manually keep them in sync
    //
    // Option B (flexible): Use a BRAM shared between SW and HW
    //   → MicroBlaze writes terrain_y[] to BRAM base address
    //   → color_mapper reads from BRAM during rendering
    //   → Requires adding BRAM block to Vivado block design
    //
    // For now we use Option A — terrain is static and
    // color_mapper.sv has matching hardcoded values.
    // This function is a placeholder for Option B later.
    // ============================================================
    (void)terrain_y;   // suppress unused warning
}
