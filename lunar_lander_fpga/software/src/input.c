#include "input.h"

#if defined(__GNUC__)
#define LANDER_WEAK __attribute__((weak))
#else
#define LANDER_WEAK
#endif

enum {
    HID_KEY_A = 0x04,
    HID_KEY_D = 0x07,
    HID_KEY_W = 0x1A
};

static bool report_has_key(const uint8_t keycodes[6], uint8_t key)
{
    int index;

    for (index = 0; index < 6; ++index) {
        if (keycodes[index] == key) {
            return true;
        }
    }

    return false;
}

LANDER_WEAK bool input_platform_read_hid_report(uint8_t keycodes[6])
{
    int index;

    for (index = 0; index < 6; ++index) {
        keycodes[index] = 0U;
    }

    return false;
}

void input_init(void)
{
}

void input_clear(LanderInput *input)
{
    if (input == 0) {
        return;
    }

    input->thrust_on = false;
    input->rotate_direction = 0;
}

void input_decode_hid_report(const uint8_t keycodes[6], LanderInput *input)
{
    if ((keycodes == 0) || (input == 0)) {
        return;
    }

    input_clear(input);
    input->thrust_on = report_has_key(keycodes, HID_KEY_W);

    if (report_has_key(keycodes, HID_KEY_A)) {
        input->rotate_direction -= 1;
    }

    if (report_has_key(keycodes, HID_KEY_D)) {
        input->rotate_direction += 1;
    }
}

void input_poll(LanderInput *input)
{
    uint8_t keycodes[6];

    if (input == 0) {
        return;
    }

    input_clear(input);

    if (input_platform_read_hid_report(keycodes)) {
        input_decode_hid_report(keycodes, input);
    }
}
