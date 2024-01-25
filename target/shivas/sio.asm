; SPDX-FileCopyrightText: 2023 Audrius Karabanovas <audrius@karabanovas.net>
;
; SPDX-License-Identifier: Apache-2.0

        include "errors_h.asm"
        include "drivers_h.asm"
        include "sio_h.asm"

    section KERNEL_DRV_TEXT
        ; Initialize SIO chip.
sio_init:
sio_deinit:
        ld  a, %00011000				; Perform SIO channel reset
        out (SIO_A_CTRL), a
        nop
        ld  a, %00000100				; WR0: register 4
        out (SIO_A_CTRL), a
        ld  a, %10000100				; WR4: 1/32 (115200 @ 3.686 MHZ), 8-bit sync, 1 stop bit, no parity
        out (SIO_A_CTRL), a
        ld  a, %00000011				; WR0: register 3
        out (SIO_A_CTRL), a
        ld  a, %11000001				; WR3: 8-bits/char, RX enabled
        out (SIO_A_CTRL), a
        ld  a, %00000101				; WR0: register 5
        out (SIO_A_CTRL), a
        ld  a, %01101000				; WR5: DTR=0, 8-bits/char, TX enabled
        out (SIO_A_CTRL), a

        nop
        ld  a, 'U'
        out (SIO_A_DATA), a

        xor a                           ; ERR_SUCCESS
        ret

sio_open:
        xor a   ; Success
        ret

sio_read:
sio_write:
sio_close:
sio_seek:
sio_ioctl:
        ld  a, ERR_NOT_IMPLEMENTED ; doesn't make sense
        ret

    ; section DRIVER_BSS

    section KERNEL_DRV_VECTORS
sio_struct:
        NEW_DRIVER_STRUCT("SIO0",   \
        sio_init,   \
        sio_read,   sio_write, \
        sio_open,   sio_close, \
        sio_seek,   sio_ioctl, \
        sio_deinit)