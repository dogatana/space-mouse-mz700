;==============================
; space mouse launcher
;==============================

include "color.asm"

; -----------------------------
; 機種依存定義
; -----------------------------

launcher_start_addr equ $1200
space_mouse_top_addr equ $2400
; space_mouse_top_addr equ $2000
vram_addr equ $d000
function xy2vram(x, y) => y * 40 + x + vram_addr
function xy2attr(x, y) => y * 40 + x + vram_addr + $0800
                charmap @MAP,"mz700.json"

; -----------------------------
; space mouse 本体の参照
; ----------------------------
ex_pcg_exist equ space_mouse_top_addr + $114e
ex_high_score equ space_mouse_top_addr + $10f7
ex_program_entry equ space_mouse_top_addr + $0420


EOS equ 0xFF


; x = 0..39
; y = 0..24
; c = attribute color
PRINT_XYC       macro x, y, color, msg
                ld hl, .msg
                ld d, y
                ld e, x
                ld b, color
                call puts
                jr .next
.msg            db msg, EOS
.next
                endm

WAIT_N          macro   n
                ld  de, n
                call wait_loop
                endm

BEEP_ON         macro
                ld a, 1
                call ROM_BEEP
                endm

BEEP_OFF        macro
                xor a
                call ROM_BEEP
                endm

; --------------------------------------------
; launcher 開始
; --------------------------------------------
                org launcher_start_addr

                jr start
                nop
                nop
; --------------------------------------------
; jump table of support routine for mz700
; --------------------------------------------
pub_rom_conose:
pub_rom_width:
pub_rom_color:
                ret
                nop
                nop
                nop
pub_rom_cls:
                jp rom_cls
                nop
pub_init_attr:
                jp support_init_attr
                nop
pub_rom_xy_vram_ofs:
                jp rom_xy_vram_ofs
                nop
pub_disp_man_sub:
                jp disp_man_sub
                nop
pub_rom_beep:
                jp rom_beep
                nop
pub_rom_get_key:
                jp rom_get_key
                nop
pub_rom_scroll_stage:
                jp rom_scroll_stage
                nop
pub_rom_attr_control:
                jp rom_attr_control
                nop
pub_rom_set_line_attr:
                jp rom_set_line_attr
                nop
pub_rom_check_quit:
                jp rom_check_quit
                nop
pub_rom_hide_char:
                jp rom_hide_char
                nop

; --------------------------------------------
; launcher 開始
; --------------------------------------------
start:          call patch_space_mouse
                call init_screen

                ; pcg 8100 の有無確認

check_pcg:  call rom_cls
                PRINT_XYC 2, 12, ATTR_WHITE,  @MAP:"PCG-8001 がありますか (Y or N) "
                call wait_all_key_release
.check_pcg_loop
                call get_key

                cp "Y"
                jr nz, .check_no
                call ex_init_pcg ; pcg キャラクタ書き込み
                ld a, 1 ; pcg あり
                jr .set_ex_pcg_exist

.check_no       cp "N"
                jr nz, .check_pcg_loop

                ld a, 0 ; pcg なし
.set_ex_pcg_exist
                ld (ex_pcg_exist), a

                ; hig score クリアの有無確認
check_clear_high_score:
                call rom_cls
                PRINT_XYC 2, 12, ATTR_WHITE, @MAP:"HIGH-SCORE を 0 にしますか (Y or N) "
                call wait_all_key_release
                call get_key
                cp "Y"
                jr nz, .check_no
                ld hl, 0
                ld (ex_high_score), hl
                jr .next

.check_no       cp "N"
                jr nz, check_clear_high_score

.next
show_main_title:
                call display_title
call_game_main:
                call ex_program_entry

                call display_retry_message
                call wait_all_key_release
query_retry:
                call get_key
                cp "\r"
                jp z, call_game_main
                cp "N"
                jr nz, query_retry
                call init_screen
                call rom_cls
                jp ROM_HOT_START


; ---------------------------
; タイトル画面表示
; ---------------------------
display_title:
                call ROM_CLS

                PRINT_XYC 3, 24, ATTR_CYAN, @MAP:"┏━━━━━━━━━━━━━━━━━┓"
                call scroll_up
                PRINT_XYC 3, 24, ATTR_CYAN, @MAP:"┃＊＊　ＳＰＡＣＥ　ＭＯＵＳＥ　＊＊┃"
                call scroll_up
                PRINT_XYC 3, 24, ATTR_CYAN, @MAP:"┗━━━━━━━━━━━━━━━━━┛"
                BEEP_ON
                WAIT_N 15000
                BEEP_OFF

                call scroll_up
                call scroll_up
                PRINT_XYC 0, 24, ATTR_MAGENTA, @MAP:"＃＃＃　　ＳＣＯＲＥ　ＡＤＶＡＮＣＥ　ＴＡＢＬＥ　　＃＃＃"
                BEEP_ON
                WAIT_N 15000
                BEEP_OFF

                call scroll_up
                call scroll_up
                PRINT_XYC 0, 24, ATTR_YELLOW, @MAP:"　ＰＯＷＥＲ　ＦＥＥＤ　・・・・　ＳＣＥＮＥ　＊　５０　ＰＴＳ"
                BEEP_ON
                WAIT_N 15000
                BEEP_OFF

                call scroll_up
                call scroll_up
                PRINT_XYC 0, 24, ATTR_GREEN, @MAP:"　ＧＯ　ＵＰ　ＴＨＥ　ＦＬＯＯＡ　・・・　ＳＣＥＮＥ　＊　１０　ＰＴＳ"
                BEEP_ON
                WAIT_N 15000
                BEEP_OFF

                call scroll_up
                call scroll_up
                PRINT_XYC 0, 24, ATTR_CYAN, @MAP:"　ＢＯＮＵＳ　・・・・　ＳＣＥＮＥ　＊　ＯＸＹＧＥＮ　＊　１０　ＰＴＳ"
                BEEP_ON
                WAIT_N 15000
                BEEP_OFF

                call scroll_up
                call scroll_up
                call scroll_up
                PRINT_XYC 0, 24, ATTR_MAGENTA, @MAP:"<key function>"
                PRINT_XYC 18, 24, ATTR_WHITE, @MAP:"ＵＰ"
                call scroll_up
                PRINT_XYC 9, 24, ATTR_WHITE, @MAP:"　　　　　　　　┏━┓"
                call scroll_up
                PRINT_XYC 9, 24, ATTR_WHITE, @MAP:"　　　　　　　　┃８┃"
                call scroll_up
                PRINT_XYC 9, 24, ATTR_WHITE, @MAP:"　　　　　┏━┓┗━┛┏━┓"
                call scroll_up
                PRINT_XYC 9, 24, ATTR_WHITE, @MAP:"ＬＥＦＴ　┃４┃　＋　┃６┃　ＲＩＧＨＴ"
                call scroll_up
                PRINT_XYC 9, 24, ATTR_WHITE, @MAP:"　　　　　┗━┛　　　┗━┛"
                call scroll_up
                call scroll_up
                PRINT_XYC 0, 24, ATTR_WHITE, @MAP:"　５０００　ＰＴＳ で　ＭＡＮ ひとり　ふえます。"
                BEEP_ON
                WAIT_N 15000
                BEEP_OFF

                call scroll_up
                call scroll_up
                PRINT_XYC 0, 24, ATTR_CYAN, @MAP:"    HIT RETURN KEY"
                call scroll_up
                BEEP_ON
                WAIT_N 15000
                BEEP_OFF

                call wait_all_key_release
.loop           call get_key
                cp "\r"
                jr nz, .loop
                ret

;----------------------------
; ゲーム終了後、リトライ確認画面
;----------------------------
display_retry_message:
                 PRINT_XYC 7,  9, ATTR_CYAN, @MAP:"■■■■■■■■■■■■■■■■"
                 PRINT_XYC 7, 10, ATTR_CYAN, @MAP:"■　　　　　　　　　　　　　　■"
                 PRINT_XYC 7, 11, ATTR_CYAN, @MAP:"■　　　　　　　　　　　　　　■"
                 PRINT_XYC 7, 12, ATTR_CYAN, @MAP:"■　　　　　　　　　　　　　　■"
                 PRINT_XYC 7, 13, ATTR_CYAN, @MAP:"■　　　　　　　　　　　　　　■"
                 PRINT_XYC 7, 14, ATTR_CYAN, @MAP:"■　　　　　　　　　　　　　　■"
                 PRINT_XYC 7, 15, ATTR_CYAN, @MAP:"■■■■■■■■■■■■■■■■"
                 BEEP_ON            
                 WAIT_N 15000
                 BEEP_OFF
                 PRINT_XYC 8, 10, ATTR_YELLOW, @MAP:"＃＃＃＃＃＃＃＃＃＃＃＃＃＃"
                 PRINT_XYC 8, 11, ATTR_YELLOW, @MAP:"＃　　　　　　　　　　　　＃"
                 PRINT_XYC 8, 12, ATTR_YELLOW, @MAP:"＃　　　　　　　　　　　　＃"
                 PRINT_XYC 8, 13, ATTR_YELLOW, @MAP:"＃　　　　　　　　　　　　＃"
                 PRINT_XYC 8, 14, ATTR_YELLOW, @MAP:"＃＃＃＃＃＃＃＃＃＃＃＃＃＃"
                 BEEP_ON            
                 WAIT_N 15000
                 BEEP_OFF
                 PRINT_XYC 9, 11, ATTR_BLUE, @MAP:"＊＊＊＊＊＊＊＊＊＊＊＊"
                 PRINT_XYC 9, 12, ATTR_BLUE, @MAP:"＊　　　　　　　　　　＊"
                 PRINT_XYC 9, 13, ATTR_BLUE, @MAP:"＊＊＊＊＊＊＊＊＊＊＊＊"
                 BEEP_ON            
                 WAIT_N 15000
                 BEEP_OFF
                 PRINT_XYC 11, 12, ATTR_WHITE, @MAP:"GAME OVER"
                 BEEP_ON            
                 WAIT_N 15000
                 BEEP_OFF
                 PRINT_XYC 5, 18, ATTR_MAGENTA, @MAP:"                       "
                 PRINT_XYC 5, 19, ATTR_MAGENTA, @MAP:"PLAY AGAIN = RETURN key"
                 PRINT_XYC 5, 20, ATTR_MAGENTA, @MAP:"                       "
                 ret
                  

;------------------------------
; DE 回ループで wait
;------------------------------
wait_loop:
.loop           ld  a, d
                or  e
                jr  z, .ret
                dec de
                jr  .loop
.ret
                ret


; == 以降機種依存処理
                include "sub_mz700.asm"
; パッチ処理
                include "patch.asm"

;----------------------------
; space mouse 本体読込
;----------------------------
                org space_mouse_top_addr

                include "machine.bin", B

                end start

