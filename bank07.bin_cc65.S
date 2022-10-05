; Target assembler: cc65 v2.18.0 [--target none -C bank07.bin_cc65.cfg]
; 6502bench SourceGen v1.8.3
         .setcpu "65816"
SCSI_CMD_READ6 = $08

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
NUM_PART =       $c8ce      ; number of partition on the device - only used in bank 07
UNK_c8cf =       $c8cf      ; $00 if failed to read Partition Map. $ff if PM detected
TEMP_c8d0 =      $c8d0      ; temp int storage (size of DDM block?)
TMP_COUNT =      $c8d6      ; temp counter - only used in bank 07
PTR_c8d7 =       $c8d7      ; temp pointer storage (?)
TEMP_c8da =      $c8da      ;unknown
SAVE_XFER_MODE_ALT = $c8e7  ; saved XFER_MODE ? - seems used only in bank 7 as a temp
IIgs_PDMA =      $c8f3      ;0x01 if IIgs PDMA
BLKSIZE_H =      $c92f      ;byte1 of block size - reverse endian

         .org    $cc00
         .a8
         .i8
FN_07:   jsr     CALL_B1_c800
         jsr     LCC51
         jsr     CALL_FN_00 ;Do Phases
         lda     SCSI_CDB_CMD
         cmp     #SCSI_CMD_READ6
         beq     @LCC1A
         jsr     LCCFB
         jsr     CALL_FN_71
         lda     #$65
         bne     @LCC22

@LCC1A:  jsr     LCCE7
         jsr     CALL_FN_61
         lda     #$55
@LCC22:  jsr     CALL_FN_X7 ;CALL_FN_55
         jmp     @LCC28     ;redundant

@LCC28:  jsr     LCD0F
         lda     #$30
         jmp     CALL_FN_X7 ;CALL_FN_30

CALL_B1_c800:
         lda     #$17
         sta     REG_IO_BANK_SEL,y ;set ram bank 01
         jsr     $c800
         lda     #$07
         sta     REG_IO_BANK_SEL,y ;set ram bank 00
         rts

CALL_FN_00:
         lda     #$00       ;CALL_FN_00
CALL_FN_X7:
         ldy     SAVE_Y
         ldx     #$07
         jsr     BANKSWITCH ;CALL_FN_X7
         rts

CALL_FN_61:
         lda     #$61
         bne     CALL_FN_X7 ;CALL_FN_61

CALL_FN_71:
         lda     #$71
         bne     CALL_FN_X7 ;CALL_FN_71

LCC51:   jsr     @LCC95
         lda     SAVE_SP_CMD_B
         and     #$0f       ;mask extended cmd bit
         cmp     #$08       ;SP CMD Read
         bne     @LCC61     ;branch if not a read command
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
@LCC95:  jsr     @LCC8B     ;seems a bug
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

LCCE7:   jsr     SET_TIMEOUT_03
@LCCEA:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$04
         beq     @LCCFA
         jsr     DEC_TIMEOUT
         bcs     ERROR_IOERROR
         bcc     @LCCEA

@LCCFA:  rts

LCCFB:   jsr     SET_TIMEOUT_03
@LCCFE:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$00
         beq     @LCD0E
         jsr     DEC_TIMEOUT
         bcs     ERROR_IOERROR
         bcc     @LCCFE

@LCD0E:  rts

LCD0F:   jsr     SET_TIMEOUT_03
@LCD12:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$0c
         beq     @LCD22
         jsr     DEC_TIMEOUT
         bcs     ERROR_IOERROR
         bcc     @LCD12

@LCD22:  rts

SET_TIMEOUT_03:
         lda     #$ff
         sta     TCOUNT_B0
         sta     TCOUNT_B2
         lda     #$03
         sta     TCOUNT_B1
         rts

DEC_TIMEOUT:
         dec     TCOUNT_B0
         bne     @LCD40
         dec     TCOUNT_B2
         bne     @LCD40
         dec     TCOUNT_B1
         beq     @LCD42     ;likely a bug - should be bmi
@LCD40:  clc
         rts

@LCD42:  sec
         rts

ERROR_IOERROR:
         lda     #$27
         jmp     CALL_FN_60_RET

FN_37:   lda     #$00
         sta     TEMP_c8da-1
         sta     UNK_c8cf
         lda     $c92d
         cmp     SEL_TARGET
         bne     @LCD60
         lda     BLKSIZE_H-1
         cmp     #$44
         beq     @LCD88
@LCD60:  jsr     @LCD8C
         jsr     FN_17      ;Read DDM and master PDM
         lda     UNK_c8cf
         beq     @LCD74     ;branch if DDM/PDM read failed
         jsr     FILL_SDAT_TABLE
         lda     SAVE_XFER_MODE_ALT
         sta     XFER_MODE
@LCD74:  lda     $c92d
         cmp     #$05
         bne     @LCD88
         sty     $c92d
         lda     UNK_c8cf
         bne     @LCD88
         lda     #$69
         jmp     CALL_FN_X7 ;CALL_FN_69

@LCD88:  ldy     SAVE_Y
         rts

@LCD8C:  lda     BLKSIZE_H-1
         cmp     #$44
         beq     @LCDAC
         lda     #$4d
         jsr     CALL_FN_X7 ;CALL_FN_4D
         ldx     #$00
         lda     $ca00,x
         cmp     #$05
         bne     @LCDAC
         sta     $c92d
         lda     #$59
         jmp     CALL_FN_X7 ;CALL_FN_59

         .byte   $8c
         .byte   $2d
         .byte   $c9

@LCDAC:  rts

FN_17:   lda     XFER_MODE  ;READ DDM and master PDM
         sta     SAVE_XFER_MODE_ALT
         lda     CALL_TYPE
         and     #$3f
         sta     CALL_TYPE  ;strip extended flag from CALL_TYPE
         jsr     READ_DDM
         bcs     @FN_17_fail ;branch if failed to read DDM
         lda     #$01
         sta     PD_PAR_BLK_LO ;set block to 1
         jsr     READ_PDM   ;Read PDM
         bcs     @FN_17_fail
         lda     #$ff
         bne     @FN_17_end

@FN_17_fail:
         lda     #$00
@FN_17_end:
         sta     UNK_c8cf
         lda     SAVE_XFER_MODE_ALT
         sta     XFER_MODE
         rts

FILL_SDAT_TABLE:
         lda     #$00
         sta     TMP_COUNT
         ldy     #$07
         lda     (BUF_PTR_L),y ;read total number of partitions on the device
         sta     NUM_PART   ;read and parse NUM_PART PDM
@next_pdm:
         jsr     CALL_FN_0E_CARRY
         bcs     @skip_make_entry ;skip parsing if partition not recognized ???
         jsr     NEW_SDAT_ENTRY
@skip_make_entry:
         inc     TMP_COUNT
         lda     TMP_COUNT
         cmp     NUM_PART
         beq     @done_reading_pdm
         clc                ;add 1 to block
         adc     #$01
         sta     PD_PAR_BLK_LO
         jsr     READ_PDM   ;read next PDM
         jmp     @next_pdm

@done_reading_pdm:
         lda     TEMP_c8da-1
         sta     UNK_c8cf
         rts

NEW_SDAT_ENTRY:
         inc     TEMP_c8da-1 ;add partition to SDAT
         jsr     FN_57      ;Find empty SDAT -> TMP_PTR0
         ldy     #$00
         lda     #$86
         sta     (TMP_PTR0),y ;put signature in SDAT entry
         jsr     GET_PART_SIZE_START ;*$C8D2=partition size; PART_START=partition start
         jsr     FILL_SDAT_ENTRY
         jmp     FILL_ID_TIMEOUT

GET_PART_SIZE_START:
         ldy     #$0c
         ldx     #$00       ;copy partiton size ($0c is the offset in the PDM) to $c8d2
@size_copy_loop:
         lda     (BUF_PTR_L),y
         sta     $c8d2,x
         iny
         inx
         cpy     #$10
         bne     @size_copy_loop
         ldy     #$09       ;copy 3 lsb of partition start to PART_START
         ldx     #$00
@start_copy_loop:
         lda     (BUF_PTR_L),y
         sta     PART_START,x
         iny
         inx
         cpy     #$0c
         bne     @start_copy_loop
         rts

FILL_SDAT_ENTRY:
         jsr     CLR_SDAT_ENTRY ;keeps signature ID intact
         ldy     #$07
         lda     TEMP_c8d0
         sta     (TMP_PTR0),y
         iny
         lda     TEMP_c8d0+1
         sta     (TMP_PTR0),y ;fill the bytes per block
         ldy     #$01
         ldx     #$00
@blk_count_cpy_loop:
         lda     $c8d2,x
         sta     (TMP_PTR0),y
         iny
         inx
         cpy     #$05
         bne     @blk_count_cpy_loop ;fill the block count
         ldy     #$0a
         ldx     #$00
@start_cpy_loop:
         lda     PART_START,x
         sta     (TMP_PTR0),y
         iny
         inx
         cpy     #$0d
         bne     @start_cpy_loop ;fill partition start
         rts

FILL_ID_TIMEOUT:
         ldy     #$0d
         lda     SEL_TARGET
         sta     (TMP_PTR0),y ;fill SDAT entry software ID
         iny
         lda     #$0c
         sta     (TMP_PTR0),y ;fill SDAT entry timeout
         rts

FN_57:   lda     #$31       ;Find empty SDAT (TMP_PTR0 points to the first free entry)
         sta     TMP_PTR0
         lda     #$c8
         sta     TMP_PTR0+1 ;TMP_PTR0=SDAT_BASE
         ldy     #$00
         lda     (TMP_PTR0),y ;load SDAT_ID
         cmp     #$86       ;check for signature
         beq     next_entry ;branch if entry already taken
         bne     FN_57_end  ;branch if entry is free

next_entry:
         lda     TMP_PTR0
         clc
         adc     #$11
         cmp     #$98
         bcs     SET_TMP_PTR_CB00_RET ;branch if table overflow
         jsr     check_sdat_entry
         bcs     next_entry ;branch if entry alredy in use
         bcc     FN_57_end

SET_TMP_PTR_CB00_RET:
         lda     #$00
         sta     TMP_PTR0
         lda     #$cb
         sta     TMP_PTR0+1
FN_57_end:
         ldy     SAVE_Y
         rts

check_sdat_entry:
         sta     TMP_PTR0
         ldy     #$00
         lda     (TMP_PTR0),y
         cmp     #$86
         bne     @entry_free
         sec
         rts

@entry_free:
         clc
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

READ_PDM:
         jsr     SET_BUF_PTR_CA00
         lda     #$00
         sta     XFER_MODE
         sta     PD_PAR_BLK_HI
         jsr     READ_BLOCK_LBA16
         ldy     #$00
         jsr     SET_BUF_PTR_CA00
         lda     (BUF_PTR_L),y
         cmp     #$50       ;check for PDM signature
         bne     RET_CARRY_SET ;branch if not PDM
         iny
         lda     (BUF_PTR_L),y
         cmp     #$4d       ;check for PDM signature
         bne     RET_CARRY_SET ;branch if not PDM
         clc
         bcc     RET_RESTORE_Y

RET_CARRY_SET:
         sec
RET_RESTORE_Y:
         ldy     SAVE_Y
         rts

READ_DDM:
         jsr     SET_BUF_PTR_CA00
         lda     #$00
         sta     XFER_MODE
         lda     #$00       ;redundant
         sta     PD_PAR_BLK_HI ;set block to 0
         sta     PD_PAR_BLK_LO
         jsr     READ_BLOCK_LBA16 ;read BLOCK 0
         ldy     #$00
         jsr     SET_BUF_PTR_CA00
         lda     (BUF_PTR_L),y
         cmp     #$45       ;Check for DDM signature
         bne     RET_CARRY_SET_LOCAL ;not DDM block
         iny
         lda     (BUF_PTR_L),y
         cmp     #$52       ;Check for DDM signature
         bne     RET_CARRY_SET_LOCAL ;not DDM block
         ldy     #$02
         lda     (BUF_PTR_L),y
         sta     TEMP_c8d0
         iny
         lda     (BUF_PTR_L),y
         sta     TEMP_c8d0+1 ;TEMP_c8d0 contains the size in bytes of the DDM (inverse endian)
         clc
         bcc     RET_RESTORE_Y

RET_CARRY_SET_LOCAL:
         jmp     RET_CARRY_SET ;redundant

SET_BUF_PTR_CA00:
         lda     #$00
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

CALL_FN_0E_CARRY:
         lda     #$0e
         jsr     CALL_FN_X7 ;CALL_FN_0E
         lda     UNK_c8cf
         beq     @LCF60
         clc
         rts

@LCF60:  sec
         rts

         .byte   $60

READ_BLOCK_LBA16:
         lda     #SCSI_CMD_READ6
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
         jmp     CALL_FN_X7 ;CALL_FN_10 Data Xin

CLR_SDAT_ENTRY:
         lda     #$00
         ldy     #$10
@sdat_clr_loop:
         sta     (TMP_PTR0),y
         dey
         bne     @sdat_clr_loop
         rts

FN_67:   lda     TMP_PTR_L  ;SAVE TMP_PTR to $c8d7
         sta     PTR_c8d7
         lda     TMP_PTR_H
         sta     PTR_c8d7+1
         rts

FN_77:   lda     PTR_c8d7   ;Restore TMP_PTR from $c8d7
         sta     TMP_PTR_L
         lda     PTR_c8d7+1
         sta     TMP_PTR_H
         rts

CALL_FN_60_RET:
         sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH

FN_TABLE:
         .word   FN_07
         .word   FN_17
         .word   FN_17
         .word   FN_37
         .word   FN_17
         .word   FN_57
         .word   FN_67
         .word   FN_77
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
