; Target assembler: cc65 v2.18.0 [--target none -C bank03.bin_cc65.cfg]
; 6502bench SourceGen v1.7.3
         .setcpu "65816"
SCSI_CMD_TEST_UNIT_READY = $00
SCSI_CMD_REQUEST_SENSE = $03
SCSI_CMD_FORMAT_UNIT = $04
SCSI_CMD_REASSIGN_BLOCKS = $07
SCSI_CMD_INQUIRY = $12
SCSI_CMD_RESERVE = $16
SCSI_CMD_RELEASE = $17
SCSI_CMD_MODE_SENSE6 = $1a
SCSI_CMD_SEND_DIAG = $1d
SCSI_CMD_READ_CAPACITY = $25
P8E_IO_ERR =     $27        ;I/O error
P8E_WRITE_PROT = $2b        ;Disk write protected
SCSI_CMD_READ_DEFECT_DATA = $37

TMP_PTR0 =       $19        ; temporary ZP pointer 
TMP_PTR1 =       $1b        ; temporary ZP pointer 
PD_PAR_BLK_LO =  $46        ;PRODOS input parameter Block lo
PD_PAR_BLK_HI =  $47        ;PRODOS input parameter Block hi
TMP_PTR_L =      $f6        ; temporary ZP long pointer
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
BUF_PTR_XH =     $fd
REG_5380_ICMD =  $c001      ; RW Initiator command register
REG_5380_STAT =  $c004      ; R SCSI status
REG_IO_BANK_SEL = $c00a     ; W memory bank select
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B2 =      $c802      ; timeout counter MSB
XFER_MODE =      $c804      ; 0x00 IIe PDMA, 0x01 IIgs PDMA, 0x02-0xff PIO 
INIT_FLAG =      $c809      ; card initialized flag (init=$77)
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SCSI_CMD_LEN =   $c80d      ; SCSI COMMAND lenght
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SCSI_CDB_LUN =   $c80f      ; 
SCSI_CDB_LBA_HI = $c810
SCSI_CDB_LEN =   $c812
SCSI_CDB10_8 =   $c816
SAVE_Y   =       $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
CMD_STATUS =     $c81e      ; SCSI CMD status - 0x00 OK, 0x02 Check condition
UNK_c820 =       $c820      ; 0xff if PIO ?
SDAT_BASE =      $c831      ;start of SDAT table (extends to $C8A7)
UNK_c8cc =       $c8cc      ;unknown
SAVE_SP_UNIT =   $c8e8      ; saved Smartport UNIT number
TEMP_HI  =       $c8ee      ;generic 16-bit temp high byte
TEMP_LO  =       $c8ef      ;generic 16-bit temp low byte
IIgs_PDMA =      $c8f3      ;0x01 if IIgs PDMA
buf_c8f5 =       $c8f5      ; seems to be some sort of 12 byte structure ???
SAVE_XFER_MODE = $c91f
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB
TIMEOUT  =       $c9f6      ; each unit is 1.25s

         .org    $cc00
         .a8
         .i8
LOAD_CDB_TEST_UNIT_READY:
         jsr     ZERO_CMD_BUF6 ;TEST_UNIT_READY
         lda     #SCSI_CMD_TEST_UNIT_READY
         sta     SCSI_CDB_CMD
         rts

LOAD_CDB_REQUEST_SENSE:
         jsr     ZERO_CMD_BUF6 ;REQUEST_SENSE
         lda     #SCSI_CMD_REQUEST_SENSE
         sta     SCSI_CDB_CMD
         lda     #$1c
         sta     SCSI_CDB_LEN
         jmp     COPY_BUF_PTR

LOAD_CDB_INQUIRY:
         jsr     ZERO_CMD_BUF6 ;INQUIRY
         lda     #SCSI_CMD_INQUIRY
         sta     SCSI_CDB_CMD
         lda     #$91
         sta     SCSI_CDB_LEN
         jmp     COPY_BUF_PTR

LOAD_CDB_FORMAT:
         jsr     ZERO_CMD_BUF6 ;FORMAT_UNIT
         lda     #SCSI_CMD_FORMAT_UNIT
         sta     SCSI_CDB_CMD
         lda     UNK_c8cc
         sta     SCSI_CDB_LEN
         rts

LOAD_CDB_READ_CAPACITY:
         ldx     #$09       ;READ_CAPACITY
         lda     #$0a
         sta     SCSI_CMD_LEN
         lda     #$00
@clr_loop_25:
         sta     SCSI_CDB_CMD,x
         dex
         bne     @clr_loop_25
         lda     #SCSI_CMD_READ_CAPACITY
         sta     SCSI_CDB_CMD
         jmp     COPY_BUF_PTR

FN_A3:   jsr     LOAD_CDB_TEST_UNIT_READY ;TEST_UNIT_READY
         jsr     SCSI_CMD_SEND_NO_DATA
         lda     INIT_FLAG
         cmp     #$77
         bne     @FN_A3_end
         lda     RET_CODE
         beq     @FN_A3_end
         lda     #$39
         jsr     CALL_FN_X3 ;CALL_FN_39
         lda     #P8E_IO_ERR
         jmp     CALL_FN_60_RET ;return fail

@FN_A3_end:
         rts

FN_D3:   jsr     WRITE_PROT_CHECK
         jsr     LOAD_CDB_FORMAT ;FORMAT_UNIT
         jsr     CALL_00_Do_Phases ;Do_Phases
@LCC75:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$0c
         bne     @LCC75
         jsr     CALL_FN_30
         lda     CMD_STATUS
         beq     LCCAF
         jmp     ERROR_IOERROR

FN_B3:   jsr     LOAD_CDB_REQUEST_SENSE ;REQUEST_SENSE
         jsr     CALL_00_Do_Phases
         jmp     LCDE3

FN_93:   jsr     LOAD_CDB_INQUIRY
         jsr     CALL_00_Do_Phases
         lda     PD_PAR_BLK_LO
         sta     TEMP_HI
         lda     PD_PAR_BLK_HI
         sta     TEMP_LO
         jsr     LCDCE
         lda     TEMP_HI
         sta     PD_PAR_BLK_LO
         lda     TEMP_LO
         sta     PD_PAR_BLK_HI
LCCAF:   rts

FN_C3:   jsr     LOAD_CDB_READ_CAPACITY
         jsr     CALL_00_Do_Phases
         lda     BUF_PTR_L
         sta     TEMP_HI
         lda     BUF_PTR_H
         sta     TEMP_LO
         jsr     LCDCE
         lda     TEMP_HI
         sta     BUF_PTR_L
         lda     TEMP_LO
         sta     BUF_PTR_H
         lda     RET_CODE
         beq     RET_SY
         lda     INIT_FLAG
         cmp     #$77
         bne     RET_SY     ;branch if not init
ERROR_IOERROR:
         lda     #P8E_IO_ERR
         jmp     CALL_FN_60_RET

RET_SY:  ldy     SAVE_Y
         rts

LOAD_CDB_RESERVE:
         jsr     ZERO_CMD_BUF6 ;RESERVE
         lda     #SCSI_CMD_RESERVE
         sta     SCSI_CDB_CMD
         lda     #$01
         sta     SCSI_CDB_LEN
         rts

LOAD_CDB_RELEASE:
         jsr     ZERO_CMD_BUF6 ;RELEASE
         lda     #SCSI_CMD_RELEASE
         sta     SCSI_CDB_CMD
         lda     #$1c
         sta     SCSI_CDB_LEN
         jmp     COPY_BUF_PTR

LOAD_CDB_READ_DEFECT:
         ldx     #$0a       ;READ_DEFECT_DATA
         stx     SCSI_CMD_LEN ;clear 10-bytes command
         lda     #$00
@clr_loop_37:
         sta     SCSI_CDB_CMD,x
         dex
         bne     @clr_loop_37
         lda     #SCSI_CMD_READ_DEFECT_DATA
         sta     SCSI_CDB_CMD
         lda     #$fc
         sta     SCSI_CDB10_8 ;CDB10 CMD LEN
         lda     #$1d
         sta     SCSI_CDB_LBA_HI ;DEFECT LIST FORMAT
         jmp     COPY_BUF_PTR

LOAD_CDB_SEND_DIAG:
         jsr     ZERO_CMD_BUF6 ;SEND_DIAGNOSTIC
         lda     #SCSI_CMD_SEND_DIAG
         sta     SCSI_CDB_CMD
         lda     #$04       ;SELF TEST
         sta     SCSI_CDB_LUN
         jmp     COPY_BUF_PTR

LOAD_CDB_MODE_SENSE6:
         jsr     ZERO_CMD_BUF6 ;MODE_SENSE
         lda     #SCSI_CMD_MODE_SENSE6
         sta     SCSI_CDB_CMD
         lda     CALL_TYPE  ;ugly code below. need to set y=7 if extended call
         and     #$40
         beq     @LCD45     ;branch if not extended call
         lda     CALL_TYPE
         cmp     #$01       ;if EXT_FLAG==$01 should be a PRODOS call
         bne     @LCD57     ;branch if not PRODOS
@LCD45:  ldy     #$05
@LCD47:  lda     (TMP_PTR_L),y
         jmp     @LCD50

         .byte   $a0
         .byte   $07
         .byte   $b7
         .byte   $f6

@LCD50:  sta     SCSI_CDB_LEN
         jsr     COPY_BUF_PTR
         rts

@LCD57:  ldy     #$07
         bne     @LCD47

LOAD_CDB_REASSIGN_BLOCKS:
         jsr     ZERO_CMD_BUF6 ;REASSIGN_BLOCKS
         lda     #SCSI_CMD_REASSIGN_BLOCKS
         sta     SCSI_CDB_CMD
         jmp     COPY_BUF_PTR

ZERO_CMD_BUF6:
         ldx     #$06
         stx     SCSI_CMD_LEN
         lda     #$00
@LCD6D:  sta     SCSI_CDB_CMD,x
         dex
         bne     @LCD6D
         rts

COPY_BUF_PTR:
         lda     CALL_TYPE
         and     #$40
         beq     @std_call
         lda     IIgs_PDMA
         bne     @copy_long_buf_ptr
@std_call:
         ldy     #$02
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_L
         iny
         lda     (TMP_PTR_L),y
         sta     BUF_PTR_H
@copy_buf_ptr_done:
         ldy     SAVE_Y
         rts

@copy_long_buf_ptr:
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
         jmp     @copy_buf_ptr_done

         .byte   $a9
         .byte   $74

CALL_FN_X3:
         ldy     SAVE_Y
         ldx     #$03
         jsr     BANKSWITCH ;CALL_FN_X3
         rts

SCSI_CMD_SEND_NO_DATA:
         lda     #$00
         jsr     CALL_FN_X3 ;CALL_FN_00 (DoPhases)
CALL_FN_30:
         lda     #$30
         jmp     CALL_FN_X3 ;CALL_FN_30 (Get Status and Message)

CALL_00_Do_Phases:
         lda     #$00
         jmp     CALL_FN_X3 ;CALL_FN_00 (DoPhases)

         .byte   $a9        ;unreachable code
         .byte   $00
         .byte   $20
         .byte   $a9
         .byte   $cd
         .byte   $20
         .byte   $ce
         .byte   $cd
         .byte   $a9
         .byte   $30
         .byte   $4c
         .byte   $a9
         .byte   $cd

LCDCE:   lda     TIMEOUT
         sta     TCOUNT_B2
         jsr     SET_PIO_MODE
         lda     #$40
         jsr     CALL_FN_X3 ;CALL_FN_40
         lda     SAVE_XFER_MODE
         sta     XFER_MODE
         rts

LCDE3:   jsr     SET_PIO_MODE
         jsr     WAIT_FOR_COMMAND_PHASE
         lda     #$01
         jsr     CALL_FN_X3 ;CALL_FN_01
         lda     SAVE_XFER_MODE
         sta     XFER_MODE
         jmp     CALL_FN_30 ;Get Status and Message

LCDF7:   jsr     SET_PIO_MODE
         lda     #$50
         jsr     CALL_FN_X3 ;CALL_FN_50
         lda     SAVE_XFER_MODE
         sta     XFER_MODE
         rts

SET_PIO_MODE:
         ldy     SAVE_Y
         lda     #$ff
         sta     UNK_c820
         lda     XFER_MODE
         sta     SAVE_XFER_MODE
         lda     #$03
         sta     XFER_MODE  ;set PIO mode
         rts

         .byte   $20        ;unreachable code
         .byte   $34
         .byte   $ce
         .byte   $a9
         .byte   $40
         .byte   $20
         .byte   $a9
         .byte   $cd
         .byte   $4c
         .byte   $2d
         .byte   $ce
         .byte   $20
         .byte   $34
         .byte   $ce
         .byte   $a9
         .byte   $50
         .byte   $20
         .byte   $a9,$cd,$ad,$e7,$c8,$8d
         .byte   $04
         .byte   $c8
         .byte   $60
         .byte   $ad
         .byte   $04
         .byte   $c8,$8d,$e7,$c8,$a9
         .byte   $02
         .byte   $8d
         .byte   $04
         .byte   $c8
         .byte   $ac
         .byte   $1a
         .byte   $c8
         .byte   $60

WRITE_PROT_CHECK:
         lda     DEV_STATUS
         and     #$04       ;medium write protect bit
         beq     @not_wp    ;branch if media is not write protected
         lda     #P8E_WRITE_PROT
         jmp     CALL_FN_60_RET

@not_wp: rts

FN_03_DoStatus:
         jsr     WRITE_PROT_CHECK
         jsr     LOAD_CDB_REASSIGN_BLOCKS ;REASSIGN_BLOCKS
         jsr     CALL_00_Do_Phases
         jsr     LCE67
         bcs     ret_27
         jmp     LCDF7

ret_27:  lda     #$27
         sta     RET_CODE
         rts

LCE67:   ldx     #$03
@LCE69:  lda     REG_5380_STAT,y
         and     #$1c
         beq     @LCE78
         jsr     DELAY_10000
         dex
         bne     @LCE69
         sec
         rts

@LCE78:  clc
         rts

DELAY_10000:
         ldy     #$00
         sty     TCOUNT_B0
@delay_loop:
         dey
         bne     @delay_loop
         dec     TCOUNT_B0
         lda     TCOUNT_B0
         bne     @delay_loop
         ldy     SAVE_Y
         rts

WAIT_FOR_COMMAND_PHASE:
         ldx     #$02
@cmd_pahse_loop:
         lda     REG_5380_STAT,y
         and     #$1c       ;MSG_CD_IO mask
         cmp     #$04       ;Command phase
         beq     @cmd_phase_found ;branch if Command Phase
         jsr     DELAY_10000
         dex
         bne     @cmd_pahse_loop
         sec
         rts

@cmd_phase_found:
         clc
         rts

FN_13:   rts

FN_23:   jsr     LOAD_CDB_MODE_SENSE6 ;MODE_SENSE
         jsr     CALL_00_Do_Phases
         lda     SCSI_CDB_LEN
         beq     JMP_FN_30  ;branch if CMD lenght is 0 (nothing to transfer)
         jsr     LCDCE
         rts

JMP_FN_30:
         jmp     CALL_FN_30 ;GET STATUS_AND_MESSAGE

FN_33:   jsr     LOAD_CDB_RESERVE
         jmp     SCSI_CMD_SEND_NO_DATA

FN_43:   jsr     LOAD_CDB_RELEASE
         jmp     SCSI_CMD_SEND_NO_DATA

FN_53:   jsr     LOAD_CDB_READ_DEFECT
         jsr     CALL_00_Do_Phases
@LCEC8:  lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$04
         beq     @LCED7
         cmp     #$0c
         beq     @LCEDA
         bne     @LCEC8

@LCED7:  jmp     LCDCE

@LCEDA:  jsr     CALL_FN_30
         lda     RET_CODE
         bne     ERROR_IOERROR_DUP
         rts

ERROR_IOERROR_DUP:
         lda     #$27
         ldy     SAVE_Y
         jmp     CALL_FN_60_RET

FN_63:   jsr     LOAD_CDB_SEND_DIAG
         jsr     CALL_00_Do_Phases
         ldx     #$03
         lda     #$30
         jsr     BANKSWITCH ;CALL_FN_30
         lda     CMD_STATUS
         bne     RET_27_LOCAL
         rts

RET_27_LOCAL:
         jmp     ret_27

FN_E3:   lda     SAVE_SP_UNIT
         beq     @LCF0E     ;branch if unit number is invalid
         lda     #$80
         sta     REG_5380_ICMD,y
         jmp     FN_A3      ;send CMD TEST_UNIT_READY

@LCF0E:  lda     #$11       ;invalid unit number
         jmp     CALL_FN_60_RET ;return fail

FN_F3:   jsr     ZERO_CMD_BUF6 ;Send REQUEST SENSE command
         lda     #SCSI_CMD_REQUEST_SENSE
         sta     SCSI_CDB_CMD
         lda     #$1c
         sta     SCSI_CDB_LEN
         jsr     CALL_00_Do_Phases ;Do_Phases
         jsr     LCDCE
         rts

         .byte   $18        ;seems unreachable code
         .byte   $fb
         .byte   $60
         .byte   $38
         .byte   $fb
         .byte   $60
         .byte   $a9
         .byte   $80
         .byte   $8d
         .byte   $36
         .byte   $c0
         .byte   $60
         .byte   $a9
         .byte   $0f
         .byte   $8d
         .byte   $36
         .byte   $c0
         .byte   $60

FN_73:   ldx     #$00       ;SAVE_TIMEOUT_AND CLEAR SDAT
         lda     #$c8
         sta     TMP_PTR0+1
         lda     #$31
         sta     TMP_PTR0   ;TMP_PTR0=$c831 (SDAT_BASE)
@next_sdat:
         ldy     #$0e       ;device timeout offset
         lda     (TMP_PTR0),y ;load device timeout from SDAT entry
         sta     buf_c8f5,x ;store sequentially at buf_c8f5
         inx
         lda     TMP_PTR0
         clc
         adc     #$11
         sta     TMP_PTR0   ;next SDAT
         ldy     #$00
         lda     (TMP_PTR0),y
         cmp     #$86
         beq     @next_sdat ;branch if sdat valid - could be a bug check SDAT INIT
         lda     #$ff
         sta     buf_c8f5,x ;end the buffer with $ff
         lda     #$00
         ldx     #$76
@sdat_clr_loop:
         sta     SDAT_BASE,x ;clear all SDAT table (???)
         dex
         bpl     @sdat_clr_loop
RET_LOAD_Y:
         ldy     SAVE_Y
         rts

FN_83:   ldx     #$00       ;restore TIMEOUT
         lda     #$c8
         sta     TMP_PTR0+1
         lda     #$31
         sta     TMP_PTR0   ;TMP_PTR0=$c831 (SDAT_BASE)
@LCF77:  ldy     #$0e       ;device timeout offset
         lda     buf_c8f5,x
         sta     (TMP_PTR0),y
         inx
         lda     TMP_PTR0
         clc
         adc     #$11
         sta     TMP_PTR0
         lda     buf_c8f5,x
         cmp     #$ff
         bne     @LCF77
         beq     RET_LOAD_Y

         .byte   "JEFF ZIASEVA HENIN"

CALL_FN_60_RET:
         sta     RET_CODE   ;return fail
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH ;CALL_FN_60

FN_TABLE:
         .word   FN_03_DoStatus
         .word   FN_13
         .word   FN_23
         .word   FN_33
         .word   FN_43
         .word   FN_53
         .word   FN_63
         .word   FN_73
         .word   FN_83
         .word   FN_93
         .word   FN_A3
         .word   FN_B3
         .word   FN_C3
         .word   FN_D3
         .word   FN_E3
         .word   FN_F3
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
         rts                ;bug? all other banks have a clc before rts

DO_CALL_FN:
         jmp     (TMP_PTR1)

         .byte   $00        ;bug? this is unique to this bank
         .byte   $02
         .byte   $31
         .byte   $34
         .byte   $30
