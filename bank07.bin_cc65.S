; Target assembler: cc65 v2.18.0 [--target none -C bank07.bin_cc65.cfg]
; 6502bench SourceGen v1.8.3
         .setcpu "65816"
TMP_PTR0 =       $19        ; temporary ZP pointer 
TMP_PTR1 =       $1b        ; temporary ZP pointer 
PD_PAR_BLK_LO =  $46        ;PRODOS input parameter Block lo
PD_PAR_BLK_HI =  $47        ;PRODOS input parameter Block hi
TMP_PTR_L =      $f6        ; temporary ZP long pointer
TMP_PTR_H =      $f7
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
BUF_PTR_XH =     $fd
REG_5380_STAT =  $c004      ; R SCSI status
REG_IO_BANK_SEL = $c00a     ; W memory bank select
DEV_IDX  =       $c800      ; index into the SDAT/DIBTAB tables
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B2 =      $c802      ; timeout counter MSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
XFER_MODE =      $c804      ; 0x00 IIe PDMA, 0x01 IIgs PDMA, 0x02-0xff PIO 
SEL_TARGET =     $c806      ; SCSI (BUS?) ID of selected target
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SCSI_CMD_LEN =   $c80d      ; SCSI COMMAND lenght
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SCSI_CDB_LUN =   $c80f      ; 
SCSI_CDB_LBA_HI = $c810
SCSI_CDB_LBA_LO = $c811
SCSI_CDB_LEN =   $c812
SAVE_Y   =       $c81a      ; slot adress (n+8)<<4 
SAVE_SP_CMD_B =  $c81b      ; saved SmartPort Command
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
PART_START =     $c824      ; partition start (3 bytes) seems to be in reverse endian (?)
UNK_c8cf =       $c8cf      ; unknown
PTR_c8d0 =       $c8d0      ; temp pointer storage (?)
PTR_c8d7 =       $c8d7      ; temp pointer storage (?)
TEMP_c8da =      $c8da      ;unknown
SAVE_SP_UNIT =   $c8e8      ; saved Smartport UNIT number
IIgs_PDMA =      $c8f3      ;0x01 if IIgs PDMA
BLKSIZE_H =      $c92f      ;byte1 of block size

         .org    $cc00
         .a8
         .i8
TCC00:   jsr     @LCC30
         jsr     LCC51
         jsr     @LCC3E
         lda     SCSI_CDB_CMD
         cmp     #$08
         beq     @LCC1A
         jsr     LCCFB
         jsr     LCC4D
         lda     #$65
         bne     @LCC22

@LCC1A:  jsr     LCCE7
         jsr     LCC49
         lda     #$55
@LCC22:  jsr     LCC40
         jmp     @LCC28

@LCC28:  jsr     LCD0F
         lda     #$30
         jmp     LCC40

@LCC30:  lda     #$17
         sta     REG_IO_BANK_SEL,y
         jsr     DEV_IDX
         lda     #$07
         sta     REG_IO_BANK_SEL,y
         rts

@LCC3E:  lda     #$00
LCC40:   ldy     SAVE_Y
         ldx     #$07
         jsr     BANKSWITCH
         rts

LCC49:   lda     #$61
         bne     LCC40

LCC4D:   lda     #$71
         bne     LCC40

LCC51:   jsr     @LCC95
         lda     SAVE_SP_CMD_B
         and     #$0f
         cmp     #$08
         bne     @LCC61
@LCC5D:  sta     SCSI_CDB_CMD
         rts

@LCC61:  lda     #$0a
         bne     @LCC5D

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
         .byte   $18
         .byte   $fb
         .byte   $60
         .byte   $38
         .byte   $fb
         .byte   $60
         .byte   $ad
         .byte   $1d
         .byte   $c8
         .byte   $29
         .byte   $40
         .byte   $f0
         .byte   $08
.macro   HiAscii Arg
         .repeat .strlen(Arg), I
         .byte   .strat(Arg, I) | $80
         .endrep
.endmacro
         HiAscii "-sHp"
         .byte   $03
         .byte   $20
         .byte   $75
         .byte   $cc

@LCC8A:  rts

@LCC8B:  lda     #$00
         ldx     #$06
         sta     SCSI_CDB_CMD,x
         dex
         beq     @LCC8A
@LCC95:  jsr     @LCC8B
         lda     CALL_TYPE
         and     #$40
         beq     @LCCA4
         lda     IIgs_PDMA
         bne     @LCCCA
@LCCA4:  lda     #$06
         sta     SCSI_CMD_LEN
         ldy     #$02
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_L
         iny
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_H
         iny
         lda     (TMP_PTR_L),y
         sta     SCSI_CDB_LBA_LO
         iny
         lda     (TMP_PTR_L),y
         sta     SCSI_CDB_LEN
         lda     #$00
         sta     BUF_PTR_VH
         sta     BUF_PTR_XH
@LCCC6:  ldy     SAVE_Y
         rts

@LCCCA:  lda     #$01
         sta     XFER_MODE
         ldy     #$02
         lda     [TMP_PTR_L],y
         sta     BUF_PTR_L
         iny
         lda     [TMP_PTR_L],y
         sta     BUF_PTR_H
         iny
         lda     [TMP_PTR_L],y
         sta     BUF_PTR_VH
         iny
         lda     [TMP_PTR_L],y
         sta     BUF_PTR_XH
         jmp     @LCCC6

LCCE7:   jsr     LCD23
@LCCEA:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$04
         beq     @LCCFA
         jsr     LCD31
         bcs     LCD44
         bcc     @LCCEA

@LCCFA:  rts

LCCFB:   jsr     LCD23
@LCCFE:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$00
         beq     @LCD0E
         jsr     LCD31
         bcs     LCD44
         bcc     @LCCFE

@LCD0E:  rts

LCD0F:   jsr     LCD23
@LCD12:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$0c
         beq     @LCD22
         jsr     LCD31
         bcs     LCD44
         bcc     @LCD12

@LCD22:  rts

LCD23:   lda     #$ff
         sta     TCOUNT_B0
         sta     TCOUNT_B2
         lda     #$03
         sta     TCOUNT_B1
         rts

LCD31:   dec     TCOUNT_B0
         bne     @LCD40
         dec     TCOUNT_B2
         bne     @LCD40
         dec     TCOUNT_B1
         beq     @LCD42
@LCD40:  clc
         rts

@LCD42:  sec
         rts

LCD44:   lda     #$27
         jmp     LCFA6

TCD49:   lda     #$00
         sta     TEMP_c8da-1
         sta     UNK_c8cf
         lda     $c92d
         cmp     SEL_TARGET
         bne     @LCD60
         lda     BLKSIZE_H-1
         cmp     #$44
         beq     @LCD88
@LCD60:  jsr     @LCD8C
         jsr     TCDAD
         lda     UNK_c8cf
         beq     @LCD74
         jsr     LCDD9
         lda     SAVE_SP_UNIT-1
         sta     XFER_MODE
@LCD74:  lda     $c92d
         cmp     #$05
         bne     @LCD88
         sty     $c92d
         lda     UNK_c8cf
         bne     @LCD88
         lda     #$69
         jmp     LCC40

@LCD88:  ldy     SAVE_Y
         rts

@LCD8C:  lda     BLKSIZE_H-1
         cmp     #$44
         beq     @LCDAC
         lda     #$4d
         jsr     LCC40
         ldx     #$00
         lda     $ca00,x
         cmp     #$05
         bne     @LCDAC
         sta     $c92d
         lda     #$59
         jmp     LCC40

         .byte   $8c
         .byte   $2d
         .byte   $c9

@LCDAC:  rts

TCDAD:   lda     XFER_MODE
         sta     SAVE_SP_UNIT-1
         lda     CALL_TYPE
         and     #$3f
         sta     CALL_TYPE
         jsr     LCEF1
         bcs     @LCDCD
         lda     #$01
         sta     PD_PAR_BLK_LO
         jsr     LCECA
         bcs     @LCDCD
         lda     #$ff
         bne     @LCDCF

@LCDCD:  lda     #$00
@LCDCF:  sta     UNK_c8cf
         lda     SAVE_SP_UNIT-1
         sta     XFER_MODE
         rts

LCDD9:   lda     #$00
         sta     PTR_c8d7-1
         ldy     #$07
         lda     (BUF_PTR_L),y
         sta     UNK_c8cf-1
@LCDE5:  jsr     LCF54
         bcs     @LCDED
         jsr     @LCE0A
@LCDED:  inc     PTR_c8d7-1
         lda     PTR_c8d7-1
         cmp     UNK_c8cf-1
         beq     @LCE03
         clc
         adc     #$01
         sta     PD_PAR_BLK_LO
         jsr     LCECA
         jmp     @LCDE5

@LCE03:  lda     TEMP_c8da-1
         sta     UNK_c8cf
         rts

@LCE0A:  inc     TEMP_c8da-1
         jsr     TCE7A
         ldy     #$00
         lda     #$86
         sta     (TMP_PTR0),y
         jsr     @LCE1F
         jsr     @LCE3E
         jmp     @LCE6D

@LCE1F:  ldy     #$0c
         ldx     #$00
@LCE23:  lda     (BUF_PTR_L),y
         sta     $c8d2,x
         iny
         inx
         cpy     #$10
         bne     @LCE23
         ldy     #$09
         ldx     #$00
@LCE32:  lda     (BUF_PTR_L),y
         sta     PART_START,x
         iny
         inx
         cpy     #$0c
         bne     @LCE32
         rts

@LCE3E:  jsr     LCF86
         ldy     #$07
         lda     PTR_c8d0
         sta     (TMP_PTR0),y
         iny
         lda     PTR_c8d0+1
         sta     (TMP_PTR0),y
         ldy     #$01
         ldx     #$00
@LCE52:  lda     $c8d2,x
         sta     (TMP_PTR0),y
         iny
         inx
         cpy     #$05
         bne     @LCE52
         ldy     #$0a
         ldx     #$00
@LCE61:  lda     PART_START,x
         sta     (TMP_PTR0),y
         iny
         inx
         cpy     #$0d
         bne     @LCE61
         rts

@LCE6D:  ldy     #$0d
         lda     SEL_TARGET
         sta     (TMP_PTR0),y
         iny
         lda     #$0c
         sta     (TMP_PTR0),y
         rts

TCE7A:   lda     #$31
         sta     TMP_PTR0
         lda     #$c8
         sta     TMP_PTR0+1
         ldy     #$00
         lda     (TMP_PTR0),y
         cmp     #$86
         beq     @LCE8C
         bne     @LCEA4

@LCE8C:  lda     TMP_PTR0
         clc
         adc     #$11
         cmp     #$98
         bcs     @LCE9C
         jsr     @LCEA8
         bcs     @LCE8C
         bcc     @LCEA4

@LCE9C:  lda     #$00
         sta     TMP_PTR0
         lda     #$cb
         sta     TMP_PTR0+1
@LCEA4:  ldy     SAVE_Y
         rts

@LCEA8:  sta     TMP_PTR0
         ldy     #$00
         lda     (TMP_PTR0),y
         cmp     #$86
         bne     @LCEB4
         sec
         rts

@LCEB4:  clc
         rts

         .byte   $98
         .byte   $38
         .byte   $e9
         .byte   $05
         .byte   $a8,$b1,$fa,$8d
         .byte   $24
         .byte   $c8,$c8,$b1,$fa,$8d
         .byte   $25
         .byte   $c8
         .byte   $ac
         .byte   $1a
         .byte   $c8
         .byte   $60

LCECA:   jsr     LCF27
         lda     #$00
         sta     XFER_MODE
         sta     PD_PAR_BLK_HI
         jsr     LCF63
         ldy     #$00
         jsr     LCF27
         lda     (BUF_PTR_L),y
         cmp     #$50
         bne     LCEEC
         iny
         lda     (BUF_PTR_L),y
         cmp     #$4d
         bne     LCEEC
         clc
         bcc     LCEED

LCEEC:   sec
LCEED:   ldy     SAVE_Y
         rts

LCEF1:   jsr     LCF27
         lda     #$00
         sta     XFER_MODE
         lda     #$00
         sta     PD_PAR_BLK_HI
         sta     PD_PAR_BLK_LO
         jsr     LCF63
         ldy     #$00
         jsr     LCF27
         lda     (BUF_PTR_L),y
         cmp     #$45
         bne     @LCF24
         iny
         lda     (BUF_PTR_L),y
         cmp     #$52
         bne     @LCF24
         ldy     #$02
         lda     (BUF_PTR_L),y
         sta     PTR_c8d0
         iny
         lda     (BUF_PTR_L),y
         sta     PTR_c8d0+1
         clc
         bcc     LCEED

@LCF24:  jmp     LCEEC

LCF27:   lda     #$00
         sta     BUF_PTR_L
         lda     #$ca
         sta     BUF_PTR_H
         rts

         .byte   $a0
         .byte   $07
         .byte   $b1,$fa,$8d,$ce,$c8
         .byte   $20
         .byte   $54
         .byte   $cf
         .byte   $90
         .byte   $15
         .byte   $a0
         .byte   $00
         .byte   $e6
         .byte   $46
         .byte   $a5
         .byte   $46
         HiAscii "MNHp"
         .byte   $0b
         .byte   $a9
         .byte   $01
         .byte   $85
         .byte   $46
         .byte   $20
         .byte   $ca
         .byte   $ce
         .byte   $4c
         .byte   $37
         .byte   $cf
         .byte   $60
         .byte   $38
         .byte   $60

LCF54:   lda     #$0e
         jsr     LCC40
         lda     UNK_c8cf
         beq     @LCF60
         clc
         rts

@LCF60:  sec
         rts

         .byte   $60

LCF63:   lda     #$08
         sta     SCSI_CDB_CMD
         lda     #$06
         sta     SCSI_CMD_LEN
         lda     #$00
         sta     SCSI_CDB_LUN
         lda     PD_PAR_BLK_HI
         sta     SCSI_CDB_LBA_HI
         lda     PD_PAR_BLK_LO
         sta     SCSI_CDB_LBA_LO
         lda     #$01
         sta     SCSI_CDB_LEN
         lda     #$10
         jmp     LCC40

LCF86:   lda     #$00
         ldy     #$10
@LCF8A:  sta     (TMP_PTR0),y
         dey
         bne     @LCF8A
         rts

TCF90:   lda     TMP_PTR_L
         sta     PTR_c8d7
         lda     TMP_PTR_H
         sta     PTR_c8d7+1
         rts

TCF9B:   lda     PTR_c8d7
         sta     TMP_PTR_L
         lda     PTR_c8d7+1
         sta     TMP_PTR_H
         rts

LCFA6:   sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH

FN_TABLE:
         .word   TCC00
         .word   TCDAD
         .word   TCDAD
         .word   TCD49
         .word   TCDAD
         .word   TCE7A
         .word   TCF90
         .word   TCF9B
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

         .byte   $d7
         .byte   $00
         .byte   $00
         .byte   $00
