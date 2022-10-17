; Target assembler: cc65 v2.18.0 [--target none -C bank06.bin_cc65.cfg]
; 6502bench SourceGen v1.1.0
         .setcpu "65816"
SCSI_CMD_READ6 = $08
SCSI_CMD_WRITE6 = $0a
P8E_IO_ERR =     $27        ;I/O error
P8E_WRITE_PROT = $2b        ;Disk write protected

TMP_PTR1 =       $1b        ; temporary ZP pointer 
PD_PAR_BLK_LO =  $46        ;PRODOS input parameter Block lo
PD_PAR_BLK_HI =  $47        ;PRODOS input parameter Block hi
TMP_PTR_L =      $f6        ; temporary ZP long pointer
TMP_PTR_H =      $f7
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
REG_5380_DATA =  $c000      ; R current SCSI data lines status
REG_5380_DATA_OUT = $c000   ; W SCSI data output register
REG_5380_ICMD =  $c001      ; RW Initiator command register
REG_5380_MODE_SEL = $c002   ; RW Mode select register
REG_5380_SEL =   $c004      ; W Select enable register
REG_IO_DEV_ID =  $c009      ; R SCSI device ID
REG_IO_BANK_SEL = $c00a     ; W memory bank select
TCOUNT_B0 =      $c801      ; timeout counter LSB
SEL_TARGET =     $c806      ; SCSI (BUS?) ID of selected target
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SCSI_CMD_LEN =   $c80d      ; SCSI COMMAND lenght
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SCSI_CDB_LUN =   $c80f      ; 
SCSI_CDB_LBA_HI = $c810
SCSI_CDB_LBA_LO = $c811
SCSI_CDB_LEN =   $c812
SLOT_OFFSET =    $c81a      ; slot adress (n+8)<<4 
SAVE_SP_CMD =    $c81b      ; saved SmartPort Command
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
CMD_STATUS =     $c81e      ; SCSI CMD status - 0x00 OK, 0x02 Check condition
SDAT_BASE =      $c831      ;start of SDAT table (extends to $C8A7)
TMP_COUNTER =    $c8c6
RD_ERRORS =      $c8c9      ; used only in blk 6 to count the number of read errors
PARTMAP_OK =     $c8cf      ; $00 if failed to read Partition Map. non-zero if PM detected
BLOCK_SIZE =     $c8d0      ; temp int storage (size of DDM block?)
TEMP_c8da =      $c8da      ; unknown
PTR_c8df =       $c8df      ; unknown
SAVE_SP2 =       $c8ed      ;saved SP - also used a random temp
UNK_LEN  =       $c92d      ; unknown lenght - could be reverse endian ?????
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB

         .org    $cc00
         .a8
         .i8
FN_06:   lda     DEV_STATUS
         cmp     #$b4
         bne     @not_write_protected
         lda     #P8E_WRITE_PROT ;ERROR NOWRITE
         jmp     CALL_FN_60_RET

@not_write_protected:
         lda     BUF_PTR_L
         sta     PTR_c8df
         lda     BUF_PTR_H
         sta     PTR_c8df+1 ;copy BUF_PTR to $c8df
         jsr     FN_26      ;check if valid partition map is present
         bcs     EXECUTE_FORMAT_PM_INIT ;branch if failed to read partition map
         rts

EXECUTE_FORMAT_PM_INIT:
         jsr     @CALL_FN_D3 ;FORMAT_UNIT
         jsr     NEW_PM
         lda     #$0c
         jmp     CALL_FN_X6_SY ;CALL_FN_0C - Set New SDAT

@CALL_FN_D3:
         lda     #$d3       ;FORMAT_UNIT
CALL_FN_X6_SY:
         ldx     #$06
         ldy     SLOT_OFFSET
         jsr     BANKSWITCH ;CALL_FN_X6
         rts

NEW_PM:  jsr     EXEC_PARSE_READ_CAPACITY
         jsr     CREATE_PM
         rts

EXEC_PARSE_READ_CAPACITY:
         lda     #$00
         sta     BUF_PTR_L
         sta     TMP_PTR_L
         lda     #$ca
         sta     BUF_PTR_H
         sta     TMP_PTR_H  ;set BUF_PTR and TMP_PTR to $ca00
         ldy     #$02
         lda     TMP_PTR_L
         sta     (TMP_PTR_L),y
         iny
         lda     TMP_PTR_H
         sta     (TMP_PTR_L),y
         lda     #$c3
         jsr     CALL_FN_X6_SY ;CALL_FN_C3 - READ_CAPACITY
         lda     #$00
         sta     BUF_PTR_L
         lda     #$ca
         sta     BUF_PTR_H  ;set BUF_PTR to $ca00
         ldy     #$03
         lda     (BUF_PTR_L),y
         sta     UNK_LEN-1  ;save LSB of device size at $c92c ($c929+3)
         sec
         ldx     DEV_STATUS
         cpx     #$f8       ;block dev, W, R, online, fmt
         beq     @sbc_45
         sbc     #$40
         jmp     @sbc_40

@sbc_45: sbc     #$45
@sbc_40: sta     $c8d2,y    ;store LSB of device size -$40 or -$45 depending on the value of DEV_STATUS
         dey
@sbc_loop:
         lda     (BUF_PTR_L),y
         sta     $c929,y    ;store byte 1..3 of device size to $c929
         sbc     #$00
         sta     $c8d2,y    ;store byte 1..3 of device size -$40 (or $45) to $c8d2
         dey
         bpl     @sbc_loop
         ldy     #$06
         lda     (BUF_PTR_L),y
         sta     BLOCK_SIZE
         iny
         lda     (BUF_PTR_L),y
         sta     BLOCK_SIZE+1 ;store block lenght to $c8d0
         rts

CREATE_PM:
         lda     #$00       ;build and write the partition map to the disk
         sta     PD_PAR_BLK_LO ;could reuse SET_BLK_BLK_CLR below
         sta     PD_PAR_BLK_HI ;set PAR_BLK to 0
         sta     BUF_PTR_L
         lda     #$ca
         sta     BUF_PTR_H  ;set BUF_PTR to $ca00
         jsr     CLR_BUF
         lda     #$45
         ldy     #$00
         sta     (BUF_PTR_L),y
         iny
         lda     #$52
         sta     (BUF_PTR_L),y ;fill DDM signature
         lda     BLOCK_SIZE
         iny
         sta     (BUF_PTR_L),y
         iny
         lda     BLOCK_SIZE+1
         sta     (BUF_PTR_L),y ;copy block size from TEMP_c8d0 into DDM size
         ldx     #$00
         ldy     #$04
@blk_count_loop:
         lda     $c929,x    ;copy block count from $c929
         sta     (BUF_PTR_L),y
         inx
         iny
         cpx     #$08
         bne     @blk_count_loop
         ldy     #$11
         lda     #$01
         sta     (BUF_PTR_L),y ;set DDM drive count to 1
         lda     #$1f
         jsr     CALL_FN_X6_SY ;CALL_FN_1F
         jsr     EXECUTE_WRITE ;WRITE DDM in block 0
         lda     #$01
         jsr     SET_BLK_BLK_CLR
         lda     #$2f
         jsr     CALL_FN_X6_SY ;CALL_FN_2F
         jsr     EXECUTE_WRITE ;WRITE MASTER PDM in block 1
         lda     #$02
         jsr     SET_BLK_BLK_CLR
         lda     #$0f
         jsr     CALL_FN_X6_SY ;CALL_FN_0F
         jsr     EXECUTE_WRITE ;WRITE PDM ENTRY in block 2
         ldy     SLOT_OFFSET
         rts

EXECUTE_WRITE:
         jsr     FILL_CMD_WRITE6
         lda     #$20
         jmp     CALL_FN_X6_SY ;CALL_FN_20

SET_BLK_BLK_CLR:
         sta     PD_PAR_BLK_LO ;set PAR_BLK to A, set BUF_PTR to $ca00, clear $ca00 buffer
         lda     #$00
         sta     PD_PAR_BLK_HI
         sta     BUF_PTR_L
         lda     #$ca
         sta     BUF_PTR_H
         jsr     CLR_BUF
         rts

CLR_BUF: lda     #$00       ;clear 256 bytes at BUF_PTR
         tay
@clr_buf_loop:
         sta     (BUF_PTR_L),y
         iny
         bne     @clr_buf_loop
         rts

FN_26:   lda     #$47       ;try to read DDM and PDM
         jsr     CALL_FN_X6_SY ;CALL_FN_47 - READ DDM and MASTER PDM
         lda     PARTMAP_OK
         beq     @ret_fail
         clc
         rts

@ret_fail:
         sec
         rts

         .byte   $a9
         .byte   $08
         .byte   $4c
         .byte   $2c
         .byte   $cd

FILL_CMD_WRITE6:
         lda     #SCSI_CMD_WRITE6
         jmp     FILL_SCSI_CDB

FILL_SCSI_CDB:
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
         rts

         .byte   $a5
         .byte   $46
         .byte   $8d
         .byte   $c7
         .byte   $c8
         .byte   $a5
         .byte   $47
         .byte   $8d
         .byte   $c8
         .byte   $c8
         .byte   $60
         .byte   $ad
         .byte   $c7
         .byte   $c8
         .byte   $85
         .byte   $46
         .byte   $ad
         .byte   $c8
         .byte   $c8
         .byte   $85
         .byte   $47
         .byte   $60

FN_16:   lda     SCSI_CDB_CMD
         cmp     #SCSI_CMD_READ6
         beq     @FN_16_read ;branch if SCSI READ6 command
         cmp     #SCSI_CMD_WRITE6 ;redundant ???
         rts

@FN_16_read:
         lda     #$00
         sta     RET_CODE
         jsr     COPY_CMD_c81b
         jsr     CHECK_REQ_SENSE
         bcs     @LCD8C     ;branch if sense error
         jsr     TRY_10_RD
         bcc     @FN_16_ret_ok
         jsr     TRY_10_WR_RD
         bcc     @FN_16_ret_ok
         jsr     LCE80
         bcs     ERROR_IOERROR
@FN_16_ret_ok:
         clc
         lda     #$00
         sta     RET_CODE
         rts

@LCD8C:  jsr     SET_BUF_PTR_CA00
         lda     SAVE_SP_CMD
         cmp     #SCSI_CMD_WRITE6
         beq     @FN_16_write
         jsr     READ_BLK
         bcs     ERROR_IOERROR
         bcc     @FN_16_ret_ok

@FN_16_write:
         jsr     WRITE_BLK_CA00
         bcc     @FN_16_ret_ok
ERROR_IOERROR:
         lda     #P8E_IO_ERR
         jmp     CALL_FN_60_RET

CALL_FN_49:
         lda     #$49       ;send REQUEST_SENSE and store res at $c901
         jmp     CALL_FN_X6_SY ;CALL_FN_49

CHECK_REQ_SENSE:
         jsr     CALL_FN_49 ;send REQUEST_SENSE and store res at $c901
         ldx     #$02
         lda     $c901,x    ;get SENSE KEY
         cmp     #$06
         beq     FN_66      ;if(SENSE_KEY==UNIT_ATTENTION) jmp PROCESS_ASC
         cmp     #$02
         beq     FN_66      ;if(SENSE_KEY==NOT_READY) jmp PROCESS_ASC
         and     #$07       ;likely a bug - the mask for sense key should be $F
         cmp     #$01
         beq     @recoverable ;branch if recoverable error
         sec
         bcs     @sense_end

@recoverable:
         clc
@sense_end:
         ldy     SLOT_OFFSET
         rts

LDA_ASC: ldx     #$0c
         lda     $c901,x
         rts

FN_66:   jsr     LDA_ASC    ;process ASC from SENSE_DATA at $c901
         cmp     #$28       ;load ASC (additional sense code)
         beq     LCDDF
         cmp     #$b7
         beq     LCE27
         cmp     #$b0
         beq     ERROR_OFFLINE
LCDDF:   jsr     LCDF9
         lda     CALL_TYPE
         cmp     #$01
         bne     ERROR_DISKSWITCH
         lda     #$27       ;ERROR_IOERROR
         bne     RET_ERROR

ERROR_DISKSWITCH:
         lda     #$2e
RET_ERROR:
         ldy     SLOT_OFFSET
         jmp     CALL_FN_60_RET

ERROR_OFFLINE:
         lda     #$2f
         bne     RET_ERROR

LCDF9:   lda     #$0c
         jmp     CALL_FN_X6_SY ;CALL_FN_0C

FN_56:   lda     #$ff
         sta     SAVE_SP2   ;number of retrys
@FN_65_try_again:
         lda     #$a3
         jsr     CALL_FN_X6_SY ;CALL_FN_A3 - SEND CMD_TEST_UNIT_READY
         lda     CMD_STATUS
         beq     @FN_56_ret_ok
         jsr     DELAY_C0FF
         jsr     CALL_FN_49 ;send REQUEST sense and store in $c901
         jsr     LDA_ASC
         cmp     #$28
         beq     @FN_56_ret_ok
         cmp     #$b0
         beq     @FN_56_ret_ok
         dec     SAVE_SP2
         bne     @FN_65_try_again
         sec
         rts

@FN_56_ret_ok:
         clc
         rts

LCE27:   jsr     FN_56
         bcc     LCDDF
         jmp     ERROR_IOERROR

DELAY_C0FF:
         tya
         ldx     #$ff
         ldy     #$c0
@delay_loop:
         dex
         bne     @delay_loop
         dey
         bne     @delay_loop
         tay
         rts

TRY_10_RD:
         lda     #$00       ;try 10 Reads. fail if all failed
         sta     RD_ERRORS
         sta     TMP_COUNTER ;TEMP_c8c6 count from 0 to 9
@loop1:  jsr     READ_BLK_CA00
         bcc     @skip      ;branch if read ok
         inc     RD_ERRORS
@skip:   inc     TMP_COUNTER
         lda     TMP_COUNTER
         cmp     #$0a
         bne     @loop1
         lda     RD_ERRORS
         cmp     #$0a
         beq     @io_error  ;error if all read tries failed
         cmp     #$05       ;useful?
         rts

@io_error:
         jmp     ERROR_IOERROR

TRY_10_WR_RD:
         lda     #$00       ;try 10 WR/RD, fail if any failed
         sta     TMP_COUNTER ;TEMP_c8c6 count from 0 to 9
@loop2:  jsr     WRITE_BLK_CA00
         bcs     @ret_error
         jsr     READ_BLK_CA00
         bcs     @ret_error
         inc     TMP_COUNTER
         lda     TMP_COUNTER
         cmp     #$0a
         bne     @loop2
         clc
         rts

@ret_error:
         sec
         rts

LCE80:   lda     #$21
         jsr     CALL_FN_X6 ;CALL_FN_21
         lda     #$3d
         jsr     CALL_FN_X6 ;CALL_FN_3D - auto select XFER_MODE
         lda     RET_CODE
         bne     @LCE9B
         jsr     WRITE_BLK_CA00
         bcs     @LCE95
         rts

@LCE95:  jsr     TRY_10_WR_RD
         bcs     LCE80
         rts

@LCE9B:  sec
         rts

READ_BLK_CA00:
         jsr     SET_BUF_PTR_CA00 ;read block at LBA $cddb to buf at $ca00
READ_BLK:
         lda     #$41
         jsr     CALL_FN_X6_SY ;CALL_FN_41 - LOAD CDB READ6 - 1 block from LBA at $c8db
         jsr     CALL_FN_00 ;Do Phases
         jsr     CALL_FN_01 ;Data Xin
         lda     #$a0
         jsr     CALL_FN_X6_SY ;CALL_FN_A0 - Get status and message
CHECK_STATUS_RET:
         lda     CMD_STATUS ;check status
         beq     @ret_ok
         sec
         rts

@ret_ok: clc
         rts

WRITE_BLK_CA00:
         jsr     SET_BUF_PTR_CA00 ;write block at $ca00 to LBA at $c8db
         lda     #$51
         jsr     CALL_FN_X6_SY ;CALL_FN_51 - LOAD CDB WRITE6 - 1 block from LBA at $c8db
         jsr     CALL_FN_00 ;Do Phases
         jsr     CALL_FN_11 ;Data Xout
         lda     #$a0
         jsr     CALL_FN_X6_SY ;CALL_FN_A0 - Get status and message
         jmp     CHECK_STATUS_RET

CALL_FN_00:
         lda     #$00       ;DoPhases
CALL_FN_X6:
         ldx     #$06
         jsr     BANKSWITCH ;CALL_FN_X6
         rts

CALL_FN_01:
         lda     #$01
         bne     CALL_FN_X6 ;CALL_FN_01 - READ data to BUF_PTR

CALL_FN_11:
         lda     #$11
         bne     CALL_FN_X6 ;CALL_FN_11 - Data Xout

SET_BUF_PTR_CA00:
         lda     #$00
         sta     BUF_PTR_L
         lda     #$ca
         sta     BUF_PTR_H
         rts

COPY_CMD_c81b:
         lda     SCSI_CDB_CMD
         sta     SAVE_SP_CMD
         rts

FN_46:   lda     #$02       ;try to call FN_36 twice
         sta     TEMP_c8da
@loop3:  lda     #$00
         sta     RET_CODE
         jsr     FN_36      ;BUS_FREE and TEST_UNIT_READY
         bcc     @LCF03     ;call to FN_36 was successfull
         dec     TEMP_c8da
         bne     @loop3     ;loop one more time
@LCF03:  rts

FN_36:   jsr     LCF21      ;CALL_FN_3A - BUS_FREE
         bcs     RET_EC_27
         jsr     SCSI_ARBITRATE_ALT
         bcs     RET_EC_27
         jsr     SCSI_SELECT_ALT
         bcs     RET_EC_27
         lda     #$44
         jsr     CALL_FN_X6_SY ;CALL_FN_44
         clc
         rts

RET_EC_27:
         lda     #$27
         sta     RET_CODE
         sec
         rts

LCF21:   jsr     CALL_FN_3A
         bcs     RET_EC_27  ;seems redundant as the same is in the calling function
         rts

SCSI_ARBITRATE_ALT:
         lda     REG_5380_MODE_SEL,y
         and     #$fe
         sta     REG_5380_MODE_SEL,y ;reset arbitrate bit
         lda     REG_IO_DEV_ID,y
         sta     REG_5380_DATA_OUT,y ;put scsi id on the bus
         lda     REG_5380_MODE_SEL,y
         ora     #$01
         sta     REG_5380_MODE_SEL,y ;initiate arbitration
         lda     REG_5380_ICMD,y
         and     #$20
         bne     SCSI_ARBITRATE_ALT ;lost SCSI arbitration, try again
         lda     REG_5380_DATA,y
         sec
         sbc     REG_IO_DEV_ID,y
         beq     @LCF55     ;only this device requested to arbitrate
         sec
         sbc     REG_IO_DEV_ID,y
         bmi     @LCF55     ;we are the highest priority
         sec                ;we are not the highest priority
         rts                ;return fail - bug(?) does not reset arbitrate bit

@LCF55:  lda     REG_5380_ICMD,y ;check again for lost arbitration
         and     #$20
         bne     SCSI_ARBITRATE_ALT ;arbitration lost try again
         clc
         rts                ;return success

SCSI_SELECT_ALT:
         lda     #$04       ;very similar to SCSI SELECT
         sta     REG_5380_ICMD,y
         nop
         lda     REG_IO_DEV_ID,y
         ora     SEL_TARGET
         sta     REG_5380_DATA_OUT,y
         lda     #$0d
         sta     REG_5380_ICMD,y
         lda     #$00
         sta     REG_5380_MODE_SEL,y
         lda     #$00
         sta     REG_5380_SEL,y
         lda     #$05
         sta     REG_5380_ICMD,y
         sta     TCOUNT_B0
@retry_not_busy:
         jsr     WAIT_NOT_BUSY
         bcc     @end_sel
         dec     TCOUNT_B0
         bne     @retry_not_busy
         jmp     ret_fail2

@end_sel:
         lda     #$00
         sta     REG_5380_ICMD,y
         clc
         rts

CALL_FN_3A:
         lda     #$3a
         jmp     CALL_FN_X6_SY ;CALL_FN_3A

WAIT_NOT_BUSY:
         lda     #$4b
         jsr     CALL_FN_X6_SY ;CALL_FN_4B
         lda     SDAT_BASE-1
         beq     ret_fail2
         clc
         rts

ret_fail2:
         sec
         rts

CALL_FN_60_RET:
         sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH ;CALL_FN_60_RET

FN_TABLE:
         .word   FN_06
         .word   FN_16
         .word   FN_26
         .word   FN_36
         .word   FN_46
         .word   FN_56
         .word   FN_66
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea

         .org    $cfcc
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
         jsr     @DO_CALL_FN
         pla
         and     #$0f
         sta     REG_IO_BANK_SEL,y
         clc
         rts

@DO_CALL_FN:
         jmp     (TMP_PTR1)

         .byte   $02
         .byte   $31
         .byte   $34
         .byte   $30
