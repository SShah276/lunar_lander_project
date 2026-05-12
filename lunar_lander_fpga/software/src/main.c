#include <stdio.h>

// USB driver includes need to stay before the Xilinx headers.
#include "lw_usb/GenericTypeDefs.h"
#include "lw_usb/GenericMacros.h"
#include "lw_usb/MAX3421E.h"
#include "lw_usb/USB.h"
#include "lw_usb/usb_ch9.h"
#include "lw_usb/transfer.h"
#include "lw_usb/HID.h"

#include "xparameters.h"
#include <xgpio.h>

#include "physics.h"
#include "input.h"
#include "game_logic.h"
#include "interface.h"
#include "terrain.h"
#include "hud.h"

extern HID_DEVICE hid_device;

static BYTE addr = 1;
const char* const devclasses[] = {
    " Uninitialized", " HID Keyboard", " HID Mouse", " Mass storage"
};

BYTE GetDriverandReport(void) {
    BYTE i, device = 0xFF, tmpbyte;
    DEV_RECORD* tpl_ptr;

    xil_printf("USB Running\n");
    for (i = 1; i < USB_NUMDEVICES; i++) {
        tpl_ptr = GetDevtable(i);
        if (tpl_ptr->epinfo != NULL) {
            xil_printf("Device %d:%s\n", i, devclasses[tpl_ptr->devclass]);
            device = tpl_ptr->devclass;
        }
    }
    // Cast to void — we check errors elsewhere, suppress unused warning
    (void)XferGetIdle(addr, 0, hid_device.interface, 0, &tmpbyte);
    (void)XferGetProto(addr, 0, hid_device.interface, &tmpbyte);
    return device;
}

#define FRAME_SKIP   1

int main(void) {

    interface_init();
    terrain_init();

    physics_init();
    game_logic_init();

    send_lander_to_hw(0);
    send_terrain_to_hw();

    BYTE rcode;
    BOOT_KBD_REPORT kbdbuf;
    BYTE runningdebugflag = 0;
    BYTE errorflag        = 0;
    BYTE device           = 0;

    static int frame_counter = 0;
    static int render_thrust_flag = 0;

    static u32 last_pos_word    = 0xFFFFFFFF;
    static u32 last_status_word = 0xFFFFFFFF;
    static u32 last_extra_word  = 0xFFFFFFFF;

    int i;
    for (i = 0; i < 6; i++) kbdbuf.keycode[i] = 0;

    xil_printf("=== LUNAR LANDER ===\n");
    xil_printf("W=Thrust  A=Left  D=Right  R=Reset\n");

    xil_printf("Initializing MAX3421E...\n");
    MAX3421E_init();
    xil_printf("Initializing USB...\n");
    USB_init();

    while (1) {
        MAX3421E_Task();
        USB_Task();

        if (GetUsbTaskState() == USB_STATE_RUNNING) {

            if (!runningdebugflag) {
                runningdebugflag = 1;
                device = GetDriverandReport();
            }
            else if (device == 1) {

                rcode = kbdPoll(&kbdbuf);

            
                if (rcode != hrNAK && rcode != 0) {
                    continue;   
                }

                input_update(kbdbuf.keycode);

                render_thrust_flag = (input_thrust  &&
                                      fuel > 0       &&
                                      game_state == STATE_PLAYING) ? 1 : 0;

                frame_counter++;
                if (frame_counter >= FRAME_SKIP) {
                    frame_counter = 0;
                    physics_update();
                    game_logic_update();
                }

                u32 new_pos = (((unsigned int)(pos_y >> FIXED_SHIFT) & 0x3FF) << 10) |
                               ((unsigned int)(pos_x >> FIXED_SHIFT) & 0x3FF);
                u32 new_status = (u32)hud_pack_with_thrust(render_thrust_flag);
                u32 new_extra = (u32)hud_pack_extra_word();

                if (new_pos != last_pos_word || new_status != last_status_word) {
                    send_lander_to_hw(render_thrust_flag);
                    last_pos_word    = new_pos;
                    last_status_word = new_status;
                }

                if (new_extra != last_extra_word) {
                    XGpio_DiscreteWrite(&Gpio_keycode, 2, new_extra);
                    last_extra_word = new_extra;
                }

                XGpio_DiscreteWrite(&Gpio_keycode, 1,
                    kbdbuf.keycode[0]          |
                    (kbdbuf.keycode[1] <<  8)  |
                    (kbdbuf.keycode[2] << 16)  |
                    (kbdbuf.keycode[3] << 24));
            }

        }
        else if (GetUsbTaskState() == USB_STATE_ERROR) {
            if (!errorflag) {
                errorflag = 1;
                xil_printf("USB Error\n");
            }
        }
        else {
            xil_printf("USB state: %x\n", GetUsbTaskState());
            if (runningdebugflag) {
                runningdebugflag = 0;
                MAX3421E_init();
                USB_init();
            }
            errorflag = 0;
        }
    }

    return 0;
}
