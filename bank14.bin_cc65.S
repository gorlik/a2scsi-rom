; Target assembler: cc65 v2.18.0 [--target none -C bank14.bin_cc65.cfg]
; 6502bench SourceGen v1.8.3
         .setcpu "65816"
P8E_IO_ERR =     $27        ;I/O error

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
INIT_FLAG =      $c809      ; card initialized flag (init=$77)
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
SCSI_CDB10_7 =   $c815
SCSI_CDB10_8 =   $c816
SCSI_CDB10_9 =   $c817
SLOT_OFFSET =    $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
CMD_STATUS =     $c81e      ; SCSI CMD status - 0x00 OK, 0x02 Check condition
UNK_c820 =       $c820      ; 0xff if PIO ?
UNK_c8cc =       $c8cc      ;unknown
NUM_PART =       $c8ce      ; number of partition on the device - only used in bank 07
PARTMAP_OK =     $c8cf      ; $00 if failed to read Partition Map. non-zero if PM detected
IS_IIgs  =       $c8f3      ;0x01 if IIgs
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB

         .org    $cc00
         .a8
         .i8
FN_0E:   ldy     #$30
         ldx     #$00
@cmp_loop:
         lda     (BUF_PTR_L),y
         cmp     str_apple_PRODO,x
         beq     @match1
         cmp     str_APPLE_prodos,x
         bne     @match_fail
@match1: iny
         inx
         cpx     #$09
         bne     @cmp_loop
         lda     #$ff
         bne     FN_0E_end

@match_fail:
         lda     #$00
FN_0E_end:
         sta     PARTMAP_OK
         ldy     SLOT_OFFSET
         rts

str_apple_PRODO:
         .byte   "apple PRODO"
str_APPLE_prodos:
         .byte   "APPLE_prodos"

FN_1E:   lda     CALL_TYPE  ;Handle SP control $20-$2A
         and     #$40
         beq     @FN_1E_std_call
         lda     IS_IIgs
         bne     @FN_1E_IIgs
         ldy     #$06
         bne     @load_control_code

@FN_1E_std_call:
         ldy     #$04
@load_control_code:
         lda     (TMP_PTR_L),y
@done_loading:
         sec
         sbc     #$20       ;subtract $20 from control code
         tax
         lda     SP_FN_TABLE_L,x
         sta     TMP_PTR1
         lda     SP_FN_TABLE_H,x
         sta     TMP_PTR1+1
         jmp     (TMP_PTR1)

@FN_1E_IIgs:
         ldy     #$06
         lda     [TMP_PTR_L],y
         jmp     @done_loading

SP_FN_TABLE_L:
         .byte   <SP_AUDIO_SEARCH
         .byte   <SP_AUDIO_PLAY
         .byte   <SP_AUDIO_PAUSE
         .byte   <SP_UNKNOWN
         .byte   <SP_AUDIO_STATUS
         .byte   <SP_AUDIO_SCAN
         .byte   <FN_2E     ;$26 - Eject
         .byte   <SP_READ_TOC
         .byte   <SP_READ_Q_SUBCODE
         .byte   <SP_READ_HEADER
         .byte   <SP_SET_INTERLEAVE
SP_FN_TABLE_H:
         .byte   >SP_AUDIO_SEARCH
         .byte   >SP_AUDIO_PLAY
         .byte   >SP_AUDIO_PAUSE
         .byte   >SP_UNKNOWN
         .byte   >SP_AUDIO_STATUS
         .byte   >SP_AUDIO_SCAN
         .byte   >FN_2E
         .byte   >SP_READ_TOC
         .byte   >SP_READ_Q_SUBCODE
         .byte   >SP_READ_HEADER
         .byte   >SP_SET_INTERLEAVE

SP_AUDIO_SEARCH:
         jsr     CHECK_VALID
         jsr     LCDB6
EXECUTE_COMMAND:
         jsr     CALL_FN_00 ;DoPhases
         jsr     WAIT_FOR_STATUS
         jsr     CALL_FN_30 ;get STATUS and MESSAGE
         lda     RET_CODE
         beq     @rts
         lda     #P8E_IO_ERR
         jmp     CALL_FN_60_RETY

@rts:    rts

CHECK_VALID:
         lda     DEV_STATUS
         cmp     #$b4
         bne     ERROR_BADCTL
         rts

ERROR_BADCTL:
         lda     #$21
CALL_FN_60_RETY:
         ldy     SLOT_OFFSET
         jmp     CALL_FN_60_RET

SP_AUDIO_PLAY:
         jsr     CHECK_VALID
         jsr     LCDC2
         jmp     EXECUTE_COMMAND

SP_AUDIO_PAUSE:
         jsr     CHECK_VALID
         jsr     LCDCD
         jmp     EXECUTE_COMMAND

SP_UNKNOWN:
         jsr     CHECK_VALID
         jsr     LCDEE
         jmp     EXECUTE_COMMAND

SP_AUDIO_STATUS:
         jsr     CHECK_VALID
         jsr     LCE01
         jsr     CALL_FN_00
         jsr     LCD4A
         jmp     LCD26

SP_AUDIO_SCAN:
         jsr     CHECK_VALID
         jsr     LCE11
         jmp     EXECUTE_COMMAND

FN_2E:   jsr     CHECK_VALID
         jsr     LCE1C
         jmp     EXECUTE_COMMAND

SP_READ_TOC:
         jsr     CHECK_VALID
         jsr     LCE2A
         jsr     CALL_FN_00
         jsr     LCD4A
         jmp     LCD26

SP_READ_Q_SUBCODE:
         jsr     CHECK_VALID
         jsr     LCE68
         jsr     CALL_FN_00
         jsr     LCD4A
         jmp     LCD26

SP_READ_HEADER:
         jsr     CHECK_VALID
         jsr     LCE78
         jsr     CALL_FN_00
         jsr     LCD4A
         jmp     LCD26

SP_SET_INTERLEAVE:
         ldy     #$02
         lda     (TMP_PTR_L),y
         sta     UNK_c8cc
         lda     #$d3
         jmp     CALL_FN_XE ;CALL_FN_D3

CALL_FN_00:
         lda     #$00
CALL_FN_XE:
         ldx     #$0e
         ldy     SLOT_OFFSET
         jsr     BANKSWITCH
         rts

LCD26:   ldy     SLOT_OFFSET
         lda     #$ff
         sta     UNK_c820
         lda     XFER_MODE
         sta     TMP_c80a
         lda     #$03
         sta     XFER_MODE
         lda     #$40
         jsr     CALL_FN_XE ;CALL_FN_40
         lda     TMP_c80a
         sta     XFER_MODE
         rts

CALL_FN_30:
         lda     #$30
         jmp     CALL_FN_XE ;CALL_FN_30

LCD4A:   jsr     SET_TIMEOUT_03
@LCD4D:  lda     REG_5380_STAT,y
         and     #$3c
         cmp     #$24
         beq     @LCD61
         cmp     #$2c
         beq     ERROR_IOERROR
         jsr     DEC_TIMEOUT3
         bcs     ERROR_IOERROR
         bcc     @LCD4D

@LCD61:  rts

WAIT_FOR_STATUS:
         jsr     SET_TIMEOUT_03
@status_loop:
         lda     REG_5380_STAT,y
         and     #$1c       ;MSG CD IO mask
         cmp     #$0c       ;status phase
         beq     @rts
         jsr     DEC_TIMEOUT3
         bcs     ERROR_IOERROR
         bcc     @status_loop

@rts:    rts

ERROR_IOERROR:
         lda     #$27
         ldy     SLOT_OFFSET
         jmp     CALL_FN_60_RET

SET_TIMEOUT_03:
         lda     #$ff
         sta     TCOUNT_B0
         sta     TCOUNT_B2
         lda     #$03
         sta     TCOUNT_B1
         rts

DEC_TIMEOUT3:
         dec     TCOUNT_B0
         bne     @no_timeout
         dec     TCOUNT_B2
         bne     @no_timeout
         dec     TCOUNT_B1
         beq     @timeout
@no_timeout:
         clc
         rts

@timeout:
         sec
         rts

         .byte   $a9
         .byte   $06
         .byte   $8d
         .byte   $0d
         .byte   $c8
         .byte   $f0
         .byte   $05

CLR_CDB_CMD10:
         lda     #$0a
         sta     SCSI_CMD_LEN
         ldx     #$0a
         lda     #$00
@clr_cdb_loop:
         sta     SCSI_CDB_CMD,x
         dex
         bne     @clr_cdb_loop
         rts

LCDB6:   jsr     CLR_CDB_CMD10
         lda     #$c8
         sta     SCSI_CDB_CMD
         jsr     LCE8E
         rts

LCDC2:   jsr     CLR_CDB_CMD10
         lda     #$c9
         sta     SCSI_CDB_CMD
         jmp     LCE8E

LCDCD:   jsr     CLR_CDB_CMD10
         lda     #$ca
         sta     SCSI_CDB_CMD
         jsr     LCF4A
         ldy     #$00
         jsr     LCEEF
         bcc     @LCDE4
         jsr     LCEFF
         bcc     @LCDE6
@LCDE4:  lda     (BUF_PTR_L),y
@LCDE6:  bne     @LCDED
         lda     #$10
         sta     SCSI_CDB_LUN
@LCDED:  rts

LCDEE:   jsr     CLR_CDB_CMD10
         lda     #$cb
         sta     SCSI_CDB_CMD
         jsr     LCF4A
         ldy     #$ff
         jsr     LCEDC
         jmp     LCEC5

LCE01:   jsr     CLR_CDB_CMD10
         lda     #$cc
         sta     SCSI_CDB_CMD
         lda     #$ff
         sta     SCSI_CDB10_8
         jmp     LCF4A

LCE11:   jsr     CLR_CDB_CMD10
         lda     #$cd
         sta     SCSI_CDB_CMD
         jmp     LCE8E

LCE1C:   jsr     CLR_CDB_CMD10
         lda     #$c0
         sta     SCSI_CDB_CMD
         lda     #$01
         sta     SCSI_CDB_LUN
         rts

LCE2A:   jsr     CLR_CDB_CMD10
         lda     #$c1
         sta     SCSI_CDB_CMD
         jsr     LCF4A
         ldy     #$00
         jsr     LCEEF
         bcs     @LCE50
         lda     (BUF_PTR_L),y
         sta     SCSI_CDB_CTRL
         iny
         lda     (BUF_PTR_L),y
         sta     SCSI_CDB10_8
         iny
         lda     (BUF_PTR_L),y
         sta     SCSI_CDB10_7
         jmp     LCEC5

@LCE50:  clc
         xce
         lda     [BUF_PTR_L],y
         sta     SCSI_CDB_CTRL
         iny
         lda     [BUF_PTR_L],y
         sta     SCSI_CDB10_8
         iny
         lda     [BUF_PTR_L],y
         sta     SCSI_CDB10_7
         sec
         xce
         jmp     LCEC5

LCE68:   jsr     CLR_CDB_CMD10
         lda     #$c2
         sta     SCSI_CDB_CMD
         lda     #$ff
         sta     SCSI_CDB10_8
         jmp     LCF4A

LCE78:   jsr     CLR_CDB_CMD10
         lda     #$c3
         sta     SCSI_CDB_CMD
         jsr     LCF4A
         ldy     #$ff
         jsr     LCEDC
         lda     #$ff
         sta     SCSI_CDB10_8
         rts

LCE8E:   jsr     LCF4A
         ldy     #$00
         jsr     LCEEF
         bcc     @LCE9D
         jsr     LCEFF
         bcc     @LCE9F
@LCE9D:  lda     (BUF_PTR_L),y
@LCE9F:  beq     @LCEB2
         iny
         jsr     LCEEF
         bcc     @LCEAC
         jsr     LCEFF
         bcc     @LCEAE
@LCEAC:  lda     (BUF_PTR_L),y
@LCEAE:  ora     #$10
         bne     @LCEBF

@LCEB2:  iny
         jsr     LCEEF
         bcc     @LCEBD
         jsr     LCEFF
         bcc     @LCEBF
@LCEBD:  lda     (BUF_PTR_L),y
@LCEBF:  sta     SCSI_CDB_LUN
         jsr     LCEDC
LCEC5:   iny
         jsr     LCEEF
         bcc     @LCED0
         jsr     LCEFF
         bcc     @LCED2
@LCED0:  lda     (BUF_PTR_L),y
@LCED2:  ldy     #$05
@LCED4:  asl     A
         dey
         bpl     @LCED4
         sta     SCSI_CDB10_9
         rts

LCEDC:   iny
         lda     CALL_TYPE
         and     #$40
         beq     @LCEE9
         lda     IS_IIgs
         bne     @LCEEC
@LCEE9:  jmp     LCF14

@LCEEC:  jmp     LCF30

LCEEF:   lda     CALL_TYPE
         and     #$40
         beq     @LCEFB
         lda     IS_IIgs
         bne     @LCEFD
@LCEFB:  clc
         rts

@LCEFD:  sec
         rts

LCEFF:   clc
         xce
         lda     [BUF_PTR_L],y
         sec
         xce
         rts

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

LCF14:   lda     (BUF_PTR_L),y
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

         .byte   $a0
         .byte   $00
         .byte   $18
         .byte   $fb

LCF30:   lda     [BUF_PTR_L],y
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

LCF4A:   lda     CALL_TYPE
         and     #$40
         beq     @LCF56
         lda     IS_IIgs
         bne     @LCF65
@LCF56:  ldy     #$02
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_L
         iny
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_H
@LCF61:  ldy     SLOT_OFFSET
         rts

@LCF65:  clc
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
         jmp     @LCF61

FN_3E:   jsr     CALL_FN_30 ;Get Status and Message
         lda     CMD_STATUS
         cmp     #$08       ;SCSI_STATUS_BUSY
         bne     @FN3_end   ;branch if status not busy
         lda     #$76
         sta     INIT_FLAG  ;bug???
         sta     NUM_PART-1
         sta     $c8d6
@busy_loop:
         lda     #$a3       ;Keep trying until not busy
         jsr     CALL_FN_XE ;CALL_FN_A3 - send CMD_TEST_UNIT_READY
         lda     CMD_STATUS
         cmp     #$08
         bne     @not_busy
         dec     $c8d6
         bne     @busy_loop
         dec     NUM_PART-1
         bne     @busy_loop
@not_busy:
         lda     #$77
         sta     INIT_FLAG
@FN3_end:
         lda     CMD_STATUS
         sta     RET_CODE
         rts

CALL_FN_60_RET:
         sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH

FN_TABLE:
         .word   FN_0E
         .word   FN_1E
         .word   FN_2E
         .word   FN_3E
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
