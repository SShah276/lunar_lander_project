#ifndef INPUT_H
#define INPUT_H

// ⚠️ Don't include HID.h here directly — it needs GenericTypeDefs.h first
// Instead, forward-declare only what we need

// USB HID keycodes
#define KEY_W   0x1A
#define KEY_A   0x04
#define KEY_D   0x07
#define KEY_R   0x15

// Current input state — set by input_update() each frame
extern int input_thrust;
extern int input_left;
extern int input_right;
extern int input_reset;

// Use unsigned char instead of BYTE so we don't need GenericTypeDefs.h
// BYTE is just typedef'd to unsigned char anyway
void input_update(unsigned char keycodes[6]);
int  key_is_pressed(unsigned char keycodes[6], unsigned char key);

#endif
