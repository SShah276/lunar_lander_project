#ifndef INPUT_H
#define INPUT_H

#include <stdbool.h>
#include <stdint.h>

#include "game_logic.h"

void input_init(void);
void input_clear(LanderInput *input);
void input_poll(LanderInput *input);
void input_decode_hid_report(const uint8_t keycodes[6], LanderInput *input);
bool input_platform_read_hid_report(uint8_t keycodes[6]);

#endif
