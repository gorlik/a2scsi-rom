; Target assembler: cc65 v2.18.0 [--target none -C bank10.bin_cc65.cfg]
; 6502bench SourceGen v1.8.3
         .setcpu "65816"
DIBTAB_ENTRY_SIZE = $1b
P8E_IO_ERR =     $27        ;I/O error

TMP_PTR0 =       $19        ; temporary ZP pointer 
JMP_PTR  =       $1b        ; Jmp target ZP pointer 
MEM_PTR_L =      $f6        ; temporary ZP long pointer
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
TMP_c807 =       $c807      ; save BUF_PTR_VH ???
INIT_FLAG =      $c809      ; card initialized flag (init=$77)
TMP_c80a =       $c80a      ; unknown
RET_CODE =       $c80b      ; 
BSW_TEMP =       $c80c      ; TEMP in BANKSWITCH
SCSI_CMD_LEN =   $c80d      ; SCSI COMMAND lenght
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SCSI_CDB_LEN =   $c812
SLOT_OFFSET =    $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
NEW_BLK_SIZE =   $c82a      ; desired block size in SetBlock
RX_LEN_LO =      $c8e4      ; bytes read if call successfull
RX_LEN_HI =      $c8e5      ; bytes read if call successfull
TEMP_16  =       $c8ee      ;generic 16-bit temp
IS_IIgs  =       $c8f3      ;0x01 if IIgs
TEMP_c915 =      $c915      ;unknown
TEMP_VH  =       $c921      ;unknown
TEMP_XH  =       $c922      ;unknown
UNK_LEN  =       $c92d      ; unknown lenght - could be reverse endian ?????
DIBTAB   =       $c931      ;start of DIBTAB (extends to $C9ED)
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB

         .org    $cc00
         .a8
         .i8
FN_0A:   jsr     DIBTAB_LOOKUP ;TMP_PTR0=&DIBTAB[DEV_IDX]
         bcc     @entry_found_0a
         jsr     CALL_FN_0D ;SEND INQUIRY and FILL DIBTAB
         jsr     DIBTAB_LOOKUP ;TMP_PTR0=&DIBTAB[DEV_IDX]
@entry_found_0a:
         jsr     FN_7A      ;copy DIBTAB entry from TMP_PTR0 to BUF_PTR omitting signature
         jsr     FN_2A      ;EXECUTE TEST_UNIT_READY (special tape handling)
         lda     #$7f
         jsr     CALL_FN_XA ;CALL_FN_7F - FN_0D, FN_8A
         jmp     restore_y_return

FN_7A:   lda     #$1a       ;memcpy (BUF_PTR, TMP_PTR0+1, 25 or 26) (TMP_PTR0 points to DIBTAB[DEV_IDX], omits signature, corrects for std and ext call
         sta     RX_LEN_LO
         ldy     #$00
         sty     RX_LEN_HI  ;RX_LEN=$001a (size of DIBTAB entry)
         lda     CALL_TYPE
         and     #$40
         beq     @not_ext_call ;branch if not ext call
         lda     IS_IIgs
         bne     IIgs       ;branch if IIgs detected
@not_ext_call:
         iny
         lda     (TMP_PTR0),y
         sta     DEV_STATUS ;DEV_STATUS=DIBTAB.dev_status
         dey
         sta     (BUF_PTR_L),y
         cpy     #$04
         bne     @LCC41
         lda     CALL_TYPE
         beq     std_sp_call ;branch if std call
@LCC41:  iny
         cpy     #$1a
         beq     FN_7A_end
         bne     @not_ext_call

std_sp_call:
         iny                ;messy copy code
         dec     RX_LEN_LO
         iny
@LCC4D:  lda     (TMP_PTR0),y
         dey
         dey
         sta     (BUF_PTR_L),y
         iny
         iny
         iny
         cpy     #$1b
         bne     @LCC4D
FN_7A_end:
         jmp     restore_y_return

IIgs:    ldy     #$01
@LCC5F:  lda     (TMP_PTR0),y
         dey
         sta     [BUF_PTR_L],y
         iny
         iny
         cpy     #$1b
         bne     @LCC5F
         beq     FN_7A_end

CALL_FN_0D:
         lda     #$0d
         jmp     CALL_FN_XA ;CALL_FN_0D

         .byte   $99
         .byte   $0b
         .byte   $c0

ERROR_IOERROR:
         lda     #P8E_IO_ERR
         ldy     SLOT_OFFSET
         jmp     CALL_FN_60_RET

DIBTAB_LOOKUP:
         ldx     DEV_IDX    ;TMP_PTR0=&DIBTAB[DEV_IDX]
         lda     #<DIBTAB   ;offset of DIBTAB from $C900
next_entry:
         dex
         bmi     entry_found
         clc
         adc     #DIBTAB_ENTRY_SIZE ;add 27 (size of DIBTAB entry)
         jmp     next_entry

entry_found:
         sta     TMP_PTR0
         lda     #>DIBTAB
         sta     TMP_PTR0+1 ;19,1a contain $c9xx (address of selected DIBTAB entry)
         ldy     #$00
         lda     (TMP_PTR0),y
         cmp     #$86       ;check for DIBTAB entry ID
         bne     DIBTAB_ERROR
         clc
         rts

DIBTAB_ERROR:
         sec
         rts

restore_y_return:
         ldy     SLOT_OFFSET
         rts

FN_1A:   jsr     FN_6A      ;tmp_PTR0=&DIBTAB[DEV_IDX], set DEV_STATUS and copy BLK_SIZE
         jsr     FN_2A      ;EXECUTE TEST_UNIT_READY (special tape handling)
         lda     #$6f
         jsr     CALL_FN_XA ;CALL_FN_6F
         jmp     restore_y_return

FN_6A:   jsr     DIBTAB_LOOKUP ;TMP_PTR0=&DIBTAB[DEV_IDX]
         bcc     @entry_found_6a
         jsr     CALL_FN_0D
@entry_found_6a:
         jsr     FN_8A      ;Set DEV_STATUS, copy BLKSIZE to BUF_PTR+1
         jmp     restore_y_return

FN_8A:   lda     CALL_TYPE  ;SET DEV_STATUS and copies dibtab device status and block size to *BUF_PTR
         and     #$40       ;memcpy(BUF_PTR_L, TMP_PTR0+1, 4 or 5)
         beq     @FN_8A_not_ext
         lda     IS_IIgs
         bne     @FN_8A_IIgs ;branch if IIgs
         ldy     #$05
         bne     @FN_8A_loop1

@FN_8A_not_ext:
         ldy     #$04
@FN_8A_loop1:
         lda     (TMP_PTR0),y
         dey
         sta     (BUF_PTR_L),y
         tya
         bne     @FN_8A_loop1
         ldy     #$01
         lda     (TMP_PTR0),y
         sta     DEV_STATUS ;put device status in $c9f3
@FN_8A_end:
         jmp     restore_y_return

@FN_8A_IIgs:
         ldy     #$05
@FN_8A_loop2:
         lda     (TMP_PTR0),y
         dey
         sta     [BUF_PTR_L],y
         tya
         bne     @FN_8A_loop2
         ldy     #$01
         lda     (TMP_PTR0),y
         sta     DEV_STATUS
         jmp     @FN_8A_end

FN_3A:   lda     #$af
         jmp     CALL_FN_XA ;CALL_FN_AF

FN_4A:   ldy     #$02       ;SET_BLOCK_SIZE - get new blk size and fall though FN_AA
         lda     CALL_TYPE
         and     #$40
         beq     @FN_4A_std_call
         lda     IS_IIgs
         bne     FN_4A_native
@FN_4A_std_call:
         lda     (MEM_PTR_L),y
         sta     NEW_BLK_SIZE
         iny
         lda     (MEM_PTR_L),y
         sta     NEW_BLK_SIZE+1 ;*$c82a=new block size (pointer member of the smartport control list)
FN_AA:   ldy     #$07
         jsr     SET_TIMEOUT_0C
         jsr     EXECUTE_MODE_SENSE
         jsr     EXECUTE_MODE_SEL_SETBLK
         lda     TMP_c807
         sta     BUF_PTR_VH
         lda     INIT_FLAG
         cmp     #$77
         bne     @FN_AA_end ;branch if card not init
         lda     #$44
         sta     UNK_LEN+1
         lda     SEL_TARGET
         sta     UNK_LEN
         lda     #$0c
         jsr     CALL_FN_XA ;CALL_FN_0C - Set new SDAT
         sty     UNK_LEN
         sty     UNK_LEN+1
@FN_AA_end:
         jmp     restore_y_return

FN_4A_native:
         lda     [MEM_PTR_L],y
         sta     NEW_BLK_SIZE
         iny
         lda     [MEM_PTR_L],y
         sta     NEW_BLK_SIZE+1 ;*$c82a=new block size (pointer member of the smartport control list)
         jmp     FN_AA

WAIT_DATA_IN:
         jsr     SET_TIMEOUT_0C
@wait_din_loop:
         lda     REG_5380_STAT,y
         and     #$3c
         cmp     #$24
         beq     clc_rts    ;branch if data in phase - (REQ & IO asserted)
         cmp     #$2c
         beq     rts1       ;branch if status phsase - REQ & IO & CD asserted
         jsr     DEC_TIMEOUT
         bcs     rts1
         bcc     @wait_din_loop

DEC_TIMEOUT:
         dec     TCOUNT_B0
         bne     clc_rts
         dec     TCOUNT_B2
         bne     clc_rts
         dec     TCOUNT_B1
         bne     clc_rts
         sec
         rts

clc_rts: clc
rts1:    rts

SET_TIMEOUT_0C:
         lda     #$00
         sta     TCOUNT_B0
         sta     TCOUNT_B2
         lda     #$0c
         sta     TCOUNT_B1
         ldy     SLOT_OFFSET
         rts

WAIT_FOR_DOUT:
         jsr     SET_TIMEOUT_0C
@wait_dout_loop:
         lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$00
         beq     clc_rts
         jsr     DEC_TIMEOUT
         bcs     rts1
         bcc     @wait_dout_loop

CALL_00_DoPhases:
         lda     #$00
CALL_FN_XA:
         ldy     SLOT_OFFSET
         ldx     #$0a
         jmp     BANKSWITCH

CALL_FN_B0:
         lda     #$b0       ;DoPhases (no BUS_FREE)
         bne     CALL_FN_XA

CALL_FN_30:
         lda     #$30       ;Get STATUS and MESSAGE
         bne     CALL_FN_XA

READ_PIO:
         jsr     CALL_FN_5D ;FORCE_PIO_MODE
         lda     #$01       ;CALL_FN_01 - read DATA to BUF_PTR
CALL_FN_XA_REST:
         jsr     CALL_FN_XA ;CALL_FN_XA
         lda     TMP_c80a
         sta     XFER_MODE  ;restore XFER_MODE from c80a (saved in FN_5D)
         rts

WRITE_PIO:
         jsr     CALL_FN_5D ;FORCE_PIO_MODE
         lda     #$11
         bne     CALL_FN_XA_REST ;CALL_FN_11_restore - Data Xout + restore XFER_MODE

CALL_FN_5D:
         lda     #$5d       ;FORCE_PIO_MODE
         jmp     CALL_FN_XA

FILL_SETBLK:
         ldx     #$06
@mode_sel_cpy:
         lda     MODE_SELECT_DATA,x
         sta     SCSI_CMD_LEN,x
         dex
         bpl     @mode_sel_cpy ;copy MODE_SELECT_CMD to CDB
         jsr     BUF_PTR_CA00
         lda     NEW_BLK_SIZE
         sta     $ca0a
         lda     NEW_BLK_SIZE+1
         sta     $ca0b
         lda     #$00
         sta     $ca00
         lda     #$0c
         sta     SCSI_CDB_LEN
         lda     DEV_STATUS
         cmp     #$b4       ;status for CD-ROM
         bne     @LCE11     ;end if not CD-ROM
         lda     NEW_BLK_SIZE+1
         cmp     #$08
         bcc     @LCE11
         lda     NEW_BLK_SIZE
         cmp     #$04
         bcc     @LCE11
         lda     #$01
         ora     $ca0e
         sta     $ca0e
         lda     #$14
         sta     SCSI_CDB_LEN
@LCE11:  rts

SCSI_CMD_1A:
         ldx     #$06
@mode_sense_cpy:
         lda     MODE_SENSE_DATA,x
         sta     SCSI_CMD_LEN,x
         dex
         bpl     @mode_sense_cpy
BUF_PTR_CA00:
         lda     #$00
         sta     BUF_PTR_L
         lda     #$ca
         sta     BUF_PTR_H  ;$FB,$FB point to $CA00
         rts

EXECUTE_MODE_SENSE:
         jsr     SCSI_CMD_1A ;MODE_SENSE
SEND_CMD_DIN_STATUS:
         jsr     CALL_00_DoPhases
         jsr     WAIT_DATA_IN
         bcs     IOERROR_NEAR
         jsr     READ_PIO
         jmp     CALL_FN_30 ;get STATUS ans MESSAGE

EXECUTE_MODE_SEL_SETBLK:
         jsr     FILL_SETBLK
SEND_CMD_DOUT_STATUS:
         jsr     CALL_00_DoPhases
         jsr     WAIT_FOR_DOUT
         bcs     IOERROR_NEAR
         jsr     WRITE_PIO
         jsr     CALL_FN_30 ;get status and message
         lda     RET_CODE
         bne     IOERROR_NEAR
         rts

IOERROR_NEAR:
         jmp     ERROR_IOERROR

FN_5A:   ldx     #$06       ;SP_MODE_SELECT
@cpy_loop:
         lda     MODE_SELECT_DATA,x ;FILL CDB with MODE SELECT command
         sta     SCSI_CMD_LEN,x
         dex
         bpl     @cpy_loop
         lda     #$8b
         jsr     CALL_FN_XA ;CALL_FN_8B - BUF_PTR=TMP_PTR[2]
         lda     CALL_TYPE
         and     #$40
         beq     @not_etx
         lda     IS_IIgs
         bne     @native_path
         ldy     #$07
         bne     @emulation_path

@not_etx:
         ldy     #$05
@emulation_path:
         lda     (MEM_PTR_L),y
@cdb_len_done:
         sta     SCSI_CDB_LEN
         jmp     SEND_CMD_DOUT_STATUS

@native_path:
         ldy     #$07
         lda     [MEM_PTR_L],y
         jmp     @cdb_len_done

MODE_SELECT_DATA:
         .byte   $06
         .byte   $15
         .byte   $00
         .byte   $00
         .byte   $00
         .byte   $14
         .byte   $00
MODE_SENSE_DATA:
         .byte   $06
         .byte   $1a
         .byte   $00
         .byte   $01
         .byte   $00
         .byte   $50
         .byte   $00

FN_2A:   ldy     #$00       ;EXECUTE TEST_UNIT_READY and handle tape device
         jsr     LDA_BUF_PTR_Y
         sta     TEMP_c915  ;store dev_status to TEMP_c915
         ldy     #$06
         sty     SCSI_CMD_LEN
         lda     #$00
@clear_cdb_loop:
         sta     SCSI_CDB_CMD,y ;clear SCSI CDB
         dey
         bpl     @clear_cdb_loop ;CMD TEST_UNIT_READY
         jsr     FN_3A      ;CALL_FN_AF - BUS_FREE
         jsr     CALL_FN_B0 ;Do Phases without BUS_FREE- both of the above can be replaced with FN_00
         lda     RET_CODE   ;EXECUTE CMD TEST_UNIT_READY
         beq     @cmd_ok    ;branch if TEST_UNIT_READY successfull
         lda     TEMP_c915
         and     #$ef
         sta     TEMP_c915  ;clear bit 4 (device offline) if TEST_UNIT_READY failed
         bne     FN_2A_end
@cmd_ok: lda     #$3e
         jsr     CALL_FN_XA ;CALL_FN_3E - Get status and message. Check device not busy
         lda     RET_CODE
         bne     CHECK_REQUEST_SENSE ;branch if status failed
TAPE_SENSE:
         ldy     #$17
         lda     (TMP_PTR0),y ;load device type from DIBTAB
         cmp     #$06       ;device type tape drive
         bne     FN_2A_end  ;branch if not tape
         jsr     SAVE_FA_FD
         jsr     EXECUTE_MODE_SENSE
         lda     RET_CODE
         bne     FN_2A_end
         ldy     #$02
         jsr     LDA_BUF_PTR_Y ;get sense key
         jsr     LOAD_FA_FD
         and     #$80       ;filemark mask
         bne     @set_write_protect ;branch if filemark==1
         lda     TEMP_c915
         and     #$fb       ;clear write protect bit
         bne     @store_dev_status ;branch always
@set_write_protect:
         lda     TEMP_c915
         ora     #$04
@store_dev_status:
         sta     TEMP_c915
FN_2A_end:
         jsr     ST_c915_BUF_PTR_Y
         lda     #$00
         sta     RET_CODE
         jmp     restore_y_return

CHECK_REQUEST_SENSE:
         jsr     SAVE_FA_FD
         jsr     SCSI_CMD_03 ;REQUEST_SENSE
         jsr     SEND_CMD_DIN_STATUS ;EXECUTE_CDB_CMD
         lda     RET_CODE
         bne     FN_2A_end  ;branch if sense ok
         ldy     #$0c
         jsr     LDA_BUF_PTR_Y ;get ASC
         jsr     LOAD_FA_FD
         cmp     #$b0       ;unknown vendor specific ASC
         bne     @LCF21     ;branch if ASC!=$b0
         lda     TEMP_c915
         and     #$ee       ;clear ONLINE and DISK_SWITCH flags
@LCF1C:  sta     TEMP_c915  ;set device offline
         bne     TAPE_SENSE
@LCF21:  cmp     #$28       ;UNIT ATTENTION - not-ready to ready transition (format complete) ???
         bne     FN_2A_end
         lda     TEMP_c915
         ora     #$11
         bne     @LCF1C     ;always branch

LDA_BUF_PTR_Y:
         lda     CALL_TYPE
         and     #$40
         beq     @LDA_BUF_PTR_std
         lda     IS_IIgs
         bne     @LDA_BUF_PTR_ext
@LDA_BUF_PTR_std:
         lda     (BUF_PTR_L),y
@LDA_BUF_PTR_end:
         rts

@LDA_BUF_PTR_ext:
         clc
         xce
         lda     [BUF_PTR_L],y
         sec
         xce
         bcc     @LDA_BUF_PTR_end

ST_c915_BUF_PTR_Y:
         ldy     #$00
         lda     CALL_TYPE
         and     #$40
         beq     @ST_BUF_PTR_std
         lda     IS_IIgs
         bne     @ST_BUF_PTR_ext
@ST_BUF_PTR_std:
         lda     TEMP_c915
         sta     (BUF_PTR_L),y
         rts

@ST_BUF_PTR_ext:
         lda     TEMP_c915
         clc
         xce
         sta     [BUF_PTR_L],y
         sec
         xce
         rts

SAVE_FA_FD:
         lda     BUF_PTR_L  ;save $fa..$fd to $c8ee and $c921
         sta     TEMP_16
         lda     BUF_PTR_H
         sta     TEMP_16+1
         lda     BUF_PTR_VH
         sta     TEMP_VH
         lda     BUF_PTR_XH
         sta     TEMP_XH
         rts

LOAD_FA_FD:
         pha                ;load $fa..$fd from $c8ee and $c921
         lda     TEMP_16
         sta     BUF_PTR_L
         lda     TEMP_16+1
         sta     BUF_PTR_H
         lda     TEMP_VH
         sta     BUF_PTR_VH
         lda     TEMP_XH
         sta     BUF_PTR_XH
         pla
         rts

SCSI_CMD_03:
         ldy     #$06       ;SCSI REQUEST_SENSE
@req_sense_copy_loop:
         lda     REQ_SENSE_DATA,y ;fill SCSI CDB from ROM data
         sta     SCSI_CMD_LEN,y
         dey
         bpl     @req_sense_copy_loop
         lda     #$00
         sta     BUF_PTR_VH
         jmp     BUF_PTR_CA00

REQ_SENSE_DATA:
         .byte   $06
         .byte   $03
         .byte   $00
         .byte   $00
         .byte   $00
         .byte   $0d
         .byte   $00

CALL_FN_60_RET:
         sta     RET_CODE   ;return fail
         lda     #$60
         jmp     CALL_FN_XA ;CALL_FN_60

FN_TABLE:
         .word   FN_0A
         .word   FN_1A
         .word   FN_2A
         .word   FN_3A
         .word   FN_4A
         .word   FN_5A
         .word   FN_6A
         .word   FN_7A
         .word   FN_8A
         .word   FN_2A
         .word   FN_AA
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea

BANKSWITCH:
         stx     BSW_TEMP
         tax
         lda     BSW_TEMP
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
         sta     JMP_PTR
         inx
         lda     FN_TABLE,x
         sta     JMP_PTR+1
         jsr     DO_CALL_FN
         pla
         and     #$0f
         sta     REG_IO_BANK_SEL,y
         clc
         rts

DO_CALL_FN:
         jmp     (JMP_PTR)

         .byte   $d7
         .byte   $00
         .byte   $00
         .byte   $00
