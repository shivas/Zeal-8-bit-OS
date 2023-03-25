/* SPDX-FileCopyrightText: 2022 Zeal 8-bit Computer <contact@zeal8bit.com>
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#pragma once

/**
 * This file represents the keyboard interface for a key input driver.
 */


/**
 * IOCTL commands for the input/keyboard device.
 */
typedef enum {
    /**
     * Set the current input mode, check the attributes in the group below.
     */
    KB_CMD_SET_MODE = 0,

    /* Number of commands */
    KB_CMD_COUNT
} kb_cmd_t;


/**
 * Different modes supported by the imputer/keyboard device.
 * These values are meant to be passed as a parameter of KB_CMD_SET_MODE command.
 */
typedef enum {
    /**
     * In raw mode, all the characters that are pressed or released are sent to the user
     * program when a read occurs.
     * This means that no treatment is performed by the driver whatsoever. For example,
     * if (Left) Shift and A are pressed, the bytes sent to the user program will be:
     *    0x93          0x61
     * Left shift   Ascii lower A
     * The non-special characters must be sent in lowercase mode.
     */
    KB_MODE_RAW = 0,

    /**
     * In COOKED mode, the entry is buffered. So when a key is pressed, it is
     * first processed before being stored in a buffer and sent to the user
     * program (on "read").
     * The buffer is flushed when it is full or when Enter ('\n') is pressed.
     * The keys that will be treated by the driver are:
     *   - Non-special characters:
     *       which includes all printable characters: letters, numbers, punctuation, etc.
     *   - Special characters that have a well defined behavior:
     *       which includes caps lock, (left/right) shifts, left arrow,
     *       right arrow, delete key, tabulation, enter.
     * The remaining special characters are ignored. Release key events are
     * also ignored.
     */
    KB_MODE_COOKED,

    /**
     * HALFCOOKED mode is similar to COOKED mode, the difference is, when an
     * unsupported key is pressed, instead of being ignored, it is filled in
     * the buffer and a special error code is returned: ERR_SPECIAL_STATE
     * The "release key" events shall still be ignored and not transmitted to
     * the user program.
     */
    KB_MODE_HALFCOOKED,

    /**
     * Number of modes above
     */
    KB_MODE_COUNT,

} kb_mode_t;


/**
 * The following codes represent the special keys of a 104-key keyboard.
 * When the input mode is not set to COOKED, the following keys can be sent to the
 * user program to mark which special keys were pressed (or released).
 */
typedef enum {
    KB_NUMPAD_0      = 0x80,
    KB_NUMPAD_1      = 0x81,
    KB_NUMPAD_2      = 0x82,
    KB_NUMPAD_3      = 0x83,
    KB_NUMPAD_4      = 0x84,
    KB_NUMPAD_5      = 0x85,
    KB_NUMPAD_6      = 0x86,
    KB_NUMPAD_7      = 0x87,
    KB_NUMPAD_8      = 0x88,
    KB_NUMPAD_9      = 0x89,
    KB_NUMPAD_DOT    = 0x8a,
    KB_NUMPAD_ENTER  = 0x8b,
    KB_NUMPAD_PLUS   = 0x8c,
    KB_NUMPAD_MINUS  = 0x8d,
    KB_NUMPAD_MUL    = 0x8e,
    KB_NUMPAD_DIV    = 0x8f,
    KB_NUMPAD_LOCK   = 0x90,
    KB_SCROLL_LOCK   = 0x91,
    KB_CAPS_LOCK     = 0x92,
    KB_LEFT_SHIFT    = 0x93,
    KB_LEFT_ALT      = 0x94,
    KB_LEFT_CTRL     = 0x95,
    KB_RIGHT_SHIFT   = 0x96,
    KB_RIGHT_ALT     = 0x97,
    KB_RIGHT_CTRL    = 0x98,
    KB_HOME          = 0x99,
    KB_END           = 0x9a,
    KB_INSERT        = 0x9b,
    KB_DELETE        = 0x9c,
    KB_PG_DOWN       = 0x9d,
    KB_PG_UP         = 0x9e,
    KB_PRINT_SCREEN  = 0x9f,
    KB_UP_ARROW      = 0xa0,
    KB_DOWN_ARROW    = 0xa1,
    KB_LEFT_ARROW    = 0xa2,
    KB_RIGHT_ARROW   = 0xa3,
    KB_LEFT_SPECIAL  = 0xa4,

    KB_ESC           = 0xf0,
    KB_F1            = 0xf1,
    KB_F2            = 0xf2,
    KB_F3            = 0xf3,
    KB_F4            = 0xf4,
    KB_F5            = 0xf5,
    KB_F6            = 0xf6,
    KB_F7            = 0xf7,
    KB_F8            = 0xf8,
    KB_F9            = 0xf9,
    KB_F10           = 0xfa,
    KB_F11           = 0xfb,
    KB_F12           = 0xfc,

    /**
     * When a released event is triggered, this value shall precede the key concerned.
     * As such, in RAW mode, each key press should at some point generate a release
     * sequence. For example:
     *  0x61 [...] 0xFE 0x61
     *   A   [...] A released
     */
    KB_RELEASED      = 0xfe,
    KB_UNKNOWN       = 0xff,
} kb_keys_t;
