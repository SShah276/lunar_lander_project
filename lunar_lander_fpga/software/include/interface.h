#ifndef INTERFACE_H
#define INTERFACE_H

#include <stdint.h>

#include "game_logic.h"

#define GAME_STATE_REG_LANDER_X_OFFSET 0x00U
#define GAME_STATE_REG_LANDER_Y_OFFSET 0x04U
#define GAME_STATE_REG_ANGLE_OFFSET    0x08U
#define GAME_STATE_REG_FUEL_OFFSET     0x0CU
#define GAME_STATE_REG_STATE_OFFSET    0x10U

#ifndef GAME_STATE_REG_BASE_ADDR
/* Replace this with your AXI game-state register peripheral base address. */
#define GAME_STATE_REG_BASE_ADDR 0U
#endif

void interface_write_lander_state(uintptr_t base_addr, const LanderState *state);

#endif
