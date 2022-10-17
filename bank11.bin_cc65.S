; Target assembler: cc65 v2.18.0 [--target none -C bank11.bin_cc65.cfg]
; 6502bench SourceGen v1.1.0
         .setcpu "65816"
SCSI_CMD_REZERO_UNIT = $01
SCSI_CMD_START_STOP = $1b
SCSI_CMD_RECEIVE_DIAG = $1c
SCSI_CMD_PREVENT_ALLOW_REMOVAL = $1e
P8E_IO_ERR =     $27        ;I/O error
SCSI_CMD_SEEK10 = $2b
SCSI_CMD_VERIFY10 = $2f

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
SLOT_OFFSET =    $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
UNK_c820 =       $c820      ; 0xff if PIO ?
PART_START =     $c824      ; partition start (3 bytes) seems to be in reverse endian (?)
LBA_c8db =       $c8db      ; LBA to use in CDB (?) (copied to CDB_LBA)
IS_IIgs  =       $c8f3      ;0x01 if IIgs
UNK_LEN  =       $c92d      ; unknown lenght - could be reverse endian ?????
BLKSIZE_H =      $c92f      ;byte1 of block size - reverse endian
BLKSIZE_L =      $c930      ;byte0 of block size - reverse endian
LDIO_SIZE =      $c9ee
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB
TIMEOUT  =       $c9f6      ; each unit is 1.25s

         .org    $cc00
         .a8
         .i8
FN_0B:   jsr     CLR_CDB_CMD6
         lda     CALL_TYPE
         and     #$40
         beq     @FN_0B_std_call
         lda     IS_IIgs
         bne     @LCC7C
@FN_0B_std_call:
         lda     #$06
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
         sta     LDIO_SIZE
         sta     UNK_LEN
         iny
         lda     (TMP_PTR_L),y
         sta     LDIO_SIZE+1
         sta     UNK_LEN+1
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
         ldy     SLOT_OFFSET
         lda     #$7c
         jmp     CALL_FN_XB ;CALL_FN_7C - add PART_START to UNK_c827

@LCC7C:  lda     #$01
         sta     XFER_MODE
         jsr     SET_NATIVE
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
         sta     LDIO_SIZE
         sta     UNK_LEN
         iny
         lda     [TMP_PTR_L],y
         sta     LDIO_SIZE+1
         sta     UNK_LEN+1
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
         jsr     SET_EMULATION
         jmp     @LCC65

SET_NATIVE:
         clc
         xce
         rts

SET_EMULATION:
         sec
         xce
         rts

FN_1B:   lda     #$9c
         jsr     CALL_FN_XB ;CALL_FN_9C
         ldy     #$02
         lda     (TMP_PTR_L),y
         sta     TIMEOUT
         ldy     #$0e
         sta     (TMP_PTR0),y
         ldy     SLOT_OFFSET
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
         lda     UNK_LEN
         sbc     $c92b
         pha
         lda     UNK_LEN+1
         sbc     $c92c
         bcc     @LCD23
         sta     UNK_LEN+1
         pla
         sta     UNK_LEN
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
         ldy     UNK_LEN
         sty     $c929
         ldy     UNK_LEN+1
         sty     $c92a
         stx     UNK_LEN+1
         sta     UNK_LEN
         ldy     SLOT_OFFSET
         rts

FN_5B:   lda     CALL_TYPE  ;handle smarport control codes $16-$1e
         and     #$40
         beq     @not_ext_call
         lda     IS_IIgs
         bne     load_native
         ldy     #$06
         bne     @load_emulation

@not_ext_call:
         ldy     #$04
@load_emulation:
         lda     (TMP_PTR_L),y
load_done:
         sec
         sbc     #$16       ;subtract $16 from the control number
         tax
         lda     SP_FN_TABLE_L,x
         sta     TMP_PTR1
         lda     SP_FN_TABLE_H,x
         sta     TMP_PTR1+1
         jmp     (TMP_PTR1)

load_native:
         clc
         xce
         ldy     #$06
         lda     [TMP_PTR_L],y
         sec
         xce
         jmp     load_done

SP_FN_TABLE_L:
         .byte   <SP_EXT_SEEK ;$16 - Extended Seek
         .byte   <SP_RECV_DIAG ;$17 - Receive Diag
         .byte   <SP_START_UNIT
         .byte   <SP_STOP_UNIT
         .byte   <SP_PREVENT_REMOVAL ;$1A -
         .byte   <SP_ALLOW_REMOVAL
         .byte   <SP_VERIFY
         .byte   <SP_REZERO_UNIT
         .byte   <Patch1Call ;$1E -
SP_FN_TABLE_H:
         .byte   >SP_EXT_SEEK
         .byte   >SP_RECV_DIAG
         .byte   >SP_START_UNIT
         .byte   >SP_STOP_UNIT
         .byte   >SP_PREVENT_REMOVAL
         .byte   >SP_ALLOW_REMOVAL
         .byte   >SP_VERIFY
         .byte   >SP_REZERO_UNIT
         .byte   >Patch1Call

SP_EXT_SEEK:
         jsr     CHECK_VALID
         jsr     CMD_SEEK10
EXECUTE_COMMAND:
         jsr     CALL_FN_00 ;DoPhases
         jsr     WAIT_FOR_STATUS
         jsr     CALL_FN_30 ;get status and message
         jmp     CMD_END

CHECK_VALID:
         lda     DEV_STATUS
         cmp     #$b4
         bne     ERROR_BADCTL_RET
         rts

ERROR_BADCTL_RET:
         ldy     SLOT_OFFSET
         lda     #$21
         jmp     CALL_FN_60_RET

SP_RECV_DIAG:
         jsr     LCEB6
         jsr     CALL_FN_00 ;DoPhases
         jsr     LCE42
         jsr     LCE1E
         rts

SP_START_UNIT:
         jsr     CMD_START_UNIT
         jmp     EXECUTE_CMD_DUP

SP_STOP_UNIT:
         jsr     CMD_STOP_UNIT
         jmp     EXECUTE_CMD_DUP

SP_PREVENT_REMOVAL:
         jsr     CHECK_VALID
         jsr     CMD_PREVENT_REMOVAL
         jmp     EXECUTE_CMD_DUP

SP_ALLOW_REMOVAL:
         jsr     CHECK_VALID
         jsr     CMD_ALLOW_REMOVAL
         jmp     EXECUTE_CMD_DUP

SP_VERIFY:
         jsr     CHECK_VALID
         jsr     CMD_VERIFY10
EXECUTE_CMD_DUP:
         jsr     EXECUTE_COMMAND ;BUG???? should be jmp or fn shoul end ith rts
CMD_END: lda     RET_CODE
         beq     @rts
         lda     #P8E_IO_ERR
         jmp     CALL_FN_60_RET

@rts:    rts

SP_REZERO_UNIT:
         jsr     CMD_REZERO_UNIT
         jmp     EXECUTE_CMD_DUP

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

FN_6B:   jsr     SET_RAM_BANK_01 ;CALL_B1_c806
         jsr     $c806
         jsr     SET_RAM_BANK_00
         rts

CALL_FN_00:
         lda     #$00
CALL_FN_XB:
         ldx     #$0b
         ldy     SLOT_OFFSET
         jsr     BANKSWITCH ;CALL_FN_XB
         rts

LCE1E:   ldy     SLOT_OFFSET
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

CALL_FN_30:
         lda     #$30
         jmp     CALL_FN_XB ;CALL_FN_30

LCE42:   jsr     SET_TIMEOUT_03
@LCE45:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$04
         beq     @LCE55
         jsr     DEC_TIMEOUT
         bcs     ERROR_IOERROR
         bcc     @LCE45

@LCE55:  rts

WAIT_FOR_STATUS:
         jsr     SET_TIMEOUT_03
@staus_loop:
         lda     REG_5380_STAT,y
         and     #$1c       ;MSG CD IO mask
         cmp     #$0c       ;status phase
         beq     @rts       ;branch if status phase
         jsr     DEC_TIMEOUT
         bcs     ERROR_IOERROR
         bcc     @staus_loop

@rts:    rts

ERROR_IOERROR:
         lda     #P8E_IO_ERR
         jmp     CALL_FN_60_RET

SET_TIMEOUT_03:
         lda     #$ff
         sta     TCOUNT_B0
         sta     TCOUNT_B2
         lda     #$03
         sta     TCOUNT_B1
         rts

DEC_TIMEOUT:
         dec     TCOUNT_B0
         bne     @LCE8C
         dec     TCOUNT_B2
         bne     @LCE8C
         dec     TCOUNT_B1
         beq     @LCE8E     ;should be bmi
@LCE8C:  clc
         rts

@LCE8E:  sec
         rts

CLR_CDB_CMD6:
         lda     #$06
         sta     SCSI_CMD_LEN
         bne     CLR_CDB    ;branch always

CLR_CDB_CMD10:
         lda     #$0a
         sta     SCSI_CMD_LEN
CLR_CDB: ldx     #$0a
         lda     #$00
@clr_cdb_loop:
         sta     SCSI_CDB_CMD,x
         dex
         bne     @clr_cdb_loop
         rts

CMD_SEEK10:
         jsr     CLR_CDB_CMD10
         lda     #SCSI_CMD_SEEK10
         sta     SCSI_CDB_CMD
         jsr     FN_8B
         jsr     FILL_CDB_UNK
         rts

LCEB6:   jsr     CLR_CDB_CMD6
         lda     #SCSI_CMD_RECEIVE_DIAG
         sta     SCSI_CDB_CMD
         lda     #$ff
         sta     SCSI_CDB_LEN
         jsr     FN_8B
         rts

CMD_START_UNIT:
         jsr     CLR_CDB_CMD6
         lda     #SCSI_CMD_START_STOP
STORE_CMD_LEN1:
         sta     SCSI_CDB_CMD
         lda     #$01
         sta     SCSI_CDB_LEN
         rts

CMD_STOP_UNIT:
         jsr     CLR_CDB_CMD6
         lda     #SCSI_CMD_START_STOP
         sta     SCSI_CDB_CMD
         rts

CMD_PREVENT_REMOVAL:
         jsr     CLR_CDB_CMD6
         lda     #SCSI_CMD_PREVENT_ALLOW_REMOVAL
         jmp     STORE_CMD_LEN1

         .byte   $60

CMD_ALLOW_REMOVAL:
         jsr     CLR_CDB_CMD6
         lda     #SCSI_CMD_PREVENT_ALLOW_REMOVAL
         sta     SCSI_CDB_CMD
         rts

CMD_VERIFY10:
         jsr     CLR_CDB_CMD10
         lda     #SCSI_CMD_VERIFY10
         sta     SCSI_CDB_CMD
         jsr     FN_8B
         jsr     FILL_CDB_UNK
         lda     #$01
         sta     SCSI_CDB10_8
         rts

CMD_REZERO_UNIT:
         jsr     CLR_CDB_CMD6
         lda     #SCSI_CMD_REZERO_UNIT
         sta     SCSI_CDB_CMD
         rts

FILL_CDB_UNK:
         lda     CALL_TYPE
         and     #$40
         beq     @std_call
         lda     IS_IIgs
         bne     @IIgs
@std_call:
         ldy     #$00
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

@IIgs:   clc
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
         and     #$40       ;BUF_PTR=TMP_PTR[2]
         beq     @FN_8B_std_call
         lda     IS_IIgs
         bne     @FN_8B_IIgs
@FN_8B_std_call:
         ldy     #$02
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_L
         iny
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_H
@FN_8B_end:
         ldy     SLOT_OFFSET
         rts

@FN_8B_IIgs:
         clc
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
         jmp     @FN_8B_end

FN_4B:   lda     #$06       ;WAIT_NOT_BUSY
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
