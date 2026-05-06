#include <stdio.h>

// USB must win this race
#include "lw_usb/GenericTypeDefs.h"
#include "lw_usb/GenericMacros.h"
#include "lw_usb/MAX3421E.h"
#include "lw_usb/USB.h"
#include "lw_usb/usb_ch9.h"
#include "lw_usb/transfer.h"
#include "lw_usb/HID.h"

#include "xparameters.h"
#include <xgpio.h>

// Your game modules last
#include "physics.h"
#include "input.h"
#include "game_logic.h"
#include "interface.h"

extern HID_DEVICE hid_device;

static BYTE addr = 1;
const char* const devclasses[] = {
    " Uninitialized", " HID Keyboard", " HID Mouse", " Mass storage"
};

BYTE GetDriverandReport() {
    BYTE i;
    BYTE rcode;
    BYTE device = 0xFF;
    BYTE tmpbyte;
    DEV_RECORD* tpl_ptr;

    xil_printf("Reached USB_STATE_RUNNING\n");
    for (i = 1; i < USB_NUMDEVICES; i++) {
        tpl_ptr = GetDevtable(i);
        if (tpl_ptr->epinfo != NULL) {
            xil_printf("Device: %d%s\n", i, devclasses[tpl_ptr->devclass]);
            device = tpl_ptr->devclass;
        }
    }
    rcode = XferGetIdle(addr, 0, hid_device.interface, 0, &tmpbyte);
    rcode = XferGetProto(addr, 0, hid_device.interface, &tmpbyte);
    return device;
}

int main() {
    interface_init();
    physics_init();
    game_logic_init();
    send_lander_to_hw();

    BYTE rcode;
    BOOT_KBD_REPORT kbdbuf;
    BYTE runningdebugflag = 0;
    BYTE errorflag = 0;
    BYTE device;

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

                if (rcode == hrNAK) {
                    // Pass raw keycode array — no BOOT_KBD_REPORT in input.h
                    input_update(kbdbuf.keycode);
                    physics_update();
                    game_logic_update();
                    send_lander_to_hw();
                    continue;
                }
                else if (rcode) {
                    continue;
                }

                // Pass raw array, not the struct
                input_update(kbdbuf.keycode);
                physics_update();
                game_logic_update();
                send_lander_to_hw();

                XGpio_DiscreteWrite(&Gpio_keycode, 1,
                    kbdbuf.keycode[0]         |
                    (kbdbuf.keycode[1] <<  8) |
                    (kbdbuf.keycode[2] << 16) |
                    (kbdbuf.keycode[3] << 24));
            }
        }
        else if (GetUsbTaskState() == USB_STATE_ERROR) {
            if (!errorflag) {
                errorflag = 1;
                xil_printf("USB Error State\n");
            }
        }
        else {
            xil_printf("USB task state: %x\n", GetUsbTaskState());
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
