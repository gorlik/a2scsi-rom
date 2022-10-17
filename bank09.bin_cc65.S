; Target assembler: cc65 v2.18.0 [--target none -C bank09.bin_cc65.cfg]
; 6502bench SourceGen v1.8.3
         .setcpu "65816"
SCSI_CMD_READ6 = $08
SCSI_CMD_WRITE6 = $0a

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
SLOT_OFFSET =    $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
CMD_STATUS =     $c81e      ; SCSI CMD status - 0x00 OK, 0x02 Check condition
UNK_c827 =       $c827      ; 3-byte unknown in reverse endian as the above
NEW_BLK_SIZE =   $c82a      ; desired block size in SetBlock
LBA_c8db =       $c8db      ; LBA to use in CDB (?) (copied to CDB_LBA)
RX_LEN_LO =      $c8e4      ; bytes read if call successfull
RX_LEN_HI =      $c8e5      ; bytes read if call successfull
IS_IIgs  =       $c8f3      ;0x01 if IIgs
LBA_TEMP =       $c911      ; temporary block number in bank 9
UNK_LEN  =       $c92d      ; unknown lenght - could be reverse endian ?????
LDIO_SIZE =      $c9ee
TMP_c9f1 =       $c9f1      ; 2-byte temp
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB
TIMEOUT  =       $c9f6      ; each unit is 1.25s

         .org    $cc00
         .a8
         .i8
LCC00:   lda     SCSI_CDB_CMD
         cmp     #SCSI_CMD_READ6
         bne     not_read
         jsr     CALL_FN_61 ;prepare DMA receive
         lda     #$00
         tay
         sta     TMP_c9f1
         sta     TMP_c9f1+1 ;TMP_cf91=0;
         lda     LDIO_SIZE+1
         beq     rts1
         tsx
         cpx     #$60
         bcc     @low_stack ;branch if stack has less than $60 bytes free
         lda     IS_IIgs
         bne     IIgs_stack_code ;branch if IIgs and plenty of stack space
@low_stack:
         ldx     SLOT_OFFSET
         lda     IS_IIgs
         beq     CALL_LDIO_DMA_READ ;branch if not IIgs
         lda     CALL_TYPE
         and     #$40
         beq     CALL_LDIO_DMA_READ ;branch if not extended
         lda     #$b4       ;IIgs path
         jmp     CALL_FN_X9 ;CALL_FN_B4

CALL_LDIO_DMA_READ:
         jsr     LDIO_DMA_READ
         rts

IIgs_stack_code:
         lda     CYAREG
         sta     SAVE_CYAREG
         lda     #$3f
         jsr     CALL_FN_X9 ;CALL_FN_3F
rts1:    rts

not_read:
         jsr     CALL_FN_71 ;prepare DMA Send
         lda     #$00
         tay
         sta     TMP_c9f1
         sta     TMP_c9f1+1
         lda     CALL_TYPE
         and     #$40
         beq     CALL_FN_6C ;branch if not ext
         lda     IS_IIgs
         bne     CALL_FN_5C ;branch if IIgs
CALL_FN_6C:
         lda     #$6c
         jmp     CALL_FN_X9 ;DMA Write type 3

CALL_FN_5C:
         lda     #$5c
         jmp     CALL_FN_X9 ;CALL_FN_5C - DMA Write IIgs

LDIO_DMA_READ:
         lda     REG_IO_DRQ,x
         bpl     @LCC8D     ;branch if no data waiting
         lda     REG_IO_PDMA_DACK,x
         sta     (BUF_PTR_L),y
         iny
         bne     LDIO_DMA_READ
         lda     #$00
         sta     TCOUNT_B1
         inc     BUF_PTR_H
         bne     @LCC80
         inc     BUF_PTR_VH
@LCC80:  inc     TMP_c9f1+1
         lda     TMP_c9f1+1
         cmp     LDIO_SIZE+1
         bne     LDIO_DMA_READ
         beq     @ret_ok

@LCC8D:  lda     REG_5380_STAT2,x
         and     #$08
         beq     @ret_ok    ;branch if pahse mismatch
         dec     TCOUNT_B0
         bne     LDIO_DMA_READ
         dec     TCOUNT_B1
         beq     @ret_fail
         bne     LDIO_DMA_READ

@ret_ok: clc
         rts

@ret_fail:
         sec
         sty     TMP_c9f1
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

FN_09:   jsr     IS_CHAR
         bcc     @FN_09_block_dev
         lda     #$07
         jmp     CALL_FN_X9 ;CALL_FN_07

@FN_09_block_dev:
         jsr     CALL_FN_0B_7C
         lda     LDIO_SIZE+1
         bne     @len_not_zero
         lda     LDIO_SIZE
         bne     @len_not_zero
         lda     #$22
         jmp     CALL_FN_60_RET ;FAIL_BADCTRLPARM

@len_not_zero:
         jsr     CMD_READ6_MB
         jsr     CHECK_END_BLK_VALID
         jsr     CALL_FN_00 ;DoPhases
         jsr     LCECF
         bcs     @LCCEF
         jsr     FN_29
@LCCEF:  jsr     WAIT_MSGIN_REQ
         jsr     CALL_FN_30 ;get status and message
         lda     CMD_STATUS
         bne     CALL_FN_39_RET ;send REQUEST_SENSE and process the output
         rts

CALL_FN_39_RET:
         jsr     FN_39
         bcs     FAIL_IOERROR_DUP
         rts

FAIL_IOERROR_DUP:
         lda     #$27
         jmp     CALL_FN_60_RET

FN_19:   lda     DEV_STATUS
         cmp     #$b4       ;bug - should be and #$04 or similar
         bne     @write_allowed
         lda     #$2b       ;ERROR_NOWRITE
         ldy     SLOT_OFFSET
         jmp     CALL_FN_60_RET ;ERROR_NOWRITE

@write_allowed:
         jsr     IS_CHAR
         bcc     FN_19_block_dev
         lda     #$07
         jmp     CALL_FN_X9 ;CALL_FN_07

FN_19_block_dev:
         jsr     CALL_FN_0B_7C
         lda     UNK_LEN+1
         bne     @len_not_zero ;??? not sure about label
         lda     UNK_LEN
         bne     @len_not_zero
         lda     #$27
         jmp     CALL_FN_60_RET ;ERROR_IOERROR

@len_not_zero:
         jsr     CMD_WRITE6_MB
         jsr     CHECK_END_BLK_VALID
         jsr     CALL_FN_00 ;DoPhases
         jsr     WAIT_DOUT_REQ
         jsr     CALL_FN_71 ;Prepare DMA send
         jsr     FN_29
         jsr     WAIT_MSGIN_REQ
         jsr     CALL_FN_30 ;get status and message
         rts

CALL_FN_00:
         lda     #$00
CALL_FN_X9:
         ldx     #$09
         ldy     SLOT_OFFSET
         jsr     BANKSWITCH ;CALL_FN_X9
         rts

IS_CHAR: lda     DEV_STATUS
         and     #$80
         bne     @not_char
         sec
         rts

@not_char:
         clc
         rts

CALL_FN_61:
         lda     #$61
         jmp     CALL_FN_X9 ;CALL_FN_61

CALL_FN_71:
         lda     #$71
         jmp     CALL_FN_X9 ;CALL_FN_71

         .byte   $a9
         .byte   $54
         .byte   $4c
         .byte   $4c
         .byte   $cd

FN_29:   jsr     LCC00
         jsr     SET_TIMEOUT_03
         jsr     LDIO_READ
         ldy     SLOT_OFFSET
         lda     #$00
         sta     REG_IO_5380_RST,y
         sta     REG_5380_MODE_SEL,y
         rts

CMD_WRITE6_MB:
         lda     #SCSI_CMD_WRITE6
         sta     SCSI_CDB_CMD
         ldx     #$06
         stx     SCSI_CMD_LEN
         jsr     SET_CDB_LEN ;adjust number of blocks to read
         rts

CMD_READ6_MB:
         lda     #SCSI_CMD_READ6
         sta     SCSI_CDB_CMD
         ldx     #$06
         stx     SCSI_CMD_LEN
         jsr     SET_CDB_LEN ;adjust number of blocks to read
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

SET_CDB_LEN:
         lda     UNK_LEN    ;CDB_LEN=(*$c929)?*$c92d+1:*$c92d
         ldx     $c929
         bne     @add_one
         ldx     $c92a
         bne     @add_one
         beq     @store_cdb_len

@add_one:
         clc
         adc     #$01
@store_cdb_len:
         sta     SCSI_CDB_LEN
         rts

CALL_FN_30:
         lda     #$30
         jmp     CALL_FN_X9 ;CALL_FN_30

LDIO_READ:
         ldy     #$00
         ldx     SLOT_OFFSET
@LCDCB:  lda     REG_IO_DRQ,x
         bpl     @LCE04
         lda     TMP_c9f1
         cmp     LDIO_SIZE
         bne     @LCDDA
         beq     @LCE17

@LCDDA:  lda     CALL_TYPE
         and     #$40
         beq     @LCDE8
         lda     IS_IIgs
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
@LCDFE:  inc     TMP_c9f1
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
@LCE39:  lda     TMP_c9f1
         sta     RX_LEN_LO
         lda     TMP_c9f1+1
         sta     RX_LEN_HI
         rts

FN_39:   lda     IS_IIgs
         sta     $c82e
         lda     #$00
         sta     IS_IIgs
         jsr     FN_49      ; SEND REQUEST SENSE store at $c901
         lda     $c82e
         sta     IS_IIgs
         ldx     #$02       ;sense key offset
         lda     $c901,x    ;get sense key
         cmp     #$06
         beq     GET_ASC    ;branch if UNIT_ATTENTION
         cmp     #$02
         beq     GET_ASC    ;branch if NOT_READY
         and     #$07       ;bug ??? - mask should be $0F
         cmp     #$01
         beq     @FN_39_ok  ;branch if RECOVERED_ERROR
         sec
         bcs     @FN_39_end

@FN_39_ok:
         clc
@FN_39_end:
         ldy     SLOT_OFFSET
         rts

FN_49:   lda     #$01       ;Send REQUEST_SENSE and store result at $c901
         sta     TMP_PTR_L
         lda     #$c9
         sta     TMP_PTR_H
         lda     #$00
         sta     TMP_PTR_VH ;TMP_PTR=$c901
         lda     #$67
         jsr     CALL_FN_X9 ;CALL_FN_67 - save TMP_PTR
         ldy     #$02       ;the pointer is copied to fake a PD command
         lda     TMP_PTR_L
         sta     (TMP_PTR_L),y ;TMP_PTR_L[2]=TMP_PTR_L
         iny
         lda     TMP_PTR_H
         sta     (TMP_PTR_L),y ;TMP_PTR_L[3]=TMP_PTR_H
         iny
         lda     #$00
         sta     (TMP_PTR_L),y ;TMP_PTR_L[4]=0;
         lda     #$b3
         jsr     CALL_FN_X9 ;CALL_FN_B3 - Send REQUEST_SENSE
         lda     #$77
         jsr     CALL_FN_X9 ;CALL_FN_77 - Restore TMP_PTR
         rts

GET_ASC: lda     #$00
         sta     TMP_PTR_VH
         sta     TMP_PTR_XH
         sta     CALL_TYPE
         lda     #$66
         jmp     CALL_FN_X9 ;CALL_FN_66 - Process ASC from sense data

         .byte   $4c
         .byte   $01
         .byte   $cd

FN_69:   lda     #$08       ;SET_BLK_2048
         bne     DO_SET_BLK

FN_59:   lda     #$02       ;SET_BLK_512
DO_SET_BLK:
         sta     NEW_BLK_SIZE
         lda     #$00
         sta     NEW_BLK_SIZE+1
         lda     #$aa
         jmp     CALL_FN_X9 ;CALL_FN_AA

CALL_FN_0B_7C:
         lda     #$0b
         jsr     CALL_FN_X9 ;CALL_FN_0B
         lda     #$7c
         jmp     CALL_FN_X9 ;CALL_FN_7C - add PART_START

LCECF:   jsr     SET_TIMEOUT_03
         lda     TIMEOUT
         sta     TCOUNT_B1
@LCED8:  lda     REG_5380_STAT,y
         and     #$3c
         cmp     #$24
         beq     clc_rts
         jsr     DEC_TIMEOUT3
         lda     TCOUNT_B1
         beq     CHECK_MSGIN_REQ
         lda     TCOUNT_B0
         bne     @LCED8
         lda     REG_5380_STAT,y
         cmp     #$6c
         beq     sec_rts
         bne     @LCED8

clc_rts: clc
         rts

sec_rts: sec
         rts

CHECK_MSGIN_REQ:
         lda     REG_5380_STAT,y
         and     #$3c
         cmp     #$2c
         beq     sec_rts
         bne     FAIL_IOERROR

WAIT_DOUT_REQ:
         jsr     SET_TIMEOUT_03
         lda     TIMEOUT
         sta     TCOUNT_B1
@wait1_loop:
         lda     REG_5380_STAT,y
         and     #$3c
         cmp     #$20
         beq     @wait1_rts
         jsr     DEC_TIMEOUT3
         lda     TCOUNT_B1
         beq     FAIL_IOERROR
         bne     @wait1_loop

@wait1_rts:
         rts

WAIT_MSGIN_REQ:
         jsr     SET_TIMEOUT_03
wait2_loop:
         lda     REG_5380_STAT,y
         and     #$3c
         cmp     #$2c
         beq     wait2_rts
         jsr     DEC_TIMEOUT3
         bcs     FAIL_IOERROR
         bcc     wait2_loop

wait2_rts:
         rts

SET_TIMEOUT_03:
         lda     #$ff
         sta     TCOUNT_B0
         sta     TCOUNT_B2
         lda     #$03
         sta     TCOUNT_B1
         rts

DEC_TIMEOUT3:
         dec     TCOUNT_B0
         bne     @not_timeout
         dec     TCOUNT_B2
         bne     @not_timeout
         dec     TCOUNT_B1
         beq     @timeout
@not_timeout:
         clc
         rts

@timeout:
         sec
         rts

FAIL_IOERROR:
         lda     #$27
         jmp     CALL_FN_60_RET

CHECK_END_BLK_VALID:
         clc
         lda     LBA_c8db
         adc     UNK_LEN
         sta     LBA_TEMP
         lda     LBA_c8db+1
         adc     #$00
         sta     LBA_TEMP+1
         lda     LBA_c8db+2
         adc     #$00
         sta     LBA_TEMP+2 ;LBA_TEMP=LBA_c8db+(char)UNK_c92d
         bcs     FAIL_BADBLOCK
         lda     LBA_TEMP+2
         sec
         sbc     UNK_c827
         bcc     @ret
         bne     FAIL_BADBLOCK
         lda     LBA_TEMP+1
         sec
         sbc     UNK_c827+1
         bcc     @ret
         bne     FAIL_BADBLOCK
         lda     LBA_TEMP
         sec
         sbc     UNK_c827+2
         bcc     @ret
         bne     FAIL_BADBLOCK ;if(LBA_TEMP>UNK_c827) FAIL_BADBLOCK
@ret:    rts

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
