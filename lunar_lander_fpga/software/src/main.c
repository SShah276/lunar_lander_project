#include "game_logic.h"
#include "input.h"
#include "interface.h"

#if defined(__has_include)
#if __has_include("platform.h")
#include "platform.h"
#define LANDER_HAVE_PLATFORM 1
#endif
#if __has_include("sleep.h")
#include "sleep.h"
#elif __has_include(<unistd.h>)
#include <unistd.h>
#endif
#endif

#ifndef LANDER_HAVE_PLATFORM
static void init_platform(void)
{
}

static void cleanup_platform(void)
{
}
#endif

static const float FRAME_DT_SECONDS = 1.0f / 60.0f;
static const unsigned FRAME_DELAY_US = 16667U;

static void wait_for_next_frame(void)
{
    usleep(FRAME_DELAY_US);
}

int main(void)
{
    LanderState lander;
    LanderConfig config;
    LanderInput input;

    init_platform();

    lander_init(&lander);
    lander_get_default_config(&config);
    input_init();

    while (1) {
        input_poll(&input);
        game_logic_step(&lander, &input, &config, FRAME_DT_SECONDS);
        interface_write_lander_state(GAME_STATE_REG_BASE_ADDR, &lander);
        wait_for_next_frame();
    }

    cleanup_platform();
    return 0;
}
