patch_space_mouse:
        ld hl, .patch_data

.loop   ld e, (hl)
        inc hl
        ld d, (hl)
        inc hl
        ld a, e
        or d
        ret z
        ld a, (hl)
        inc hl
        ld (de), a
        jr .loop

.patch_data
        include "patch_data.inc"

        dw 0
