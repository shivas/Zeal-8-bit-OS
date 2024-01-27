; SPDX-FileCopyrightText: 2023 Audrius Karabanovas <audrius@karabanovas.net>
;
; SPDX-License-Identifier: Apache-2.0

        include "errors_h.asm"
        include "drivers_h.asm"
        include "sio_h.asm"

        EXTERN  zos_vfs_set_stdout
        EXTERN  zos_vfs_set_stdin

    section KERNEL_DRV_TEXT
        ; Initialize SIO chip.
sio_init:
        ; already initialized as hack in boot.asm
        ; ld  a, %00011000				; Perform SIO channel reset
        ; out (SIO_A_CTRL), a
        ; nop
        ; ld  a, %00000100				; WR0: register 4
        ; out (SIO_A_CTRL), a
        ; ld  a, %10000100				; WR4: 1/32 (115200 @ 3.686 MHZ), 8-bit sync, 1 stop bit, no parity
        ; out (SIO_A_CTRL), a
        ; ld  a, %00000011				; WR0: register 3
        ; out (SIO_A_CTRL), a
        ; ld  a, %11000001				; WR3: 8-bits/char, RX enabled
        ; out (SIO_A_CTRL), a
        ; ld  a, %00000101				; WR0: register 5
        ; out (SIO_A_CTRL), a
        ; ld  a, %01101000				; WR5: DTR=0, 8-bits/char, TX enabled
        ; out (SIO_A_CTRL), a

        ld hl, sio_struct
        call zos_vfs_set_stdout

        ld hl, sio_struct
        call zos_vfs_set_stdin

sio_open:
sio_close:
sio_deinit:
        ; Return ERR_SUCCESS
        xor     a
        ret

        ; Read bytes from the UART.
        ; Parameters:
        ;       DE - Destination buffer, smaller than 16KB, not cross-boundary, guaranteed to be mapped.
        ;       BC - Size to read in bytes. Guaranteed to be equal to or smaller than 16KB.
        ;       A  - Should always be DRIVER_OP_NO_OFFSET here, no need to clean the stack.
        ; Returns:
        ;       A  - ERR_SUCCESS if success, error code else
        ;       BC - Number of bytes read.
        ; Alters:
        ;       This function can alter any register.
sio_read:
        xor a
        ret
sio_write:
        ex      de, hl
        call    uart_write_hl
        xor a
        ret
sio_seek:
        ld      a, ERR_NOT_SUPPORTED
        ret

sio_ioctl:
        ld      a, ERR_NOT_SUPPORTED
        ret


        ;======================================================================;
        ;================= S T D O U T     R O U T I N E S ====================;
        ;======================================================================;


        ; The following routines are used by other drivers to communicate with
        ; the standard output, check the file "stdout_h.asm" for more info about
        ; each of them (parameters, returns, registers that can be altered...)
                PUBLIC  stdout_op_start
stdout_op_start:
                PUBLIC  stdout_op_end
stdout_op_end:
        ; Nothing special to do here
                ret


                PUBLIC  stdout_show_cursor
stdout_show_cursor:
                push    hl
                push    bc
        ; Send the ANSI code for showing the cursor
                ld      hl, _show_cursor_seq
_stdout_send_seq:
                push    de
                ld      bc, _show_cursor_seq_end-_show_cursor_seq
                call    uart_write_hl
                pop     de
                pop     bc
                pop     hl
                ret
_show_cursor_seq:
                defm    0x1b, "[?25h"
_show_cursor_seq_end:


                PUBLIC  stdout_hide_cursor
stdout_hide_cursor:
                push    hl
                push    bc
        ; Same goes for hiding the cursor, the size is the same as above
                ld      hl, _hide_cursor_seq
                jr      _stdout_send_seq
_hide_cursor_seq:
                defm    0x1b, "[?25l"

                PUBLIC  stdout_print_buffer
stdout_print_buffer:
                call    _stdout_save_restore_position
        ; TODO, write the characters
                jp      _stdout_save_restore_position

        ; Parameters:
        ;   D - Baudrate
        ;   E - 7 to save
        ;       8 to restore
_stdout_save_restore_position:
                push    bc
                ld      a, 0x1b
        ; TODO: implement send byte
        ; call uart_send_byte
                ld      a, e
        ; call uart_send_byte
                pop     bc
                ret


                public  stdout_print_char
stdout_print_char:
uart_send_byte:
                push    af
uart_send_byte_wait_for_tx_buffer:
                in      a, (SIO_A_CTRL)		; Read RR0 and place it in accumulator
                and     %00000100				; Isolate bit 2: TX Buffer Empty
                jr      z, uart_send_byte_wait_for_tx_buffer		; If it's busy, then wait
                pop     af
                out     (SIO_A_DATA), a		; Transmit the character in accumulator
                ret

uart_write_hl:
                ld      a, b
                or      c
                ret     z
                ld      a, (hl)
                push    bc
        ; Enter a critical section (disable interrupts) only when sending a byte.
        ; We must not block the interrupts for too long.
        ; ENTER_CRITICAL()
                call    uart_send_byte
        ; EXIT_CRITICAL()
                pop     bc
                inc     hl
                dec     bc
                jr      uart_write_hl
                ret

    section KERNEL_DRV_VECTORS
sio_struct:
        NEW_DRIVER_STRUCT("SIO0",   \
        sio_init,   \
        sio_read,   sio_write, \
        sio_open,   sio_close, \
        sio_seek,   sio_ioctl, \
        sio_deinit)