rom_hot_start:
                ; jp $0082 ; newmon7 実ROM だと $00AD?
                jp $0000

        
;----------------------------
; PCG へキャラクタ転送
;----------------------------
ex_init_pcg:
                ; 80-cf copy from CGROM
                ld de, 0
                ld bc, $40 * 8
.code_80_BF
                call .write_pat_from_cgrom
                inc de
                dec bc
                ld a, b
                or c
                jr nz, .code_80_BF

                ; c0-df from space mouse 80-9F
                ld hl, space_mouse_top_addr + $10
                ld bc, $20 * 8
.code_C0_DF
                call .write_pat
                inc hl
                inc de
                dec bc
                ld a, b
                or c
                jr nz, .code_C0_DF

                ; e0-ff fromm space mouse E0-FF
                ld hl, space_mouse_top_addr + $10 + $60 * 8
                ld bc, $20 * 8
.code_E0_FF
                call .write_pat
                inc hl
                inc de
                dec bc
                ld a, b
                or c
                jr nz, .code_E0_FF
        
                ret
        
.write_pat_from_cgrom
                ld a, e
                ld ($e011), a
                ld a, d
                or $30
                ld ($e012), a
                xor a
                ld ($e012), a
                ret

.write_pat   
                ld a, (hl)
                ld ($e010), a
                ld a, e
                ld ($e011), a
                ld a, d
                or $10
                ld ($e012), a
                xor a
                ld ($e012), a
                ret
        
;----------------------------
; 画面設定初期化
;----------------------------
init_screen:
                ; PCG off
                ld a, $08
                ld ($e012), a
                ret

rom_cls:        ld hl, vram_addr
                ld de, vram_addr + 1
                ld (hl), 0
                ld bc, 999
                ldir

                ld hl, vram_addr + $800
                ld de, vram_addr + $800 + 1
                ld (hl), $70
                ld bc, 999
                ldir
        
                ret

;----------------------------
; 座標、色を指定文字列表示
; d:y , e: x, b: color, hl: msg
;----------------------------
puts:           push hl
                push de
                ; hl = 40 * y + x
                ld h, 0
                ld l, d
                push hl
                add hl, hl
                add hl, hl
                pop de
                add hl, de
                add hl, hl
                add hl, hl
                add hl, hl
                pop de
                ld d, 0
                add hl, de
                ld de, vram_addr
                add hl, de
                push hl
                push hl
                pop ix
                ld de, $0800
                add ix, de
                pop de
                ; de = vram
                ; ix = attr

                pop hl
.puts_loop      ld a, (hl)
                cp EOS
                jr z, .reach_EOS
                ld (de), a
                ld (ix + 0), b
                inc hl
                inc de
                inc ix
                jp .puts_loop
.reach_EOS
                ret

key_strobe      macro strobe
                ld a, strobe
                ld ($e000), a
                ld a, ($e001)
                endm

;----------------------------
; y, n, cr 入力チェック。入力まで待つ
;----------------------------
get_key:
                key_strobe 1
                bit 7, a
                jr nz, .check_N
                ld a, "Y"
                ret

.check_N        key_strobe 3
                bit 2, a
                jr nz, .check_CR
                ld a, "N"
                ret

.check_CR       key_strobe 0
                bit 0, a
                jr nz, get_key
                ld a, "\r"
                ret

; ---------------------------
; y, n, cr が離されるまで待つ
; ---------------------------
wait_all_key_release:
                ld b, $ff
                key_strobe 1
                and b
                ld b, a
                key_strobe 3
                and b
                ld b, a
                key_strobe 0
                and b
        
                cp $ff
                jr nz, wait_all_key_release

                ret
        
; ---------------------------
; beep
; ---------------------------
rom_beep:       or a
                jr nz, .beep_on
                ld ($e008), a
                ret
.beep_on        ld a, $36
                ld ($e007), a
                ld hl, $e004
                ;
                ; pc80 2.4 kHz, mz700 894.88625 kHz
                ; 分周比 373 = 0x175
                ld (hl), $75
                ld (hl), $01
                ; ld (hl), $f9
                ; ld (hl), $03
        
                ld a, 1
                ld ($e008), a

                ret

;----------------------------
; 1行スクロール
;----------------------------
scroll_up:      ld hl, xy2vram(0, 1)
                ld de, xy2vram(0, 0)
                ld bc, 40 * 24
                ldir
                ; 最下行クリア
                ld b, 40
                ld hl, xy2vram(0, 24)
                xor a
.loop1          ld (hl), a
                inc hl
                djnz .loop1

                ld hl, xy2attr(0, 1)
                ld de, xy2attr(0, 0)
                ld bc, 40 * 24
                ldir
                ;
                ld b, 40
                ld hl, xy2attr(0, 24)
                ld a, $70
.loop2          ld (hl), a
                inc hl
                djnz .loop2

                ret

;----------------------------
; ATTR を初期画面の状態で設定
;----------------------------
support_init_attr:  
                ld hl, xy2attr(0, 0) ; d800
                ld b, 25
.outer_loop     
                ; yellow
                push bc
                call init_attr_line
                pop bc
                djnz .outer_loop
                ret

init_attr_line:
                ld b, 5
                ld a, ATTR_YELLOW
.loop1          ld (hl), a
                inc hl
                djnz .loop1
                ; green
                ld b, 23
                ld a, ATTR_GREEN
.loop2          ld (hl), a
                inc hl
                djnz .loop2
                ; white
                ld b, 12
                ld a, ATTR_WHITE
.loop3          ld (hl), a
                inc hl
                djnz .loop3

                ret
;----------------------------
; x, y からvram offset 算出
; H: x(0..) L: y(1..) xも1からのはずなのだが
;----------------------------
rom_xy_vram_ofs:
                ; dec h ; x は 0-?
                push bc
                push de
                dec l
                ld c, h
                ld h, 0
                push hl
                pop de
                add hl, hl
                add hl, hl
                add hl, de
                add hl, hl
                add hl, hl
                add hl, hl
                ld e, c
                ld d, 0
                add hl, de
                ld de, vram_addr
                add hl, de
                pop de
                pop bc
                ret 

;----------------------------
;
;----------------------------
rom_attr_control:
                call rom_xy_vram_ofs
                push de
                ld de, $800
                add hl, de
                ld (hl), a
                pop de
                ret

;----------------------------
; x, y (HL) から MAN (A) を 黄色で表示（ボツ）
;----------------------------
disp_man_sub:
               call rom_xy_vram_ofs
               ld (hl), a
               ld de, $800
               add hl, de
               ld (hl), ATTR_CYAN
               ret

;----------------------------
; キャラクタ消去
; 消去後、オリジナルは白にしていたがスクロール時の色ずれの原因になっていたため、
; (5, キャラクタ行) の色＝壁の色に変更
;----------------------------
rom_hide_char:
                push hl
                push de
                ld de, space_mouse_top_addr + $10fd ; WK_CAPT_E0FD
                xor a
                ld (de), a   ; (WK_CAPT_E0FD), 0
                ;
                ld h, 5
                call rom_xy_vram_ofs
                ld de, $800
                add hl, de
                ld a, (hl)   ; color (5, current)
                pop de
                pop hl
                ret

;----------------------------
; ステージの色設定 
;----------------------------
rom_set_line_attr:
                push bc
                ld b, 23
.loop           ld (hl), a
                inc hl
                djnz .loop
                pop bc
                ret

;----------------------------
; 数字と矢印を判定
; 戻り先は caller の次にアドレスを配置
;----------------------------
rom_get_key:
                pop ix
                ; 数字
                ld a, 5
                ld ($e000), a
                ld a, ($e001)
                bit 4, a
                jr z, .key_4
                bit 2, a
                jr z, .key_6
                bit 0, a
                jr z, .key_8
                ; 矢印
                ld a, 7
                ld ($e000), a
                ld a, ($e001)
                bit 2, a
                jr z, .key_4
                bit 3, a
                jr z, .key_6
                bit 5, a
                jr z, .key_8
                ld a, $ff
                ret

.key_4          jp (ix)

.key_6          inc ix
                inc ix
                jp (ix) 

.key_8          inc ix
                inc ix
                inc ix
                inc ix
                jp (ix)


;----------------------------
; ゲーム中に Q が押されたら終了（game over）
;----------------------------
rom_check_quit:
                ld a, 2
                ld ($e000), a
                ld a, ($e001)
                bit 7, a
                ret

;----------------------------
; ステージ範囲だけスクロール
;----------------------------
rom_scroll_stage:
                ld b, 24
                ld hl, xy2vram(5, 23)
                ld de, xy2vram(5, 24)
.scroll_line    push bc
                ld bc, 23
                ldir
                ; next line
                ld bc, -63
                add hl, bc
                push hl
                ld h, d
                ld l, e
                add hl, bc
                ld d, h
                ld e, l
                pop hl
                ;
                pop bc
                djnz .scroll_line

                ld b, 24
                ld hl, xy2attr(5, 23)
                ld de, xy2attr(5, 24)
.scroll_attr    
                push bc
                ld bc, 23
                ldir
                ; next line
                ld bc, -63
                add hl, bc
                push hl
                ld h, d
                ld l, e
                add hl, bc
                ld d, h
                ld e, l
                pop hl
                ;
                pop bc
                djnz .scroll_attr

.init_line0 
                ld hl, xy2vram(6, 0)
                ld de, xy2vram(7, 0)
                ld (hl), 0
                ld bc, 20
                ldir

                ld hl, xy2attr(5, 0)
                ld de, xy2attr(6, 0)
                ld bc, 23
                ldir

                ret

