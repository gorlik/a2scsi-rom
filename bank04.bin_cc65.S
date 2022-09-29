; Target assembler: cc65 v2.18.0 [--target none -C bank04.bin_cc65.cfg]
; 6502bench SourceGen v1.7.3
         .setcpu "65816"
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
SAVE_Y   =       $c81a      ; slot adress (n+8)<<4 
SAVE_SP_CMD_B =  $c81b      ; saved SmartPort Command
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
SCSI_RD_c81f =   $c81f      ; SCSI STATUS or MESSAGE return from FN_04 
PART_START =     $c824      ; partition start (3 bytes) seems to be in reverse endian (?)
SAVE_ZP_F6 =     $c8a8      ;saved zero page locations $f6-$fd
SAVE_ZP_15 =     $c8b0      ;saved zero page locations $15-$1e
PD_PAR_CMD_CPY = $c8bc      ;PRODOS input parameter COMMAND number
RX_LEN_LO =      $c8e4      ;bytes read if call successfull
RX_LEN_HI =      $c8e5      ;bytes read if call successfull
SAVE_SP_UNIT =   $c8e8      ; saved Smartport UNIT number
IIgs_PDMA =      $c8f3      ;0x01 if IIgs PDMA
BLKSIZE_H =      $c92f      ;byte1 of block size
BLKSIZE_L =      $c930      ;byte0 of block size
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB

         .org    $cc00
         .a8
         .i8
FN_04:   jsr     WAIT_FOR_REQ ;Get STATUS and MESSAGE
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
         bne     LCC30

RET_FAIL_27:
         lda     #$27
LCC30:   sta     RET_CODE
         ldy     SAVE_Y
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
         lda     IIgs_PDMA
         bne     @FN_24_ext_call
@FN_24_not_ext:
         ldy     #$04
         lda     (TMP_PTR_L),y
         sta     SCSI_CDB_CMD
         lda     CALL_TYPE
         beq     @LCCA5     ;branch if std Smartport call
         ldy     #$06
         lda     (TMP_PTR_L),y
         sta     SCSI_CDB_CMD
@LCCA5:  jmp     @LCCAF

@FN_24_ext_call:
         ldy     #$06
         lda     [TMP_PTR_L],y
         sta     SCSI_CDB_CMD
@LCCAF:  jsr     CALL_FN_62
         lda     SCSI_CDB_CMD
         cmp     #$07
         bcc     @LCCBE
         lda     #$21
         jmp     LCD68

@LCCBE:  tax
         lda     LCDE1,x
         sta     TMP_PTR1
         lda     LCDE8,x
         sta     TMP_PTR1+1
         jmp     (TMP_PTR1)

         .byte   $4c
         .byte   $be
         .byte   $cd

TCCCF:   lda     SAVE_SP_UNIT
         bne     @LCD36
         lda     #$00
         sta     RET_CODE
         sta     PART_START-1
         ldy     SAVE_Y
         lda     REG_5380_STAT,y
         cmp     #$bf
         beq     @LCD00
         lda     #$31
         sta     TMP_PTR0
         lda     #$c8
         sta     TMP_PTR0+1
         ldy     #$00
@LCCF0:  lda     (TMP_PTR0),y
         cmp     #$86
         bne     @LCD00
         inc     PART_START-1
         tya
         clc
         adc     #$11
         tay
         bne     @LCCF0
@LCD00:  ldy     #$00
         lda     CALL_TYPE
         beq     @LCD0C
         lda     IIgs_PDMA
         bne     @LCD25
@LCD0C:  lda     PART_START-1
         sta     (BUF_PTR_L),y
         lda     #$00
@LCD13:  iny
         sta     (BUF_PTR_L),y
         cpy     #$07
         bne     @LCD13
@LCD1A:  sta     RX_LEN_HI
         lda     #$08
         sta     RX_LEN_LO
         jmp     LCDBE

@LCD25:  lda     PART_START-1
         sta     [BUF_PTR_L],y
         lda     #$00
@LCD2C:  iny
         sta     [BUF_PTR_L],y
         cpy     #$07
         bne     @LCD2C
         jmp     @LCD1A

@LCD36:  jsr     @LCD4E
         lda     #$04
         sta     RX_LEN_LO
         lda     #$00
         sta     RX_LEN_HI
         lda     CALL_TYPE
         beq     @LCD4B
         inc     RX_LEN_LO
@LCD4B:  jmp     LCDBE

@LCD4E:  lda     #$1a
CALL_FN_Y4:
         ldx     #$04
         ldy     SAVE_Y
         jsr     BANKSWITCH
         rts

TCD59:   lda     SAVE_SP_UNIT
         beq     LCD66
         lda     #$0a
         jsr     CALL_FN_Y4
         jmp     LCDBE

LCD66:   lda     #$11
LCD68:   ldy     SAVE_Y
         jmp     LCF8A

TCD6E:   lda     SAVE_SP_UNIT
         beq     LCD66
         lda     #$04
         sta     SAVE_SP_CMD_B
         ldy     SAVE_Y
         lda     #$f3
         jmp     LCDD6

TCD80:   lda     SAVE_SP_UNIT
         beq     LCD66
         lda     #$02
         sta     RX_LEN_LO
         lda     #$00
         sta     RX_LEN_HI
         ldy     #$00
         lda     CALL_TYPE
         and     #$40
         beq     @LCD9D
         lda     IIgs_PDMA
         bne     @LCDAB
@LCD9D:  lda     BLKSIZE_H
         sta     (BUF_PTR_L),y
         iny
         lda     BLKSIZE_L
         sta     (BUF_PTR_L),y
         jmp     LCDBE

@LCDAB:  lda     BLKSIZE_H
         sta     [BUF_PTR_L],y
         iny
         lda     BLKSIZE_L
         sta     [BUF_PTR_L],y
         jmp     LCDBE

TCDB9:   lda     #$21
         jmp     LCF8A

LCDBE:   lda     #$12
         jsr     CALL_FN_Y4
         lda     RET_CODE
         bne     @LCDCC
         lda     #$00
         clc
         rts

@LCDCC:  sta     REG_IO_5380_RST,y
         lda     #$27
         jmp     LCF8A

CALL_FN_62:
         lda     #$62
LCDD6:   jmp     CALL_FN_Y4

         .byte   $00
         .byte   $01
         .byte   $02
         .byte   $04
         .byte   $08
         .byte   $10
         .byte   $20
         .byte   $40
LCDE1:   .byte   <TCCCF
         .byte   <TCDB9
         .byte   <TCDB9
         .byte   <TCD59
         .byte   <TCD59
         .byte   <TCD6E
         .byte   <TCD80
LCDE8:   .byte   >TCCCF
         .byte   >TCDB9
         .byte   >TCDB9
         .byte   >TCD59
         .byte   >TCD59
         .byte   >TCD6E
         .byte   >TCD80
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

FN_64:   lda     REG_5380_STAT,y
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
         jsr     CALL_FN_Y4 ;CALL_FN_A3
         lda     #$00
         sta     RET_CODE
         rts

FN_74:   lda     CALL_TYPE
         and     #$40
         bne     @LCEA8
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
         ldy     SAVE_Y
         rts

@LCEA8:  ldy     #$07
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
         ldy     SAVE_Y
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
@LCF03:  lda     IIgs_PDMA
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
         lda     #$31
@FN_A4_loop:
         dex
         bmi     @FN_A4_done
         clc
         adc     #$11
         bne     @FN_A4_loop
@FN_A4_done:
         sta     TMP_PTR0
         lda     #$c8
         sta     TMP_PTR0+1
         rts

FN_B4:   tya
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
@LCF5F:  inc     DEV_STATUS-1
         lda     DEV_STATUS-1
         cmp     $c9ef
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
         sty     $c9f1
@LCF86:  ldy     SAVE_Y
         rts

LCF8A:   sta     RET_CODE
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
         jsr     @LCFF9
         pla
         and     #$0f
         sta     REG_IO_BANK_SEL,y
         clc
         rts

@LCFF9:  jmp     (TMP_PTR1)

         .byte   $02
         .byte   $31
         .byte   $34
         .byte   $30
