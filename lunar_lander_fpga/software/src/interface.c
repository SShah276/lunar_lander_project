#include "interface.h"

#if defined(__has_include)
#if __has_include("xil_io.h")
#include "xil_io.h"
#define LANDER_HAVE_XIL_IO 1
#endif
#endif

static uint32_t round_to_u32(float value)
{
    if (value <= 0.0f) {
        return 0U;
    }

    return (uint32_t)(value + 0.5f);
}

static uint32_t round_to_i32_bits(float value)
{
    int32_t signed_value;

    if (value >= 0.0f) {
        signed_value = (int32_t)(value + 0.5f);
    } else {
        signed_value = (int32_t)(value - 0.5f);
    }

    return (uint32_t)signed_value;
}

static void mmio_write32(uintptr_t address, uint32_t value)
{
#ifdef LANDER_HAVE_XIL_IO
    Xil_Out32(address, value);
#else
    *(volatile uint32_t *)address = value;
#endif
}

void interface_write_lander_state(uintptr_t base_addr, const LanderState *state)
{
    if ((base_addr == 0U) || (state == 0)) {
        return;
    }

    mmio_write32(
        base_addr + GAME_STATE_REG_LANDER_X_OFFSET,
        round_to_u32(state->x)
    );
    mmio_write32(
        base_addr + GAME_STATE_REG_LANDER_Y_OFFSET,
        round_to_u32(state->y)
    );
    mmio_write32(
        base_addr + GAME_STATE_REG_ANGLE_OFFSET,
        round_to_i32_bits(state->angle_deg)
    );
    mmio_write32(
        base_addr + GAME_STATE_REG_FUEL_OFFSET,
        round_to_u32(state->fuel)
    );
    mmio_write32(
        base_addr + GAME_STATE_REG_STATE_OFFSET,
        (uint32_t)state->state
    );
}
