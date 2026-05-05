#include "input.h"

// Include the full USB driver chain IN ORDER here
// This is the only file that needs to know about BOOT_KBD_REPORT internals
#include "lw_usb/GenericTypeDefs.h"
#include "lw_usb/GenericMacros.h"
#include "lw_usb/USB.h"
#include "lw_usb/HID.h"

int input_thrust = 0;
int input_left   = 0;
int input_right  = 0;
int input_reset  = 0;

int key_is_pressed(unsigned char keycodes[6], unsigned char key) {
    int i;
    for (i = 0; i < 6; i++) {
        if (keycodes[i] == key) return 1;
    }
    return 0;
}

// Now takes raw keycode array instead of BOOT_KBD_REPORT*
// This keeps HID types out of the header
void input_update(unsigned char keycodes[6]) {
    input_thrust = key_is_pressed(keycodes, KEY_W);
    input_left   = key_is_pressed(keycodes, KEY_A);
    input_right  = key_is_pressed(keycodes, KEY_D);
    input_reset  = key_is_pressed(keycodes, KEY_R);
}
