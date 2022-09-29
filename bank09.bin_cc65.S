; Target assembler: cc65 v2.18.0 [--target none -C bank09.bin_cc65.cfg]
; 6502bench SourceGen v1.8.3
         .setcpu "65816"
TMP_PTR1 =       $1b        ; temporary ZP pointer 
TMP_PTR_L =      $f6        ; temporary ZP long pointer
TMP_PTR_H =      $f7
TMP_PTR_VH =     $f8
TMP_PTR_XH =     $f9
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
REG_5380_MODE_SEL = $c002   ; RW Mode select register
REG_5380_STAT =  $c004      ; R SCSI status
REG_5380_STAT2 = $c005      ; R Bus and status register
REG_IO_PDMA_DACK = $c008    ; RW PDMA/DACK
REG_IO_BANK_SEL = $c00a     ; W memory bank select
REG_IO_5380_RST = $c00b     ; W 5380 Reset
REG_IO_DRQ =     $c00e      ; R read DRQ on bit7
CYAREG   =       $c036      ;RW Configure Your Apple
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B2 =      $c802      ; timeout counter MSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
SAVE_CYAREG =    $c808      ; saved value of CYAREG
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SCSI_CMD_LEN =   $c80d      ; SCSI COMMAND lenght
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SCSI_CDB_LEN =   $c812
SAVE_Y   =       $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
CMD_STATUS =     $c81e      ; SCSI CMD status - 0x00 OK, 0x02 Check condition
UNK_c827 =       $c827      ; 3-byte unknown in reverse endian as the above
LBA_c8db =       $c8db      ; LBA to use in CDB (?) (copied to CDB_LBA)
RX_LEN_LO =      $c8e4      ;bytes read if call successfull
RX_LEN_HI =      $c8e5      ;bytes read if call successfull
IIgs_PDMA =      $c8f3      ;0x01 if IIgs PDMA
BLKSIZE_H =      $c92f      ;byte1 of block size
LDIO_SIZE_LO =   $c9ee
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB
TIMEOUT  =       $c9f6      ; each unit is 1.25s

         .org    $cc00
         .a8
         .i8
LCC00:   lda     SCSI_CDB_CMD
         cmp     #$08
         bne     @LCC46
         jsr     CALL_FN_61
         lda     #$00
         tay
         sta     $c9f1
         sta     DEV_STATUS-1
         lda     $c9ef
         beq     @LCC45
         tsx
         cpx     #$60
         bcc     @LCC22
         lda     IIgs_PDMA
         bne     @LCC3A
@LCC22:  ldx     SAVE_Y
         lda     IIgs_PDMA
         beq     @LCC36
         lda     CALL_TYPE
         and     #$40
         beq     @LCC36
         lda     #$b4
         jmp     CALL_FN_X9 ;CALL_FN_B4

@LCC36:  jsr     LCC68
         rts

@LCC3A:  lda     CYAREG
         sta     SAVE_CYAREG
         lda     #$3f
         jsr     CALL_FN_X9 ;CALL_FN_3F
@LCC45:  rts

@LCC46:  jsr     CALL_FN_71
         lda     #$00
         tay
         sta     $c9f1
         sta     DEV_STATUS-1
         lda     CALL_TYPE
         and     #$40
         beq     CALL_FN_6C
         lda     IIgs_PDMA
         bne     CALL_FN_5C
CALL_FN_6C:
         lda     #$6c
         jmp     CALL_FN_X9

CALL_FN_5C:
         lda     #$5c
         jmp     CALL_FN_X9

LCC68:   lda     REG_IO_DRQ,x
         bpl     @LCC8D
         lda     REG_IO_PDMA_DACK,x
         sta     (BUF_PTR_L),y
         iny
         bne     LCC68
         lda     #$00
         sta     TCOUNT_B1
         inc     BUF_PTR_H
         bne     @LCC80
         inc     BUF_PTR_VH
@LCC80:  inc     DEV_STATUS-1
         lda     DEV_STATUS-1
         cmp     $c9ef
         bne     LCC68
         beq     @LCCA0

@LCC8D:  lda     REG_5380_STAT2,x
         and     #$08
         beq     @LCCA0
         dec     TCOUNT_B0
         bne     LCC68
         dec     TCOUNT_B1
         beq     @LCCA2
         bne     LCC68

@LCCA0:  clc
         rts

@LCCA2:  sec
         sty     $c9f1
         rts

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
         .byte   $38
         .byte   $60
         .byte   $ad
         .byte   $00
         .byte   $ca
         .byte   $29
         .byte   $04
         .byte   $60
         .byte   $a9
         .byte   $3b
         .byte   $4c
         .byte   $4c
         .byte   $cd

FN_09:   jsr     LCD55
         bcc     @LCCCC
         lda     #$07
         jmp     CALL_FN_X9 ;CALL_FN_07

@LCCCC:  jsr     LCEC5
         lda     $c9ef
         bne     @LCCDE
         lda     LDIO_SIZE_LO
         bne     @LCCDE
         lda     #$22
         jmp     CALL_FN_60_RET ;FAIL_BADCTRLPARM

@LCCDE:  jsr     LCD92
         jsr     LCF5D
         jsr     CALL_FN_00
         jsr     LCECF
         bcs     @LCCEF
         jsr     FN_29
@LCCEF:  jsr     LCF23
         jsr     LCDC1
         lda     CMD_STATUS
         bne     @LCCFB
         rts

@LCCFB:  jsr     FN_39
         bcs     FAIL_IOERROR_DUP
         rts

FAIL_IOERROR_DUP:
         lda     #$27
         jmp     CALL_FN_60_RET

FN_19:   lda     DEV_STATUS
         cmp     #$b4
         bne     @LCD15
         lda     #$2b       ;ERROR_NOWRITE
         ldy     SAVE_Y
         jmp     CALL_FN_60_RET ;ERROR_NOWRITE

@LCD15:  jsr     LCD55
         bcc     @LCD1F
         lda     #$07
         jmp     CALL_FN_X9 ;CALL_FN_07

@LCD1F:  jsr     LCEC5
         lda     BLKSIZE_H-1
         bne     @LCD31
         lda     $c92d
         bne     @LCD31
         lda     #$27
         jmp     CALL_FN_60_RET ;ERROR_IOERROR

@LCD31:  jsr     LCD84
         jsr     LCF5D
         jsr     CALL_FN_00
         jsr     LCF06
         jsr     CALL_FN_71
         jsr     FN_29
         jsr     LCF23
         jsr     LCDC1
         rts

CALL_FN_00:
         lda     #$00
CALL_FN_X9:
         ldx     #$09
         ldy     SAVE_Y
         jsr     BANKSWITCH
         rts

LCD55:   lda     DEV_STATUS
         and     #$80
         bne     @LCD5E
         sec
         rts

@LCD5E:  clc
         rts

CALL_FN_61:
         lda     #$61
         jmp     CALL_FN_X9

CALL_FN_71:
         lda     #$71
         jmp     CALL_FN_X9

         .byte   $a9
         .byte   $54
         .byte   $4c
         .byte   $4c
         .byte   $cd

FN_29:   jsr     LCC00
         jsr     SET_TIMEOUT_03
         jsr     LCDC6
         ldy     SAVE_Y
         lda     #$00
         sta     REG_IO_5380_RST,y
         sta     REG_5380_MODE_SEL,y
         rts

LCD84:   lda     #$0a
         sta     SCSI_CDB_CMD
         ldx     #$06
         stx     SCSI_CMD_LEN
         jsr     LCDAB
         rts

LCD92:   lda     #$08
         sta     SCSI_CDB_CMD
         ldx     #$06
         stx     SCSI_CMD_LEN
         jsr     LCDAB
         rts

         .byte   $a9
         .byte   $00
         .byte   $a2
         .byte   $06
         .byte   $9d
         .byte   $0e
.macro   HiAscii Arg
         .repeat .strlen(Arg), I
         .byte   .strat(Arg, I) | $80
         .endrep
.endmacro
         HiAscii "HJPz"
         .byte   $60

LCDAB:   lda     $c92d
         ldx     $c929
         bne     @LCDBA
         ldx     $c92a
         bne     @LCDBA
         beq     @LCDBD

@LCDBA:  clc
         adc     #$01
@LCDBD:  sta     SCSI_CDB_LEN
         rts

LCDC1:   lda     #$30
         jmp     CALL_FN_X9

LCDC6:   ldy     #$00
         ldx     SAVE_Y
@LCDCB:  lda     REG_IO_DRQ,x
         bpl     @LCE04
         lda     $c9f1
         cmp     LDIO_SIZE_LO
         bne     @LCDDA
         beq     @LCE17

@LCDDA:  lda     CALL_TYPE
         and     #$40
         beq     @LCDE8
         lda     IIgs_PDMA
         cmp     #$01
         beq     @LCDF0
@LCDE8:  lda     REG_IO_PDMA_DACK,x
         sta     (BUF_PTR_L),y
         jmp     @LCDF5

@LCDF0:  lda     REG_IO_PDMA_DACK,x
         sta     [BUF_PTR_L],y
@LCDF5:  iny
         bne     @LCDFE
         inc     BUF_PTR_H
         bne     @LCDFE
         inc     BUF_PTR_VH
@LCDFE:  inc     $c9f1
         clc
         bcc     @LCDCB

@LCE04:  lda     REG_5380_STAT2,x
         and     #$08
         beq     @LCE35
         dec     TCOUNT_B0
         bne     @LCDCB
         dec     TCOUNT_B1
         beq     @LCE38
         bne     @LCDCB

@LCE17:  lda     REG_IO_DRQ,x
         bpl     @LCE22
         lda     REG_IO_PDMA_DACK,x
         clc
         bcc     @LCE17

@LCE22:  lda     REG_5380_STAT2,x
         and     #$08
         beq     @LCE35
         dec     TCOUNT_B0
         bne     @LCE17
         dec     TCOUNT_B1
         beq     @LCE38
         bne     @LCE17

@LCE35:  clc
         bcc     @LCE39

@LCE38:  sec
@LCE39:  lda     $c9f1
         sta     RX_LEN_LO
         lda     DEV_STATUS-1
         sta     RX_LEN_HI
         rts

FN_39:   lda     IIgs_PDMA
         sta     $c82e
         lda     #$00
         sta     IIgs_PDMA
         jsr     FN_49
         lda     $c82e
         sta     IIgs_PDMA
         ldx     #$02
         lda     $c901,x
         cmp     #$06
         beq     LCEA1
         cmp     #$02
         beq     LCEA1
         and     #$07
         cmp     #$01
         beq     @LCE70
         sec
         bcs     @LCE71

@LCE70:  clc
@LCE71:  ldy     SAVE_Y
         rts

FN_49:   lda     #$01
         sta     TMP_PTR_L
         lda     #$c9
         sta     TMP_PTR_H
         lda     #$00
         sta     TMP_PTR_VH
         lda     #$67
         jsr     CALL_FN_X9
         ldy     #$02
         lda     TMP_PTR_L
         sta     (TMP_PTR_L),y
         iny
         lda     TMP_PTR_H
         sta     (TMP_PTR_L),y
         iny
         lda     #$00
         sta     (TMP_PTR_L),y
         lda     #$b3
         jsr     CALL_FN_X9
         lda     #$77
         jsr     CALL_FN_X9
         rts

LCEA1:   lda     #$00
         sta     TMP_PTR_VH
         sta     TMP_PTR_XH
         sta     CALL_TYPE
         lda     #$66
         jmp     CALL_FN_X9 ;CALL_FN_66

         .byte   $4c
         .byte   $01
         .byte   $cd

FN_69:   lda     #$08
         bne     LCEB8

FN_59:   lda     #$02
LCEB8:   sta     $c82a
         lda     #$00
         sta     $c82b
         lda     #$aa
         jmp     CALL_FN_X9 ;CALL_FN_AA

LCEC5:   lda     #$0b
         jsr     CALL_FN_X9 ;CALL_FN_0B
         lda     #$7c
         jmp     CALL_FN_X9 ;CALL_FN_7C

LCECF:   jsr     SET_TIMEOUT_03
         lda     TIMEOUT
         sta     TCOUNT_B1
@LCED8:  lda     REG_5380_STAT,y
         and     #$3c
         cmp     #$24
         beq     @LCEF7
         jsr     DEC_TIMEOUT3
         lda     TCOUNT_B1
         beq     @LCEFB
         lda     TCOUNT_B0
         bne     @LCED8
         lda     REG_5380_STAT,y
         cmp     #$6c
         beq     @LCEF9
         bne     @LCED8

@LCEF7:  clc
         rts

@LCEF9:  sec
         rts

@LCEFB:  lda     REG_5380_STAT,y
         and     #$3c
         cmp     #$2c
         beq     @LCEF9
         bne     FAIL_IOERROR

LCF06:   jsr     SET_TIMEOUT_03
         lda     TIMEOUT
         sta     TCOUNT_B1
@LCF0F:  lda     REG_5380_STAT,y
         and     #$3c
         cmp     #$20
         beq     @LCF22
         jsr     DEC_TIMEOUT3
         lda     TCOUNT_B1
         beq     FAIL_IOERROR
         bne     @LCF0F

@LCF22:  rts

LCF23:   jsr     SET_TIMEOUT_03
@LCF26:  lda     REG_5380_STAT,y
         and     #$3c
         cmp     #$2c
         beq     @LCF36
         jsr     DEC_TIMEOUT3
         bcs     FAIL_IOERROR
         bcc     @LCF26

@LCF36:  rts

SET_TIMEOUT_03:
         lda     #$ff
         sta     TCOUNT_B0
         sta     TCOUNT_B2
         lda     #$03
         sta     TCOUNT_B1
         rts

DEC_TIMEOUT3:
         dec     TCOUNT_B0
         bne     @LCF54
         dec     TCOUNT_B2
         bne     @LCF54
         dec     TCOUNT_B1
         beq     @LCF56
@LCF54:  clc
         rts

@LCF56:  sec
         rts

FAIL_IOERROR:
         lda     #$27
         jmp     CALL_FN_60_RET

LCF5D:   clc
         lda     LBA_c8db
         adc     $c92d
         sta     $c911
         lda     LBA_c8db+1
         adc     #$00
         sta     $c912
         lda     LBA_c8db+2
         adc     #$00
         sta     $c913
         bcs     FAIL_BADBLOCK
         lda     $c913
         sec
         sbc     UNK_c827
         bcc     @LCF9A
         bne     FAIL_BADBLOCK
         lda     $c912
         sec
         sbc     UNK_c827+1
         bcc     @LCF9A
         bne     FAIL_BADBLOCK
         lda     $c911
         sec
         sbc     UNK_c827+2
         bcc     @LCF9A
         bne     FAIL_BADBLOCK
@LCF9A:  rts

FAIL_BADBLOCK:
         lda     #$2d
         jmp     CALL_FN_60_RET

CALL_FN_60_RET:
         sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH

FN_TABLE:
         .word   FN_09
         .word   FN_19
         .word   FN_29
         .word   FN_39
         .word   FN_49
         .word   FN_59
         .word   FN_69
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
         jsr     DO_FN_CALL
         pla
         and     #$0f
         sta     REG_IO_BANK_SEL,y
         clc
         rts

DO_FN_CALL:
         jmp     (TMP_PTR1)

         .byte   $d7
         .byte   $00
         .byte   $00
         .byte   $00
