; Target assembler: cc65 v2.18.0 [--target none -C bank13.bin_cc65.cfg]
; 6502bench SourceGen v1.8.3
         .setcpu "65816"
TMP_PTR0 =       $19        ; temporary ZP pointer 
TMP_PTR1 =       $1b        ; temporary ZP pointer 
TMP_PTR_L =      $f6        ; temporary ZP long pointer
TMP_PTR_H =      $f7
TMP_PTR_VH =     $f8
TMP_PTR_XH =     $f9
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
REG_5380_MODE_SEL = $c002   ; RW Mode select register
REG_5380_STAT2 = $c005      ; R Bus and status register
REG_IO_PDMA_DACK = $c008    ; RW PDMA/DACK
REG_IO_BANK_SEL = $c00a     ; W memory bank select
REG_IO_5380_RST = $c00b     ; W 5380 Reset
REG_IO_DRQ =     $c00e      ; R read DRQ on bit7
CYAREG   =       $c036      ;RW Configure Your Apple
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B2 =      $c802      ; timeout counter MSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
XFER_MODE =      $c804      ; 0x00 IIe PDMA, 0x01 IIgs PDMA, 0x02-0xff PIO 
SAVE_CYAREG =    $c808      ; saved value of CYAREG
TMP_c80a =       $c80a      ; unknown
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SAVE_Y   =       $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
UNK_c820 =       $c820      ; 0xff if PIO ?
UNK_c827 =       $c827      ; 3-byte unknown in reverse endian as the above
TEMP_c8ca =      $c8ca      ; TEMP_BUF_PTR?
UNK_c8cc =       $c8cc      ;unknown
SAVE_SP2 =       $c8ed      ;saved SP - also used a random temp
IIgs_PDMA =      $c8f3      ;0x01 if IIgs PDMA
SAVE_XFER_MODE = $c91f
TEMP_VH  =       $c921      ;unknown
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB
TIMEOUT  =       $c9f6      ; each unit is 1.25s

         .org    $cc00
         .a8
         .i8
FN_0D:   lda     #$86
         ldy     #$00
         sty     TMP_c80a
         sta     (TMP_PTR0),y
         iny
         iny
         jsr     @LCC73
         jsr     FN_4D
         jsr     @LCC84
         jsr     LCDC7
         lda     #$00
         sta     TMP_c80a
@LCC1C:  lda     $ca00,x
         cmp     #$20
         bmi     @LCC2F
         beq     @LCC2F
         cmp     #$7a
         bpl     @LCC2F
         sta     (TMP_PTR0),y
         iny
         inc     TMP_c80a
@LCC2F:  inx
         cpx     #$21
         bpl     @LCC3F
         lda     TMP_c80a
         cmp     #$10
         beq     @LCC3F
         bmi     @LCC1C
         beq     @LCC3F
@LCC3F:  tya
         pha
         ldy     #$06
         lda     TMP_c80a
         sta     (TMP_PTR0),y
         pla
         tay
         lda     #$10
         sec
         sbc     TMP_c80a
         sta     TMP_c80a
         beq     @LCC61
         bmi     @LCC61
         lda     #$20
@LCC59:  sta     (TMP_PTR0),y
         iny
         dec     TMP_c80a
         bne     @LCC59
@LCC61:  jsr     @LCCCC
         ldx     #$01
@LCC66:  iny
         lda     @LCD3B,x
         sta     (TMP_PTR0),y
         dex
         bpl     @LCC66
         ldy     SAVE_Y
         rts

@LCC73:  ldx     #$02
@LCC75:  lda     UNK_c827,x
         sta     (TMP_PTR0),y
         iny
         dex
         bpl     @LCC75
         lda     #$00
         sta     (TMP_PTR0),y
         iny
         rts

@LCC84:  iny
         tya
         pha
         ldx     #$00
         lda     $ca00,x
         beq     @LCCA8
         cmp     #$01
         beq     @LCCB4
         cmp     #$02
         beq     @LCCB8
         cmp     #$04
         beq     @LCCBC
         cmp     #$05
         beq     @LCCC0
         cmp     #$06
         beq     @LCCC4
         cmp     #$10
         beq     @LCCA8
         bne     @LCCC8

@LCCA8:  lda     #$f8
@LCCAA:  sta     DEV_STATUS
         ldy     #$01
         sta     (TMP_PTR0),y
         pla
         tay
         rts

@LCCB4:  lda     #$78
         bne     @LCCAA

@LCCB8:  lda     #$58
         bne     @LCCAA

@LCCBC:  lda     #$f0
         bne     @LCCAA

@LCCC0:  lda     #$b4
         bne     @LCCAA

@LCCC4:  lda     #$38
         bne     @LCCAA

@LCCC8:  lda     #$00
         beq     @LCCAA

@LCCCC:  lda     DEV_STATUS
         cmp     #$b4
         bne     @LCCD7
         lda     #$05
         bne     @LCD27

@LCCD7:  cmp     #$f8
         bne     @LCD0D
         lda     $ca01
         and     #$80
         bne     @LCCE6
         lda     #$07
         bne     @LCD27

@LCCE6:  tya
         pha
         lda     TMP_PTR0
         sta     SAVE_XFER_MODE
         lda     TMP_PTR0+1
         sta     TEMP_VH-1
         lda     #$9c
         jsr     CALL_FN_XD ;CALL_FN_9C
         lda     #$35
         ldy     #$0e
         sta     (TMP_PTR0),y
         lda     SAVE_XFER_MODE
         sta     TMP_PTR0
         lda     TEMP_VH-1
         sta     TMP_PTR0+1
         pla
         tay
         lda     #$06
         bne     @LCD27

@LCD0D:  cmp     #$78
         bne     @LCD15
         lda     #$06
         bne     @LCD27

@LCD15:  cmp     #$58
         bne     @LCD1D
         lda     #$09
         bne     @LCD27

@LCD1D:  cmp     #$38
         bne     @LCD25
         lda     #$08
         bne     @LCD27

@LCD25:  lda     #$03
@LCD27:  sta     (TMP_PTR0),y
         lda     $ca01
         bpl     @LCD32
         lda     #$c0
         bne     @LCD34

@LCD32:  lda     #$a0
@LCD34:  iny
         sta     (TMP_PTR0),y
         rts

         .byte   $4c
         .byte   $58
         .byte   $cf
@LCD3B:  .byte   $02
         .byte   $00

FN_4D:   tya
         pha
         ldx     #$03
@LCD41:  lda     BUF_PTR_L,x
         sta     $c82c,x
         dex
         bpl     @LCD41
         lda     TMP_PTR0
         sta     $c9f4
         lda     TMP_PTR0+1
         sta     TIMEOUT-1
         lda     TMP_PTR_L
         sta     TEMP_c8ca
         lda     TMP_PTR_H
         sta     UNK_c8cc-1
         lda     TMP_PTR_VH
         sta     $c925
         lda     TMP_PTR_XH
         sta     $c926
         lda     #$00
         sta     TMP_PTR_L
         lda     #$ca
         sta     TMP_PTR_H
         ldy     #$02
         lda     TMP_PTR_L
         sta     (TMP_PTR_L),y
         iny
         lda     TMP_PTR_H
         sta     (TMP_PTR_L),y
         iny
         lda     #$00
         sta     TMP_PTR_VH
         sta     TMP_PTR_XH
         sta     (TMP_PTR_L),y
         iny
         sta     (TMP_PTR_L),y
         lda     #$93
         jsr     CALL_FN_XD ;CALL_FN_93
         ldx     #$03
@LCD8D:  lda     $c82c,x
         sta     BUF_PTR_L,x
         dex
         bpl     @LCD8D
         lda     $c9f4
         sta     TMP_PTR0
         lda     TIMEOUT-1
         sta     TMP_PTR0+1
         lda     TEMP_c8ca
         sta     TMP_PTR_L
         lda     UNK_c8cc-1
         sta     TMP_PTR_H
         lda     $c925
         sta     TMP_PTR_VH
         lda     $c926
         sta     TMP_PTR_XH
         pla
         tay
         rts

         .byte   $99
         .byte   $0b
         .byte   $c0
         .byte   $a9
         .byte   $27
         .byte   $4c
         .byte   $58
         .byte   $cf

CALL_FN_XD:
         ldy     SAVE_Y
         ldx     #$0d
         jsr     BANKSWITCH
         rts

LCDC7:   tya
         pha
         ldx     #$00
         ldy     #$07
@LCDCD:  iny
         cpy     #$18
         beq     @LCE01
         lda     $ca00,y
         cmp     #$20
         bmi     @LCDCD
         beq     @LCDCD
         cmp     #$7a
         beq     @LCDE1
         bpl     @LCDCD
@LCDE1:  tya
         pha
@LCDE3:  inx
         iny
         cmp     #$18
         beq     @LCDF8
         lda     $ca00,y
         cmp     #$20
         beq     @LCDF8
         bpl     @LCDE3
         cmp     #$7a
         bmi     @LCDE3
         beq     @LCDE3
@LCDF8:  txa
         sta     TMP_c80a
         pla
         tax
         pla
         tay
         rts

@LCE01:  txa
         sta     TMP_c80a
         pla
         tay
         rts

FN_1D:   lda     #$15
         jsr     CALL_FN_XD ;CALL_FN_15
         lda     #$bf
         jsr     CALL_FN_XD ;CALL_FN_BF
         lda     UNK_c827
         beq     @LCE1F
         lda     #$ff
         sta     UNK_c827+1
         sta     UNK_c827+2
@LCE1F:  rts

FN_2D:   tsx
         stx     SAVE_SP2
         ldy     #$00
         txa
         cmp     #$60
         bcs     @LCE33
         lda     #$b5
         jsr     CALL_FN_XD ;CALL_FN_B5
         jmp     LCE90

@LCE33:  sbc     #$22
         tax
         stx     TMP_PTR0
         dex
         dex
         txs
         inx
         inx
         lda     SCSI_CDB_CMD
@LCE40:  lda     code_fragment,y
         sta     $0100,x
         inx
         iny
         cpy     #$08
         bne     @LCE58
         jsr     IS_NATIVE_MODE_REQ2
         bcs     @LCE58
         lda     #$97
         sta     $0100,x
         inx
         iny
@LCE58:  cpy     #$1e
         bne     @LCE40
         ldx     SAVE_Y
         lda     #$01
         sta     TMP_PTR0+1
         lda     SAVE_CYAREG
         ora     #$80
         sta     CYAREG
         ldy     #$00
         sty     TCOUNT_B0
         sty     TCOUNT_B1
         lda     #$02
         sta     TCOUNT_B2
         jsr     SET_NATIVE_IF_NEEDED
         jmp     (TMP_PTR0)

LCE7E:   nop
         jsr     IS_NATIVE_MODE_REQ2
         bcs     @LCE86
         sec
         xce
@LCE86:  ldx     SAVE_SP2
         txs
         lda     SAVE_CYAREG
         sta     CYAREG
LCE90:   lda     #$00
         ldy     SAVE_Y
         sta     REG_IO_5380_RST,y
         sta     REG_5380_MODE_SEL,y
         rts

code_fragment:
         lda     REG_IO_DRQ,x ;this fragment is copied on the stack
         bpl     @LCEAC
         lda     REG_IO_PDMA_DACK,x
         sta     (BUF_PTR_L),y
         iny
         bne     code_fragment
         jmp     @LCECE

@LCEAC:  jmp     @LCEBA

         .byte   $bd
         .byte   $0e
         .byte   $c0
         .byte   $10
         .byte   $f8
         .byte   $bd
         .byte   $08
         .byte   $c0
         .byte   $18
         .byte   $90
         .byte   $f5

@LCEBA:  dec     TCOUNT_B0
         bne     @LCEC4
         dec     TCOUNT_B1
         beq     @LCEE6
@LCEC4:  lda     REG_5380_STAT2,x
         and     #$08
         beq     @LCEEB
         jmp     (TMP_PTR0)

@LCECE:  dec     TCOUNT_B2
         beq     @LCEDC
         inc     BUF_PTR_H
         bne     @LCED9
         inc     BUF_PTR_VH
@LCED9:  jmp     (TMP_PTR0)

@LCEDC:  lda     #$13
         clc
         adc     TMP_PTR0
         sta     TMP_PTR0
         jmp     (TMP_PTR0)

@LCEE6:  lda     #$27
         sta     RET_CODE
@LCEEB:  jmp     LCE7E

         .byte   $a2
         .byte   $ff
         .byte   $ca
         .byte   $f0
         .byte   $09
         .byte   $b9
         .byte   $04
         .byte   $c0
         .byte   $29
         .byte   $20
         .byte   $f0
         .byte   $f6
         .byte   $18
         .byte   $60

set_carry_return:
         sec
         rts

SET_NATIVE:
         clc
         xce
         rts

         .byte   $38
         .byte   $fb
         .byte   $60

SET_NATIVE_IF_NEEDED:
         jsr     IS_NATIVE_MODE_REQ2
         bcs     set_carry_return ;just return should be ok
         jmp     SET_NATIVE

         .byte   $20
         .byte   $14
         .byte   $cf
         .byte   $b0
         .byte   $eb
         .byte   $4c
         .byte   $01
         .byte   $cf

IS_NATIVE_MODE_REQ2:
         lda     CALL_TYPE  ;this one is reverse return value vs the one in bank 15
         and     #$40
         beq     set_carry_return ;branch if not ext call
         lda     IIgs_PDMA
         cmp     #$01
         bne     set_carry_return ;branch if not IIgs
         clc
         rts

FN_3D:   lda     XFER_MODE  ;auto select XFER_MODE
         cmp     #$03       ;if(XFER_MODE==3) overrides the auto selection - not documented in manual
         bne     end_sel_xfer_mode
         lda     IIgs_PDMA
         cmp     #$01
         bne     SET_XFER_MODE_IIe_PDMA
         sta     XFER_MODE  ;set XFER_MODE IIgs PDMA
         jmp     end_sel_xfer_mode

SET_XFER_MODE_IIe_PDMA:
         lda     #$00
         sta     XFER_MODE
end_sel_xfer_mode:
         rts

FN_5D:   lda     #$ff
         sta     UNK_c820
         lda     XFER_MODE
         sta     TMP_c80a
         lda     #$03
         sta     XFER_MODE
         lda     BUF_PTR_VH
         sta     SAVE_CYAREG-1
         lda     #$00
         sta     BUF_PTR_VH
         rts

         .byte   $8d
         .byte   $0b
         .byte   $c8
         .byte   $a9
         .byte   $60
         .byte   $a2
         .byte   $00
         .byte   $4c
         .byte   $cc
         .byte   $cf
FN_TABLE:
         .word   FN_0D
         .word   FN_1D
         .word   FN_2D
         .word   FN_3D
         .word   FN_4D
         .word   FN_5D
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
BANKSWITCH:
         stx     BSW_SAVE_X
         tax
         lda     BSW_SAVE_X
         pha
         txa
         pha
         and     #$0f
         sta     REG_IO_BANK_SEL,y
         pla
         and     #$f0
         clc
         ror     A
         ror     A
         ror     A
         tax
         lda     FN_TABLE,x
         sta     TMP_PTR1
         inx
         lda     FN_TABLE,x
         sta     TMP_PTR1+1
         jsr     DO_CALL_FN
         pla
         and     #$0f
         sta     REG_IO_BANK_SEL,y
         clc
         rts

DO_CALL_FN:
         jmp     (TMP_PTR1)

         .byte   $00
         .byte   $00
         .byte   $00
         .byte   $00
