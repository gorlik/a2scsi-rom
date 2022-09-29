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
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SCSI_CMD_LEN =   $c80d      ; SCSI COMMAND lenght
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SCSI_CDB_LUN =   $c80f      ; 
SCSI_CDB_LBA_HI = $c810
SCSI_CDB_LBA_LO = $c811
SAVE_Y   =       $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
PART_START =     $c824      ; partition start (3 bytes) seems to be in reverse endian (?)
SDAT_BASE =      $c831      ;start of SDAT table (extends to $C8A7)
LBA_c8db =       $c8db      ; LBA to use in CDB (?) (copied to CDB_LBA)
IIgs_PDMA =      $c8f3      ;0x01 if IIgs PDMA
BLKSIZE_H =      $c92f      ;byte1 of block size
BLKSIZE_L =      $c930      ;byte0 of block size
LDIO_SIZE_LO =   $c9ee
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
         sta     BLKSIZE_H-1
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
         jmp     LCE15

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
         sta     BLKSIZE_H-1
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
         jsr     LCE15
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
         lda     BLKSIZE_H-1
         sbc     $c92c
         bcc     @LCD23
         sta     BLKSIZE_H-1
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
         ldy     BLKSIZE_H-1
         sty     $c92a
         stx     BLKSIZE_H-1
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
         lda     @LCD81+2,x
         sta     TMP_PTR1+1
         jmp     (TMP_PTR1)

@LCD6F:  clc
         xce
         ldy     #$06
         lda     [TMP_PTR_L],y
         sec
         xce
         jmp     @LCD5E

@LCD7A:  sty     $bbae
         cmp     ($c7,x)
         bne     @LCD5A
@LCD81:  sbc     @LCDF3
         cmp     @LCDCD
         cmp     @LCDCD
         cmp     $20cd
         stz     $20cd,x
         lda     [$ce]
         jsr     LCE13
         jsr     LCE56
         jsr     LCE3D
         jmp     @LCDE2

         .byte   $ad
         .byte   $f3
         .byte   $c9
         .byte   $c9
         .byte   $b4
         .byte   $d0
         .byte   $01
         .byte   $60
         .byte   $ac
         .byte   $1a
         .byte   $c8
         .byte   $a9
         .byte   $21
         .byte   $4c
         .byte   $9e
         .byte   $cf
         .byte   $20
         .byte   $b6
         .byte   $ce
         .byte   $20
         .byte   $13
         .byte   $ce
         .byte   $20
         .byte   $42
         .byte   $ce
         .byte   $20
         .byte   $1e
         .byte   $ce
         .byte   $60
         .byte   $20
         .byte   $c7
         .byte   $ce
         .byte   $4c
         .byte   $df
         .byte   $cd
         .byte   $20
         .byte   $d5
         .byte   $ce
         .byte   $4c
         .byte   $df
         .byte   $cd
         .byte   $20
         .byte   $9e
         .byte   $cd
         .byte   $20
         .byte   $de
         .byte   $ce
@LCDCD:  .byte   $4c
         .byte   $df
         .byte   $cd
         .byte   $20
         .byte   $9e
         .byte   $cd
         .byte   $20
         .byte   $e7
         .byte   $ce
         .byte   $4c
         .byte   $df
         .byte   $cd
         .byte   $20
         .byte   $9e
         .byte   $cd
         .byte   $20
         .byte   $f0
         .byte   $ce
         .byte   $20
         .byte   $92
         .byte   $cd

@LCDE2:  lda     RET_CODE
         beq     @LCDEC
         lda     #$27
         jmp     LCF9E

@LCDEC:  rts

         .byte   $20
         .byte   $04
         .byte   $cf
         .byte   $4c
         .byte   $df
         .byte   $cd
@LCDF3:  .byte   $20
         .byte   $fd
         .byte   $cd
         .byte   $20
         .byte   $03
         .byte   $c8
         .byte   $20
         .byte   $03
         .byte   $ce
         .byte   $60

LCDFD:   lda     #$1b
         sta     REG_IO_BANK_SEL,y
         rts

LCE03:   lda     #$0b
         sta     REG_IO_BANK_SEL,y
         rts

FN_6B:   jsr     LCDFD
         jsr     SEL_TARGET
         jsr     LCE03
         rts

LCE13:   lda     #$00
LCE15:   ldx     #$0b
         ldy     SAVE_Y
         jsr     BANKSWITCH
         rts

         .byte   $ac
         .byte   $1a
         .byte   $c8
         .byte   $a9
         .byte   $ff
         .byte   $8d
         .byte   $20
         .byte   $c8
         .byte   $ad
         .byte   $04
         .byte   $c8
         .byte   $8d
         .byte   $0a
         .byte   $c8
         .byte   $a9
         .byte   $03
         .byte   $8d
         .byte   $04
         .byte   $c8
         .byte   $a9
         .byte   $40
         .byte   $20
         .byte   $15
         .byte   $ce
         .byte   $ad
         .byte   $0a
         .byte   $c8
         .byte   $8d
         .byte   $04
         .byte   $c8
         .byte   $60

LCE3D:   lda     #$30
         jmp     LCE15

         .byte   $20
         .byte   $6f
         .byte   $ce
         .byte   $b9
         .byte   $04
         .byte   $c0
         .byte   $29
         .byte   $1c
         .byte   $c9
         .byte   $04
         .byte   $f0
         .byte   $07
         .byte   $20
         .byte   $7d
         .byte   $ce
         .byte   $b0
         .byte   $17
         .byte   $90
         .byte   $f0
         .byte   $60

LCE56:   jsr     @LCE6F
@LCE59:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$0c
         beq     @LCE69
         jsr     @LCE7D
         bcs     @LCE6A
         bcc     @LCE59

@LCE69:  rts

@LCE6A:  lda     #$27
         jmp     LCF9E

@LCE6F:  lda     #$ff
         sta     TCOUNT_B0
         sta     TCOUNT_B2
         lda     #$03
         sta     TCOUNT_B1
         rts

@LCE7D:  dec     TCOUNT_B0
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
         bne     @LCE9C

         .byte   $a9
         .byte   $0a
         .byte   $8d
         .byte   $0d
         .byte   $c8

@LCE9C:  ldx     #$0a
         lda     #$00
@LCEA0:  sta     SCSI_CDB_CMD,x
         dex
         bne     @LCEA0
         rts

         .byte   $20
         .byte   $97
         .byte   $ce
         .byte   $a9
         .byte   $2b
         .byte   $8d
         .byte   $0e
         .byte   $c8
         .byte   $20
         .byte   $51
         .byte   $cf
         .byte   $20
         .byte   $0d
         .byte   $cf
         .byte   $60
         .byte   $20
         .byte   $90
         .byte   $ce
         .byte   $a9
         .byte   $1c
         .byte   $8d
         .byte   $0e
         .byte   $c8
         .byte   $a9
         .byte   $ff
         .byte   $8d
         .byte   $12
         .byte   $c8
         .byte   $20
         .byte   $51
         .byte   $cf
         .byte   $60
         .byte   $20
         .byte   $90
         .byte   $ce
         .byte   $a9
         .byte   $1b
         .byte   $8d
         .byte   $0e
         .byte   $c8
         .byte   $a9
         .byte   $01
         .byte   $8d
         .byte   $12
         .byte   $c8
         .byte   $60
         .byte   $20
         .byte   $90
         .byte   $ce
         .byte   $a9
         .byte   $1b
         .byte   $8d
         .byte   $0e
         .byte   $c8
         .byte   $60
         .byte   $20
         .byte   $90
         .byte   $ce
         .byte   $a9
         .byte   $1e
         .byte   $4c
         .byte   $cc
         .byte   $ce
         .byte   $60
         .byte   $20
         .byte   $90
         .byte   $ce
         .byte   $a9
         .byte   $1e
         .byte   $8d
         .byte   $0e
         .byte   $c8
         .byte   $60
         .byte   $20
         .byte   $97
         .byte   $ce
         .byte   $a9
         .byte   $2f
         .byte   $8d
         .byte   $0e
         .byte   $c8
         .byte   $20
         .byte   $51
         .byte   $cf
         .byte   $20
         .byte   $0d
         .byte   $cf
         .byte   $a9
         .byte   $01
         .byte   $8d
         .byte   $16
         .byte   $c8
         .byte   $60
         .byte   $20
         .byte   $90
         .byte   $ce
         .byte   $a9
         .byte   $01
         .byte   $8d
         .byte   $0e
         .byte   $c8
         .byte   $60
         .byte   $ad
         .byte   $1d
         .byte   $c8
         .byte   $29
         .byte   $40
         .byte   $f0
         .byte   $05
.macro   HiAscii Arg
         .repeat .strlen(Arg), I
         .byte   .strat(Arg, I) | $80
         .endrep
.endmacro
         HiAscii "-sHP"
         .byte   $1a
         .byte   $a0
         .byte   $00
         .byte   $b1
         .byte   $fa
         .byte   $8d
         .byte   $13
         .byte   $c8,$c8,$b1,$fa,$8d
         .byte   $12
         .byte   $c8,$c8,$b1,$fa,$8d
         .byte   $11
         .byte   $c8,$c8,$b1,$fa,$8d
         .byte   $10
         .byte   $c8
         .byte   $60
         .byte   $18
         .byte   $fb
         .byte   $a0
         .byte   $00
         .byte   $b7
         .byte   $fa
         .byte   $8d
         .byte   $13
         .byte   $c8,$c8,$b7,$fa,$8d
         .byte   $12
         .byte   $c8,$c8,$b7,$fa,$8d
         .byte   $11
         .byte   $c8,$c8,$b7,$fa,$8d
         .byte   $10
         .byte   $c8
         .byte   $38
         .byte   $fb
         .byte   $60

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
         sta     SDAT_BASE-1
@bus_busy:
         lda     REG_5380_STAT,y
         and     #$40
         bne     @ret
         dex
         bne     @bus_busy
         dec     SDAT_BASE-1
         bne     @bus_busy
@ret:    rts

LCF9E:   sta     RET_CODE
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
         jsr     @LCFF9
         pla
         and     #$0f
         sta     REG_IO_BANK_SEL,y
         clc
         rts

@LCFF9:  jmp     (TMP_PTR1)

         .byte   $00
         .byte   $00
         .byte   $00
         .byte   $00
