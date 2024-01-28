        include "errors_h.asm"
        include "drivers_h.asm"
        include "vfs_h.asm"
        include "disks_h.asm"
        

        EXTERN  zos_disks_get_default
        EXTERN  zos_disks_mount

    section KERNEL_DRV_TEXT

my_driver0_init:
        ; Register itself to the VFS
        ; Do something

        call zos_disks_get_default
        ld e, FS_RAWTABLE
        ld hl, my_driver0_struct
        call zos_disks_mount

        ;ld a,  ERR_DRIVER_HIDDEN
        ret
        
my_driver0_read:
        ld a, ERR_NOT_IMPLEMENTED
        ; Do something
        xor a ; Success
        ret
my_driver0_write:
        ld a, ERR_NOT_IMPLEMENTED
        ; Do something
        xor a ; Success
        ret
my_driver0_open:
        ld a, ERR_NOT_IMPLEMENTED
        ; Do something
        ;xor a ; Success
        ret
my_driver0_close:
        ld a, ERR_NOT_IMPLEMENTED
        ; Do something
        xor a ; Success
        ret
my_driver0_seek:
        ld a, ERR_NOT_IMPLEMENTED
        ; Do something
        xor a ; Success
        ret
my_driver0_ioctl:
        ld a, ERR_NOT_IMPLEMENTED
        ; Do something
        xor a ; Success
        ret
my_driver0_deinit:
        ; Do something
        xor a ; Success
        ret

    SECTION DRV_VECTORS
my_driver0_struct:
        NEW_DRIVER_STRUCT("DRV0",   \
        my_driver0_init,   \
        my_driver0_read,   my_driver0_write, \
        my_driver0_open,   my_driver0_close, \
        my_driver0_seek,   my_driver0_ioctl, \
        my_driver0_deinit)
