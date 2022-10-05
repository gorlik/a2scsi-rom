; Target assembler: cc65 v2.18.0 [--target none -C bank11.bin_cc65.cfg]
; 6502bench SourceGen v1.1.0
         .setcpu "65816"
TMP_PTR0 =       $19        ; temporary ZP pointer 
TMP_PTR1 =       $1b        ; temporary ZP pointer 
TMP_PTR_L =      $f6        ; temporary ZP long pointer
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
BUF_PTR_XH =     $fd
REG_5380_STAT =  $c004      ; R SCSI status
REG_IO_BANK_SEL = $c00a     ; W memory bank select
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B2 =      $c802      ; timeout counter MSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
XFER_MODE =      $c804      ; 0x00 IIe PDMA, 0x01 IIgs PDMA, 0x02-0xff PIO 
SEL_TARGET =     $c806      ; SCSI (BUS?) ID of selected target
TMP_c80a =       $c80a      ; unknown
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SCSI_CMD_LEN =   $c80d      ; SCSI COMMAND lenght
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SCSI_CDB_LUN =   $c80f      ; 
SCSI_CDB_LBA_HI = $c810
SCSI_CDB_LBA_LO = $c811
SCSI_CDB_LEN =   $c812
SCSI_CDB_CTRL =  $c813
SCSI_CDB10_8 =   $c816
SAVE_Y   =       $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
UNK_c820 =       $c820      ; 0xff if PIO ?
PART_START =     $c824      ; partition start (3 bytes) seems to be in reverse endian (?)
LBA_c8db =       $c8db      ; LBA to use in CDB (?) (copied to CDB_LBA)
IIgs_PDMA =      $c8f3      ;0x01 if IIgs PDMA
BLKSIZE_H =      $c92f      ;byte1 of block size
BLKSIZE_L =      $c930      ;byte0 of block size
LDIO_SIZE_LO =   $c9ee
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB
TIMEOUT  =       $c9f6      ; each unit is 1.25s

         .org    $cc00
         .a8
         .i8
FN_0B:   jsr     LCE90
         lda     CALL_TYPE
         and     #$40
         beq     @LCC0F
         lda     IIgs_PDMA
         bne     @LCC7C
@LCC0F:  lda     #$06
         sta     SCSI_CMD_LEN
         ldy     #$02
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_L
         iny
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_H
         lda     CALL_TYPE
         beq     @LCC26
         iny
         iny
@LCC26:  iny
         lda     (TMP_PTR_L),y
         sta     LDIO_SIZE_LO
         sta     $c92d
         iny
         lda     (TMP_PTR_L),y
         sta     $c9ef
         sta     $c92e
         ldx     #$02
         iny
         lda     (TMP_PTR_L),y
         clc
         adc     PART_START+2
         sta     SCSI_CDB_LBA_LO
         sta     LBA_c8db
         iny
         lda     (TMP_PTR_L),y
         adc     PART_START+1
         sta     SCSI_CDB_LBA_HI
         sta     LBA_c8db+1
         iny
         lda     (TMP_PTR_L),y
         adc     PART_START
         sta     SCSI_CDB_LUN
         sta     LBA_c8db+2
         lda     #$00
         sta     BUF_PTR_VH
         sta     BUF_PTR_XH
@LCC65:  lda     BLKSIZE_L
         sta     $c92b
         lda     BLKSIZE_H
         sta     $c92c
         jsr     FN_2B
         ldy     SAVE_Y
         lda     #$7c
         jmp     CALL_FN_XB ;CALL_FN_7C

@LCC7C:  lda     #$01
         sta     XFER_MODE
         jsr     @LCCD9
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
         iny
         lda     [TMP_PTR_L],y
         sta     LDIO_SIZE_LO
         sta     $c92d
         iny
         lda     [TMP_PTR_L],y
         sta     $c9ef
         sta     $c92e
         iny
         lda     [TMP_PTR_L],y
         clc
         adc     PART_START+2
         sta     LBA_c8db
         sta     SCSI_CDB_LBA_LO
         iny
         lda     [TMP_PTR_L],y
         adc     PART_START+1
         sta     LBA_c8db+1
         sta     SCSI_CDB_LBA_HI
         iny
         lda     [TMP_PTR_L],y
         adc     PART_START
         sta     SCSI_CDB_LUN
         sta     LBA_c8db+2
         iny
         lda     [TMP_PTR_L],y
         jsr     @LCCDC
         jmp     @LCC65

@LCCD9:  clc
         xce
         rts

@LCCDC:  sec
         xce
         rts

FN_1B:   lda     #$9c
         jsr     CALL_FN_XB ;CALL_FN_9C
         ldy     #$02
         lda     (TMP_PTR_L),y
         sta     TIMEOUT
         ldy     #$0e
         sta     (TMP_PTR0),y
         ldy     SAVE_Y
         rts

FN_2B:   lda     #$00
         tax
         pha
         ldy     #$01
         lda     $c92b
         bmi     @LCD0B
@LCCFE:  iny
         asl     $c92b
         rol     $c92c
         bmi     @LCD0B
         cpy     #$11
         bne     @LCCFE
@LCD0B:  sec
         lda     $c92d
         sbc     $c92b
         pha
         lda     $c92e
         sbc     $c92c
         bcc     @LCD23
         sta     $c92e
         pla
         sta     $c92d
         pha
@LCD23:  pla
         pla
         rol     A
         pha
         txa
         rol     A
         tax
         lsr     $c92c
         ror     $c92b
         dey
         bne     @LCD0B
         pla
         ldy     $c92d
         sty     $c929
         ldy     $c92e
         sty     $c92a
         stx     $c92e
         sta     $c92d
         ldy     SAVE_Y
         rts

FN_5B:   lda     CALL_TYPE
         and     #$40
         beq     @LCD5A
         lda     IIgs_PDMA
         bne     @LCD6F
         ldy     #$06
         bne     @LCD5C

@LCD5A:  ldy     #$04
@LCD5C:  lda     (TMP_PTR_L),y
@LCD5E:  sec
         sbc     #$16
         tax
         lda     @LCD7A,x
         sta     TMP_PTR1
         lda     @LCD83,x
         sta     TMP_PTR1+1
         jmp     (TMP_PTR1)

@LCD6F:  clc
         xce
         ldy     #$06
         lda     [TMP_PTR_L],y
         sec
         xce
         jmp     @LCD5E

@LCD7A:  .byte   <TCD8C
         .byte   <TCDAE
         .byte   <TCDBB
         .byte   <TCDC1
         .byte   <TCDC7
         .byte   <TCDD0
         .byte   <TCDD9
         .byte   <TCDED
         .byte   <Patch1Call
@LCD83:  .byte   >TCD8C
         .byte   >TCDAE
         .byte   >TCDBB
         .byte   >TCDC1
         .byte   >TCDC7
         .byte   >TCDD0
         .byte   >TCDD9
         .byte   >TCDED
         .byte   >Patch1Call

TCD8C:   jsr     LCD9E
         jsr     LCEA7
LCD92:   jsr     CALL_FN_00
         jsr     LCE56
         jsr     LCE3D
         jmp     LCDE2

LCD9E:   lda     DEV_STATUS
         cmp     #$b4
         bne     @LCDA6
         rts

@LCDA6:  ldy     SAVE_Y
         lda     #$21
         jmp     CALL_FN_60_RET

TCDAE:   jsr     LCEB6
         jsr     CALL_FN_00
         jsr     LCE42
         jsr     LCE1E
         rts

TCDBB:   jsr     LCEC7
         jmp     LCDDF

TCDC1:   jsr     LCED5
         jmp     LCDDF

TCDC7:   jsr     LCD9E
         jsr     LCEDE
         jmp     LCDDF

TCDD0:   jsr     LCD9E
         jsr     LCEE7
         jmp     LCDDF

TCDD9:   jsr     LCD9E
         jsr     LCEF0
LCDDF:   jsr     LCD92
LCDE2:   lda     RET_CODE
         beq     @LCDEC
         lda     #$27
         jmp     CALL_FN_60_RET

@LCDEC:  rts

TCDED:   jsr     LCF04
         jmp     LCDDF

Patch1Call:
         jsr     SET_RAM_BANK_01
         jsr     $c803
         jsr     SET_RAM_BANK_00
         rts

SET_RAM_BANK_01:
         lda     #$1b
         sta     REG_IO_BANK_SEL,y ;set RAM BANK 01
         rts

SET_RAM_BANK_00:
         lda     #$0b
         sta     REG_IO_BANK_SEL,y ;set ram bank 00
         rts

FN_6B:   jsr     SET_RAM_BANK_01
         jsr     SEL_TARGET
         jsr     SET_RAM_BANK_00
         rts

CALL_FN_00:
         lda     #$00
CALL_FN_XB:
         ldx     #$0b
         ldy     SAVE_Y
         jsr     BANKSWITCH ;CALL_FN_XB
         rts

LCE1E:   ldy     SAVE_Y
         lda     #$ff
         sta     UNK_c820
         lda     XFER_MODE
         sta     TMP_c80a
         lda     #$03
         sta     XFER_MODE
         lda     #$40
         jsr     CALL_FN_XB ;CALL_FN_40
         lda     TMP_c80a
         sta     XFER_MODE
         rts

LCE3D:   lda     #$30
         jmp     CALL_FN_XB ;CALL_FN_30

LCE42:   jsr     LCE6F
@LCE45:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$04
         beq     @LCE55
         jsr     LCE7D
         bcs     LCE6A
         bcc     @LCE45

@LCE55:  rts

LCE56:   jsr     LCE6F
@LCE59:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$0c
         beq     @LCE69
         jsr     LCE7D
         bcs     LCE6A
         bcc     @LCE59

@LCE69:  rts

LCE6A:   lda     #$27
         jmp     CALL_FN_60_RET

LCE6F:   lda     #$ff
         sta     TCOUNT_B0
         sta     TCOUNT_B2
         lda     #$03
         sta     TCOUNT_B1
         rts

LCE7D:   dec     TCOUNT_B0
         bne     @LCE8C
         dec     TCOUNT_B2
         bne     @LCE8C
         dec     TCOUNT_B1
         beq     @LCE8E
@LCE8C:  clc
         rts

@LCE8E:  sec
         rts

LCE90:   lda     #$06
         sta     SCSI_CMD_LEN
         bne     LCE9C

LCE97:   lda     #$0a
         sta     SCSI_CMD_LEN
LCE9C:   ldx     #$0a
         lda     #$00
@LCEA0:  sta     SCSI_CDB_CMD,x
         dex
         bne     @LCEA0
         rts

LCEA7:   jsr     LCE97
         lda     #$2b
         sta     SCSI_CDB_CMD
         jsr     FN_8B
         jsr     LCF0D
         rts

LCEB6:   jsr     LCE90
         lda     #$1c
         sta     SCSI_CDB_CMD
         lda     #$ff
         sta     SCSI_CDB_LEN
         jsr     FN_8B
         rts

LCEC7:   jsr     LCE90
         lda     #$1b
LCECC:   sta     SCSI_CDB_CMD
         lda     #$01
         sta     SCSI_CDB_LEN
         rts

LCED5:   jsr     LCE90
         lda     #$1b
         sta     SCSI_CDB_CMD
         rts

LCEDE:   jsr     LCE90
         lda     #$1e
         jmp     LCECC

         .byte   $60

LCEE7:   jsr     LCE90
         lda     #$1e
         sta     SCSI_CDB_CMD
         rts

LCEF0:   jsr     LCE97
         lda     #$2f
         sta     SCSI_CDB_CMD
         jsr     FN_8B
         jsr     LCF0D
         lda     #$01
         sta     SCSI_CDB10_8
         rts

LCF04:   jsr     LCE90
         lda     #$01
         sta     SCSI_CDB_CMD
         rts

LCF0D:   lda     CALL_TYPE
         and     #$40
         beq     @LCF19
         lda     IIgs_PDMA
         bne     @LCF33
@LCF19:  ldy     #$00
         lda     (BUF_PTR_L),y
         sta     SCSI_CDB_CTRL
         iny
         lda     (BUF_PTR_L),y
         sta     SCSI_CDB_LEN
         iny
         lda     (BUF_PTR_L),y
         sta     SCSI_CDB_LBA_LO
         iny
         lda     (BUF_PTR_L),y
         sta     SCSI_CDB_LBA_HI
         rts

@LCF33:  clc
         xce
         ldy     #$00
         lda     [BUF_PTR_L],y
         sta     SCSI_CDB_CTRL
         iny
         lda     [BUF_PTR_L],y
         sta     SCSI_CDB_LEN
         iny
         lda     [BUF_PTR_L],y
         sta     SCSI_CDB_LBA_LO
         iny
         lda     [BUF_PTR_L],y
         sta     SCSI_CDB_LBA_HI
         sec
         xce
         rts

FN_8B:   lda     CALL_TYPE
         and     #$40
         beq     @LCF5D
         lda     IIgs_PDMA
         bne     @LCF6C
@LCF5D:  ldy     #$02
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_L
         iny
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_H
@LCF68:  ldy     SAVE_Y
         rts

@LCF6C:  clc
         xce
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
         sec
         xce
         jmp     @LCF68

FN_4B:   lda     #$06
         tax
         sta     $c830
@bus_busy:
         lda     REG_5380_STAT,y
         and     #$40
         bne     @ret
         dex
         bne     @bus_busy
         dec     $c830
         bne     @bus_busy
@ret:    rts

CALL_FN_60_RET:
         sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH

FN_TABLE:
         .word   FN_0B
         .word   FN_1B
         .word   FN_2B
         .word   FN_2B
         .word   FN_4B
         .word   FN_5B
         .word   FN_6B
         .word   FN_6B
         .word   FN_8B
         .word   $eaea
         .word   $eaea
         .word   $eaea
         .word   $eaea
         .word   $eaea
         .word   $eaea
         .word   $eaea
         .word   $eaea
         .word   $eaea

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
