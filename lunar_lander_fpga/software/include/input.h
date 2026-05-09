#ifndef INPUT_H
#define INPUT_H

// USB HID keycodes
#define KEY_W     0x1A    // Thrust (main engine)
#define KEY_A     0x04    // Rotate left
#define KEY_D     0x07    // Rotate right
#define KEY_R     0x15    // Reset game

// Current input state — updated every frame by input_update()
// 1 = pressed, 0 = not pressed
extern int input_thrust;
extern int input_left;
extern int input_right;
extern int input_reset;

// Call once per frame with the raw 6-byte keycode array from USB
void input_update(unsigned char keycodes[6]);

// Returns 1 if the given keycode is anywhere in the report
int key_is_pressed(unsigned char keycodes[6], unsigned char key);

#endif
