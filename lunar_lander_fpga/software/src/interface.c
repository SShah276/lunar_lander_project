#include "interface.h"
#include "game_logic.h"   // needs game_state, fuel
#include "physics.h"      // needs pos_x, pos_y, thrust_on, angle, velocity

XGpio Gpio_keycode;
XGpio Gpio_lander;
#ifdef XPAR_GPIO_LANDER_VEL_DEVICE_ID
XGpio Gpio_lander_velocity;
#endif

static u32 scale_abs_velocity(int velocity, int max_velocity) {
    int abs_velocity = velocity < 0 ? -velocity : velocity;
    if (abs_velocity > max_velocity) abs_velocity = max_velocity;
    return ((u32)abs_velocity * 255) / (u32)max_velocity;
}

void interface_init(void) {
    // Keycode GPIO (existing: sends keycodes to hex display + hardware)
    XGpio_Initialize(&Gpio_keycode, XPAR_GPIO_USB_KEYCODE_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio_keycode, 1, 0x00000000);
    XGpio_SetDataDirection(&Gpio_keycode, 2, 0x00000000);

    // Lander position GPIO (new: sends position to color_mapper)
    // Replace with your actual device ID from xparameters.h.
    XGpio_Initialize(&Gpio_lander, XPAR_GPIO_LANDER_POS_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio_lander, 1, 0x00000000);
    XGpio_SetDataDirection(&Gpio_lander, 2, 0x00000000);

#ifdef XPAR_GPIO_LANDER_VEL_DEVICE_ID
    XGpio_Initialize(&Gpio_lander_velocity, XPAR_GPIO_LANDER_VEL_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio_lander_velocity, 1, 0x00000000);
#endif
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
    // Bits [31:26] = signed angle + 45, range 0..90
    // Bits [25:24] = game_state (0=playing, 1=landed, 2=crashed)
    // Bits [23:22] = angle_idx (0=left, 1=center, 2=right)
    // Bit  [16]    = thrust_on
    // Bits [7:0]   = fuel scaled to 0-255
    u32 fuel_scaled = ((unsigned int)fuel * 255) / MAX_FUEL;
    u32 angle_scaled = (u32)(angle_deg + 45) & 0x3F;
    u32 status_word = (angle_scaled         << 26) |
                      ((game_state & 0x3)  << 24) |
                      ((angle_idx  & 0x3)  << 22) |
                      ((thrust_on  & 0x1)  << 16) |
                      (fuel_scaled & 0xFF);

    XGpio_DiscreteWrite(&Gpio_lander, 1, position_word);
    XGpio_DiscreteWrite(&Gpio_lander, 2, status_word);

#ifdef XPAR_GPIO_LANDER_VEL_DEVICE_ID
    u32 vel_x_scaled = scale_abs_velocity(vel_x, MAX_VEL_X);
    u32 vel_y_scaled = scale_abs_velocity(vel_y, MAX_VEL_Y);
    u32 velocity_word = (vel_y_scaled << 8) | vel_x_scaled;
    XGpio_DiscreteWrite(&Gpio_lander_velocity, 1, velocity_word);
#endif
}
