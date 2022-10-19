; Target assembler: cc65 v2.18.0 [--target none -C bank04.bin_cc65.cfg]
; 6502bench SourceGen v1.7.3
         .setcpu "65816"
SDAT_ENTRY_SIZE = $11

TMP_PTR0 =       $19        ; temporary ZP pointer 
TMP_PTR1 =       $1b        ; temporary ZP pointer 
PD_PAR_CMD =     $42        ;PRODOS input parameter COMMAND number
PD_PAR_BUF_LO =  $44        ;PRODOS input parameter Buffer lo address
PD_PAR_BUF_HI =  $45        ;PRODOS input parameter Buffer hi address
PD_PAR_BLK_LO =  $46        ;PRODOS input parameter Block lo
PD_PAR_BLK_HI =  $47        ;PRODOS input parameter Block hi
TMP_PTR_L =      $f6        ; temporary ZP long pointer
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
BUF_PTR_XH =     $fd
REG_5380_DATA =  $c000      ; R current SCSI data lines status
REG_5380_DATA_OUT = $c000   ; W SCSI data output register
REG_5380_ICMD =  $c001      ; RW Initiator command register
REG_5380_MODE_SEL = $c002   ; RW Mode select register
REG_5380_TCMD =  $c003      ; RW target command register
REG_5380_STAT =  $c004      ; R SCSI status
REG_5380_STAT2 = $c005      ; R Bus and status register
REG_IO_PDMA_DACK = $c008    ; RW PDMA/DACK
REG_IO_BANK_SEL = $c00a     ; W memory bank select
REG_IO_5380_RST = $c00b     ; W 5380 Reset
REG_IO_DRQ =     $c00e      ; R read DRQ on bit7
CYAREG   =       $c036      ;RW Configure Your Apple
DEV_IDX  =       $c800      ; index into the SDAT/DIBTAB tables
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
SAVE_CYAREG =    $c808      ; saved value of CYAREG
TMP_c80a =       $c80a      ; unknown
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SCSI_CMD_LEN =   $c80d      ; SCSI COMMAND lenght
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SCSI_CDB_LBA_HI = $c810
SCSI_CDB_LBA_LO = $c811
SCSI_CDB_LEN =   $c812
SCSI_CDB_CTRL =  $c813
SCSI_CDB10_8 =   $c816
SLOT_OFFSET =    $c81a      ; slot adress (n+8)<<4 
SAVE_SP_CMD =    $c81b      ; saved SmartPort Command
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
SCSI_RD_c81f =   $c81f      ; SCSI STATUS or MESSAGE return from FN_04 
NUM_DEVICES =    $c823      ; number of devices (used in bank2)
PART_START =     $c824      ; partition start (3 bytes) seems to be in reverse endian (?)
SDAT     =       $c831      ;start of SDAT table (extends to $C8A7)
SAVE_ZP_F6 =     $c8a8      ;saved zero page locations $f6-$fd
SAVE_ZP_15 =     $c8b0      ;saved zero page locations $15-$1e
PD_PAR_CMD_CPY = $c8bc      ;PRODOS input parameter COMMAND number
RX_LEN_LO =      $c8e4      ; bytes read if call successfull
RX_LEN_HI =      $c8e5      ; bytes read if call successfull
SAVE_SP_UNIT =   $c8e8      ; saved Smartport UNIT number
IS_IIgs  =       $c8f3      ;0x01 if IIgs
BLKSIZE_H =      $c92f      ;byte1 of block size - reverse endian
BLKSIZE_L =      $c930      ;byte0 of block size - reverse endian
LDIO_SIZE =      $c9ee
TMP_c9f1 =       $c9f1      ; 2-byte temp

         .org    $cc00
         .a8
         .i8
FN_04:   jsr     WAIT_FOR_REQ ;Get STATUS or MESSAGE byte into $c81f
         bcs     RET_FAIL_27_ALT
         lda     REG_5380_STAT2,y
         and     #$08       ;read phasematch
         beq     RET_FAIL_27 ;branch if phase mismatch
         lda     REG_5380_DATA,y ;read one byte from scsi bus
         sta     SCSI_RD_c81f
         lda     #$10
         sta     REG_5380_ICMD,y ;assert ACK
@FN_04_ack_loop:
         lda     REG_5380_ICMD,y ;why need to check?
         and     #$10
         beq     @FN_04_ack_loop ;check that ACK is asserted
         jsr     WAIT_FOR_NOT_REQ
         bcs     RET_FAIL_27_ALT
         lda     #$00
         sta     REG_5380_ICMD,y ;release bus
         txa
         rts

RET_FAIL_27_ALT:
         lda     #$27       ;seems redundant code
         bne     RET_Y

RET_FAIL_27:
         lda     #$27
RET_Y:   sta     RET_CODE
         ldy     SLOT_OFFSET
         rts

FN_14:   lda     #$02       ;Send SCSI CMD
         sta     REG_5380_TCMD,y ;set expectation for COMMAND phase
         jsr     WAIT_FOR_REQ
         bcs     RET_FAIL_27_ALT2 ;branch if req timeout
         lda     REG_5380_STAT2,y
         and     #$08
         beq     RET_FAIL_27_ALT2 ;branch if phase mismatch
         ldx     #$00
         stx     TMP_c80a
@FN_14_send_loop:
         jsr     WAIT_FOR_REQ
         bcs     RET_FAIL_27_ALT2 ;branch if req timeout
         ldx     TMP_c80a
         lda     SCSI_CDB_CMD,x
         sta     REG_5380_DATA_OUT,y ;send one byte of the SCSI CMD on the bus
         lda     #$01
         sta     REG_5380_ICMD,y ;enable DATA bus
         jsr     WAIT_FOR_REQ ;some of these WAIT_FOR_REQ seem redundant
         bcs     RET_FAIL_27_ALT2 ;branch if req timeout
         lda     #$11
         sta     REG_5380_ICMD,y ;assert ACK and keep data BUS enabled
         jsr     WAIT_FOR_NOT_REQ
         bcs     RET_FAIL_27_ALT2 ;branch if timeout on REQ deassertion
         lda     #$00
         sta     REG_5380_ICMD,y ;deassert ACK and disable DATA bus
         inc     TMP_c80a
         ldx     TMP_c80a
         cpx     SCSI_CMD_LEN
         bne     @FN_14_send_loop
         rts

RET_FAIL_27_ALT2:
         lda     #$27
         sta     RET_CODE
         rts

FN_24:   lda     CALL_TYPE
         and     #$40
         beq     @FN_24_not_ext
         lda     IS_IIgs
         bne     @FN_24_ext_call
@FN_24_not_ext:
         ldy     #$04
         lda     (TMP_PTR_L),y ;get SP status code
         sta     SCSI_CDB_CMD ;in this case this is the SP STATUS code
         lda     CALL_TYPE
         beq     @LCCA5     ;branch if std Smartport call
         ldy     #$06
         lda     (TMP_PTR_L),y ;get SP status code
         sta     SCSI_CDB_CMD ;in this case this is the SP STATUS code
@LCCA5:  jmp     @LCCAF

@FN_24_ext_call:
         ldy     #$06
         lda     [TMP_PTR_L],y
         sta     SCSI_CDB_CMD ;in this case this is the SP STATUS code
@LCCAF:  jsr     CALL_FN_62 ;add PART_START to LBA
         lda     SCSI_CDB_CMD ;in this case this is the SP STATUS code
         cmp     #$07
         bcc     @process_SP_STATUS ;branch if STATUS_CODE < 7
         lda     #$21
         jmp     CALL_FN_60_RET_Y ;FAIL_BADCTL

@process_SP_STATUS:
         tax
         lda     SP_STAT_JMPTABLE_L,x
         sta     TMP_PTR1
         lda     SP_STAT_JMPTABLE_H,x
         sta     TMP_PTR1+1
         jmp     (TMP_PTR1)

         .byte   $4c
         .byte   $be
         .byte   $cd

SP_STAT_00_STATUS:
         lda     SAVE_SP_UNIT
         bne     @device_status ;branch if UNIT!=0
         lda     #$00       ;BUS status - returns # of devices on the bus
         sta     RET_CODE
         sta     NUM_DEVICES ;NUM_DEVICES=0
         ldy     SLOT_OFFSET
         lda     REG_5380_STAT,y
         cmp     #$bf
         beq     @dev_count_done
         lda     #<SDAT
         sta     TMP_PTR0
         lda     #>SDAT
         sta     TMP_PTR0+1 ;TMP_PTR0=$c831 - SDAT_BASE
         ldy     #$00
@dev_count_loop:
         lda     (TMP_PTR0),y
         cmp     #$86
         bne     @dev_count_done ;branch if no signature
         inc     NUM_DEVICES
         tya
         clc
         adc     #SDAT_ENTRY_SIZE ;next entry
         tay
         bne     @dev_count_loop
@dev_count_done:
         ldy     #$00
         lda     CALL_TYPE
         beq     @std_call
         lda     IS_IIgs
         bne     @native
@std_call:
         lda     NUM_DEVICES
         sta     (BUF_PTR_L),y
         lda     #$00
@std_clr:
         iny
         sta     (BUF_PTR_L),y
         cpy     #$07
         bne     @std_clr
@LEN8_RETURN:
         sta     RX_LEN_HI
         lda     #$08
         sta     RX_LEN_LO  ;RX_LEN=8
         jmp     RESTORE_ZP_RET

@native: lda     NUM_DEVICES
         sta     [BUF_PTR_L],y
         lda     #$00
@native_clr:
         iny
         sta     [BUF_PTR_L],y
         cpy     #$07
         bne     @native_clr
         jmp     @LEN8_RETURN

@device_status:
         jsr     CALL_FN_1A ;RETURN DEVICE STATUS
         lda     #$04
         sta     RX_LEN_LO
         lda     #$00
         sta     RX_LEN_HI  ;RX_LEN=4
         lda     CALL_TYPE
         beq     @not_ext   ;branch if not extended
         inc     RX_LEN_LO  ;if(CALL_TYPE!=std) RX_LEN++
@not_ext:
         jmp     RESTORE_ZP_RET

CALL_FN_1A:
         lda     #$1a
CALL_FN_X4:
         ldx     #$04
         ldy     SLOT_OFFSET
         jsr     BANKSWITCH ;CALL_FN_X4
         rts

SP_STAT_03_RET_DIB:
         lda     SAVE_SP_UNIT
         beq     FAIL_BADUINT
         lda     #$0a
         jsr     CALL_FN_X4 ;CALL_FN_0A - RETURN DIB[DEV_IDX] entry
         jmp     RESTORE_ZP_RET

FAIL_BADUINT:
         lda     #$11
CALL_FN_60_RET_Y:
         ldy     SLOT_OFFSET
         jmp     CALL_FN_60_RET

SP_STAT_05_RET_ERROR:
         lda     SAVE_SP_UNIT
         beq     FAIL_BADUINT
         lda     #$04
         sta     SAVE_SP_CMD ;CMD=$04 (CONTROL) - REQUEST_SENSE
         ldy     SLOT_OFFSET
         lda     #$f3
         jmp     CALL_FN_X4_DUP ;CALL_FN_F3 - send REQUEST_SENSE

SP_STAT_06_RET_BLKSIZE:
         lda     SAVE_SP_UNIT
         beq     FAIL_BADUINT
         lda     #$02
         sta     RX_LEN_LO
         lda     #$00
         sta     RX_LEN_HI  ;RX_LEN=2
         ldy     #$00
         lda     CALL_TYPE
         and     #$40
         beq     BLKSIZE_CPY_EMU ;branch if not extended call
         lda     IS_IIgs
         bne     BLKSIZE_CPY_NATIVE ;branch if IIgs
BLKSIZE_CPY_EMU:
         lda     BLKSIZE_H
         sta     (BUF_PTR_L),y
         iny
         lda     BLKSIZE_L
         sta     (BUF_PTR_L),y
         jmp     RESTORE_ZP_RET

BLKSIZE_CPY_NATIVE:
         lda     BLKSIZE_H
         sta     [BUF_PTR_L],y
         iny
         lda     BLKSIZE_L
         sta     [BUF_PTR_L],y ;BLKSIZE=*(BUF_PTR+y)
         jmp     RESTORE_ZP_RET

ERROR_BADCTL:
         lda     #$21
         jmp     CALL_FN_60_RET

RESTORE_ZP_RET:
         lda     #$12
         jsr     CALL_FN_X4 ;CALL_FN_12 - restore ZP and return
         lda     RET_CODE
         bne     ERROR_27_RESET
         lda     #$00
         clc
         rts

ERROR_27_RESET:
         sta     REG_IO_5380_RST,y
         lda     #$27
         jmp     CALL_FN_60_RET

CALL_FN_62:
         lda     #$62
CALL_FN_X4_DUP:
         jmp     CALL_FN_X4

         .byte   $00
         .byte   $01
         .byte   $02
         .byte   $04
         .byte   $08
         .byte   $10
         .byte   $20
         .byte   $40
SP_STAT_JMPTABLE_L:
         .byte   <SP_STAT_00_STATUS ;SP_STATUS_00 - DEVICE STATUS
         .byte   <ERROR_BADCTL ;SP_STATUS_01
         .byte   <ERROR_BADCTL ;SP_STATUS_02
         .byte   <SP_STAT_03_RET_DIB ;SP_STATUS_03 - RETURN DIB
         .byte   <SP_STAT_03_RET_DIB ;SP_STATUS_04 - RETURN DIB extra
         .byte   <SP_STAT_05_RET_ERROR ;SP_STATUS_05 - RETURN last error
         .byte   <SP_STAT_06_RET_BLKSIZE ;SP_STATUS_06 - RETURN blksize
SP_STAT_JMPTABLE_H:
         .byte   >SP_STAT_00_STATUS
         .byte   >ERROR_BADCTL
         .byte   >ERROR_BADCTL
         .byte   >SP_STAT_03_RET_DIB
         .byte   >SP_STAT_03_RET_DIB
         .byte   >SP_STAT_05_RET_ERROR
         .byte   >SP_STAT_06_RET_BLKSIZE
WAIT_FOR_NOT_REQ:
         ldx     #$ff       ;wait for REQ deassertion (with timeout)
         stx     $c8f0
@wait_not_req_loop:
         dex
         bne     @wait_not_req_check
         dec     $c8f0      ;timeout waiting for REQ
         beq     wait_timeout
@wait_not_req_check:
         lda     REG_5380_STAT,y
         and     #$20
         bne     @wait_not_req_loop
         clc                ;req deasserted
         rts

WAIT_FOR_REQ:
         ldx     #$ff       ;wait for REQ assertion (with timeout)
         stx     $c8f0
@wait_for_req_loop:
         dex
         bne     @wait_req_check
         dec     $c8f0
         beq     wait_timeout ;timeout waiting for REQ
@wait_req_check:
         lda     REG_5380_STAT,y
         and     #$20
         beq     @wait_for_req_loop
         clc                ;REQ asserted
         rts

wait_timeout:
         sec
         rts

FN_34:   lda     #$02       ;Wait for REQ ad expect DATA IN
         sta     REG_5380_MODE_SEL,y ;enable BUSY monitoring
         lda     #$ff
         sta     TMP_c80a
@FN_34_loop:
         jsr     WAIT_FOR_REQ
         bcc     @FN_34_got_req ;branch if REQ asserted
         dec     TMP_c80a
         beq     @FN_34_timeout ;branch if timeout
         bne     @FN_34_loop

@FN_34_got_req:
         lda     #$01
         sta     REG_5380_TCMD,y ;set expected DATA IN phase
         clc
         rts

@FN_34_timeout:
         lda     #$28
         sta     RET_CODE
         sec
         rts

FN_64:   lda     REG_5380_STAT,y ;Prepare DMA Data OUT
         and     #$20
         beq     FN_64      ;wait for REQ to assert
         lda     #$00
         sta     REG_5380_TCMD,y ;set expected DATA OUT phase
         lda     #$01
         sta     REG_5380_ICMD,y ;enable DATA BUS
         lda     #$02
         sta     REG_5380_MODE_SEL,y ;enable DMA mode
         clc
         rts

         .byte   $a9
         .byte   $28
         .byte   $8d
         .byte   $0b
         .byte   $c8
         .byte   $38
         .byte   $60

FN_44:   lda     #$a3       ;call SEND_CMD_TEST_UNIT_READY and return $00
         jsr     CALL_FN_X4 ;CALL_FN_A3
         lda     #$00
         sta     RET_CODE
         rts

FN_74:   lda     CALL_TYPE  ;unreferenced function
         and     #$40
         bne     @FN_74_ext_call
         ldy     #$05
         lda     (TMP_PTR_L),y
         sta     PD_PAR_BLK_LO
         sta     RX_LEN_LO
         iny
         lda     (TMP_PTR_L),y
         sta     PD_PAR_BLK_HI
         sta     RX_LEN_HI
         clc
         ror     A
         sta     SCSI_CDB10_8
         iny
         lda     (TMP_PTR_L),y
         clc
         adc     PART_START+2
         sta     SCSI_CDB_CTRL
         iny
         lda     (TMP_PTR_L),y
         adc     PART_START+1
         sta     SCSI_CDB_LEN
         iny
         lda     (TMP_PTR_L),y
         adc     PART_START
         sta     SCSI_CDB_LBA_LO
         ldy     SLOT_OFFSET
         rts

@FN_74_ext_call:
         ldy     #$07
         lda     [TMP_PTR_L],y
         sta     PD_PAR_BLK_LO
         sta     RX_LEN_LO
         iny
         lda     [TMP_PTR_L],y
         sta     PD_PAR_BLK_HI
         sta     RX_LEN_HI
         iny
         lda     [TMP_PTR_L],y
         clc
         adc     PART_START+2
         sta     SCSI_CDB_CTRL
         iny
         lda     [TMP_PTR_L],y
         adc     PART_START+1
         sta     SCSI_CDB_LEN
         iny
         lda     [TMP_PTR_L],y
         adc     PART_START
         sta     SCSI_CDB_LBA_LO
         iny
         lda     [TMP_PTR_L],y
         adc     #$00
         sta     SCSI_CDB_LBA_HI
         lda     PD_PAR_BLK_HI
         clc
         ror     A
         sta     SCSI_CDB10_8
         ldy     SLOT_OFFSET
         rts

FN_84:   lda     PD_PAR_BUF_LO ;copy PD buf to BUF_PTR
         sta     BUF_PTR_L
         lda     PD_PAR_BUF_HI
         sta     BUF_PTR_H
         lda     #$00
         sta     BUF_PTR_VH
         sta     BUF_PTR_XH
         rts

FN_94:   lda     RET_CODE   ;restore ZP and return
         cmp     #$08
         bne     @LCF03
         lda     #$2f
         sta     RET_CODE
@LCF03:  lda     IS_IIgs
         beq     @FN_94_skip2gs ;branch if not IIgs
         lda     SAVE_CYAREG
         sta     CYAREG
@FN_94_skip2gs:
         ldx     #$07
@FN_94_loop1:
         lda     SAVE_ZP_F6,x
         sta     TMP_PTR_L,x
         lda     SAVE_ZP_15,x
         sta     $15,x
         lda     PD_PAR_CMD_CPY,x
         sta     PD_PAR_CMD,x
         dex
         bpl     @FN_94_loop1
         ldx     #$0a
@FN_94_loop2:
         lda     SAVE_ZP_15,x
         sta     $15,x
         dex
         cpx     #$07
         bne     @FN_94_loop2
         rts

FN_A4:   ldx     DEV_IDX    ;Get SDAT entry in TMP_PTR0 for index at $c800
         lda     #<SDAT
@FN_A4_loop:
         dex
         bmi     @FN_A4_done
         clc
         adc     #SDAT_ENTRY_SIZE
         bne     @FN_A4_loop
@FN_A4_done:
         sta     TMP_PTR0
         lda     #>SDAT
         sta     TMP_PTR0+1
         rts

FN_B4:   tya                ;IIgs LDIO DMA read ?????
         tax
         ldy     #$00
@LCF47:  lda     REG_IO_DRQ,x
         bpl     @LCF6C
         lda     REG_IO_PDMA_DACK,x
         sta     [BUF_PTR_L],y
         iny
         bne     @LCF47
         lda     #$00
         sta     TCOUNT_B1
         inc     BUF_PTR_H
         bne     @LCF5F
         inc     BUF_PTR_VH
@LCF5F:  inc     TMP_c9f1+1
         lda     TMP_c9f1+1
         cmp     LDIO_SIZE+1
         bne     @LCF47
         beq     @LCF7F

@LCF6C:  lda     REG_5380_STAT2,x
         and     #$08
         beq     @LCF7F
         dec     TCOUNT_B0
         bne     @LCF47
         dec     TCOUNT_B1
         beq     @LCF82
         bne     @LCF47

@LCF7F:  clc
         bcc     @LCF86

@LCF82:  sec
         sty     TMP_c9f1
@LCF86:  ldy     SLOT_OFFSET
         rts

CALL_FN_60_RET:
         sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH

FN_TABLE:
         .word   FN_04
         .word   FN_14
         .word   FN_24
         .word   FN_34
         .word   FN_44
         .word   FN_34
         .word   FN_64
         .word   FN_74
         .word   FN_84
         .word   FN_94
         .word   FN_A4
         .word   FN_B4
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

         .byte   $02
         .byte   $31
         .byte   $34
         .byte   $30
