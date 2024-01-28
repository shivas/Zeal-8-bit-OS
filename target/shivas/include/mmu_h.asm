; SPDX-FileCopyrightText: 2023 Zeal 8-bit Computer <contact@zeal8bit.com>
;
; SPDX-License-Identifier: Apache-2.0

    IFNDEF MMU_H
    DEFINE MMU_H

    macro   MMU_INIT _
        ld  a, 0x20    ; Physical address of RAM shifted by 14 : 512KB >> 14 = 32
        out (0xF1), a
        inc a
        out (0xF2), a
        inc a
        out (0xF3), a
    endm

    ENDIF