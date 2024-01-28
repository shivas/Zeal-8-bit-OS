; SPDX-FileCopyrightText: 2023 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

        INCLUDE "osconfig.asm"
        INCLUDE "errors_h.asm"
        INCLUDE "utils_h.asm"
        INCLUDE "mmu_h.asm"
        INCLUDE "target_h.asm"
        INCLUDE "log_h.asm"
        INCLUDE "vfs_h.asm"
        ;INCLUDE "stdout_h.asm"

        ; Forward declaration of symbols used below
        EXTERN zos_drivers_init
        EXTERN zos_vfs_init
        EXTERN zos_sys_init
        EXTERN zos_vfs_restore_std
        EXTERN zos_disks_init
        EXTERN zos_disks_get_default
        EXTERN zos_load_init_file
        EXTERN __KERNEL_BSS_head
        EXTERN __KERNEL_BSS_size
        EXTERN __DRIVER_BSS_head
        EXTERN __DRIVER_BSS_size

    ; PORTS
        ESC     equ $1B				; Escape
        SIO_A_DATA      equ	$00				; SIO data A
        SIO_A_CTRL      equ	$02				; SIO control A    


        SECTION KERNEL_TEXT

        PUBLIC zos_entry
zos_entry:
        ; Before setting up the stack, we need to configure the MMU.
        ; This must be a macro and not a function as the SP has not been set up yet.
        ; This is also valid for no-MMU target that need to set up the memory beforehand.
        ; Let's keep the same macro name to simplify things.
        MMU_INIT()

    IF CONFIG_KERNEL_TARGET_HAS_MMU
        ; Map the kernel RAM to the last virtual page
        MMU_MAP_KERNEL_RAM(MMU_PAGE_3)
    ENDIF

        ; Set up the stack pointer
        ld sp, CONFIG_KERNEL_STACK_ADDR

        ; If a hook has been installed for cold boot, call it
    IF CONFIG_KERNEL_COLDBOOT_HOOK
        call target_coldboot
    ENDIF

        ; Kernel RAM BSS shall be wiped now
        ld hl, __KERNEL_BSS_head
        ld de, __KERNEL_BSS_head + 1
        ld bc, __KERNEL_BSS_size - 1
        ld (hl), 0
        ldir

        ; Kernel is aware of Drivers BSS section, it must not be smaller than 2 bytes
        ld hl, __DRIVER_BSS_head
        ld de, __DRIVER_BSS_head + 1
        ld bc, __DRIVER_BSS_size - 1
        ld (hl), 0
        ldir

        call    shivas_hello

        ; Initialize the disk module
        call zos_disks_init

        ld hl, shiv_msg1
        call PrintString

        ; Initialize the VFS
        call zos_vfs_init

        ld      hl, shiv_msg2
        call    PrintString


        ; Initialize the logger
        call zos_log_init

        ld      hl, shiv_msg3
        call    PrintString


        ; Initialize all the drivers
        call zos_drivers_init


        ld      hl, shiv_msg4
        call    PrintString

        ; Setup the default stdin and stdout in the vfs
        call zos_vfs_restore_std

        ; Set up the syscalls
        call zos_sys_init

        ; Check if we have current time
        call zos_time_is_available
        rrca
        jp c, _zos_boot_time_ok
        ; Print a warning saying that we don't have any time driver
        ld b, a ; BC not altered by log
        ld hl, zos_time_warning
        call zos_log_warning
        ld a, b
_zos_boot_time_ok:
        rrca
        jp c, _zos_boot_date_ok
        ; Print a warning saying that we don't have any date driver
        ld hl, zos_date_warning
        call zos_log_warning
_zos_boot_date_ok:
        ; Load the init file from the default disk drive
        ld hl, zos_kernel_ready
        xor a
        call zos_log_message
        ld hl, _zos_default_init
        call zos_load_init_file
        ; If we return from zos_load_file, an error occurred
        ld hl, _load_error_1
        call zos_log_error
        xor a
        ld hl, _zos_default_init
        call zos_log_message
        xor a
        ld hl, _load_error_2
        call zos_log_message
        ; Loop until the board is rebooted
reboot: halt
        jp reboot

_load_error_1: DEFM "Could not load ", 0
_load_error_2: DEFM " initialization file\n", 0

shivas_hello:
                call    init_SIO

                ld      hl, SetupTerminal
                call    PrintString

                call    ClearScreen

                ld      hl, zos_boilerplate
                call    PrintString
                ret

init_SIO:
    ; configure SIO for serial 115200 boud transmission
        IFDEF sio_check
                ld      a, %00011000				; Perform channel reset
                out     (SIO_A_CTRL), a
                nop                             ; Awaiting SIO reset
                ld      a, %00000100				; WR0: register 4
                out     (SIO_A_CTRL), a
                ld      a, %10000100				; WR4: 1/32 (115200 @ 3.686 MHZ), 8-bit sync, 1 stop bit, no parity
;		ld	a, %01000100				; WR4: 1/16 (230400 @ 3.686 MHZ), 8-bit sync, 1 stop bit, no parity
                out     (SIO_A_CTRL), a
                ld      a, %00000011				; WR0: register 3
                out     (SIO_A_CTRL), a
                ld      a, %11000001				; WR3: 8-bits/char, RX enabled
                out     (SIO_A_CTRL), a
                ld      a, %00000101				; WR0: register 5
                out     (SIO_A_CTRL), a
                ld      a, %01101000				; WR5: DTR=0, 8-bits/char, TX enabled
                out     (SIO_A_CTRL), a
        ENDIF
                ret


PrintChar:
        ifdef   sio_check
                push    af
PrintCharTxWait:
                in      a, (SIO_A_CTRL)		; Read RR0 and place it in accumulator
                and     %00000100				; Isolate bit 2: TX Buffer Empty
                jr      z, PrintCharTxWait		; If it's busy, then wait
                pop     af
                out     (SIO_A_DATA), a		; Transmit the character in accumulator
        endif
                ret

PrintString:
                push    af
PrintStringLoop:
                ld      a, (HL)					; Load character to print in accumulator
                inc     hl						; Increment HL to next character to print
                cp      0					; Is it the end of the string?
                jr      z, PrintStringEnd		; Yes, then exit routine
                call    PrintChar				; Print the character
                jr      PrintStringLoop			; Repeat the loop until null character is reached
PrintStringEnd:
                pop     af
                ret 

ClearScreen:
                push    hl
                ld      hl, ClearScreenSeq
                call    PrintString
                pop     hl
                ret

SetupTerminal:
        db	ESC, '[', '=', '1', 'h', 0

ClearScreenSeq:
        db	ESC, '[', '2', 'J'		; Clears the screen
        db	ESC, '[', '0', '1', ';', '0', '1', 'H', 0 ; Sets to home position

BoldTextSeq:
        db ESC, '[', '1', 'm'
BoldTextResetSeq:
        db ESC, '[', '2', '2', 'm'

shiv_msg1:
                defm    "after zos_disks_init", 0xd, 0xa, 0

shiv_msg2:
                defm    "after zos_vfs_init", 0xd, 0xa, 0

shiv_msg3:
                defm    "after zos_log_init", 0xd, 0xa, 0

shiv_msg4:
                defm    "after zos_driver_init", 0xd, 0xa, 0

shiv_stdout_msg:
                defm    "this should be printed with stdout", 0xd, 0xa
shiv_stdout_msg_end:


        PUBLIC _zos_default_init
_zos_default_init:
        CONFIG_KERNEL_INIT_EXECUTABLE
        DEFM 0  ; NULL-byte after the string

        ; Define the boilerplate to print as soon as a logging function is available
        PUBLIC zos_boilerplate
zos_boilerplate:
        INCBIN "version.txt"
        DEFB "\n", 0
zos_time_warning: DEFM "Timer unavailable\n", 0
zos_date_warning: DEFM "Date unavailable\n", 0
zos_kernel_ready:
        DEFM "Kernel ready.\nLoading "
        CONFIG_KERNEL_INIT_EXECUTABLE
        DEFM "  @"
        STR(CONFIG_KERNEL_INIT_EXECUTABLE_ADDR)
        DEFM "\n\n", 0