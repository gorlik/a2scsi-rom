; Target assembler: cc65 v2.18.0 [--target none -C bank01.bin_cc65.cfg]
; 6502bench SourceGen v1.7.3
         .setcpu "65816"
SCSI_CMD_READ6 = $08
SCSI_CMD_WRITE6 = $0a
P8E_IO_ERR =     $27        ;I/O error

TMP_PTR1 =       $1b        ; temporary ZP pointer 
PD_PAR_BLK_LO =  $46        ;PRODOS input parameter Block lo
PD_PAR_BLK_HI =  $47        ;PRODOS input parameter Block hi
TMP_PTR_L =      $f6        ; temporary ZP long pointer
TMP_PTR_H =      $f7
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
REG_5380_DATA =  $c000      ; R current SCSI data lines status
REG_5380_DATA_OUT = $c000   ; W SCSI data output register
REG_5380_ICMD =  $c001      ; RW Initiator command register
REG_5380_MODE_SEL = $c002   ; RW Mode select register
REG_5380_TCMD =  $c003      ; RW target command register
REG_5380_STAT =  $c004      ; R SCSI status
REG_5380_START_WDMA = $c005 ; W start DMA send
REG_5380_STAT2 = $c005      ; R Bus and status register
REG_5380_START_IRDMA = $c007 ; W start DMA initiator receive
REG_IO_PDMA_DACK = $c008    ; RW PDMA/DACK
REG_IO_BANK_SEL = $c00a     ; W memory bank select
REG_IO_5380_RST = $c00b     ; W 5380 Reset
REG_IO_PDMA_EN = $c00d      ; W PDMA mode enable
REG_IO_DRQ =     $c00e      ; R read DRQ on bit7
CYAREG   =       $c036      ;RW Configure Your Apple
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B2 =      $c802      ; timeout counter MSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
XFER_MODE =      $c804      ; 0x00 IIe PDMA, 0x01 IIgs PDMA, 0x02-0xff PIO 
SAVE_CYAREG =    $c808      ; saved value of CYAREG
INIT_FLAG =      $c809      ; card initialized flag (init=$77)
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
SCSI_RD_c81f =   $c81f      ; SCSI STATUS or MESSAGE return from FN_04 
BLK_c8c7 =       $c8c7      ; saved PRODOS BLOCK from input parameters
LBA_c8db =       $c8db      ; LBA to use in CDB (?) (copied to CDB_LBA)
BOOT_SEQ =       $c8e3      ; $55 if in boot process
RX_LEN_LO =      $c8e4      ; bytes read if call successfull
RX_LEN_HI =      $c8e5      ; bytes read if call successfull
IS_IIgs  =       $c8f3      ;0x01 if IIgs

         .org    $cc00
         .a8
         .i8
FN_01:   jsr     COPY_PD_BLK ;Receive SCSI DATA to BUF_PTR
         lda     XFER_MODE
         beq     @FN_01_2ePDMA ;IIe PDMA
         cmp     #$01
         beq     FN_01_2gsPDMA ;IIgs PDMA
         jsr     SET_NATIVE_IF_NEEDED
         jsr     WAIT_DATA_IN_REQ
         jmp     READ_BYTES_PIO

@FN_01_2ePDMA:
         jsr     FN_61      ;PREPARE DMA Receive
         jsr     CHECK_NATIVE_NEEDED
         bcs     LCC44      ;branch to CALL_FN_3C if native
         jsr     DMA_READ   ;emulation path
         txa
         tay
LCC22:   lda     #$00       ;return from native path here
         sta     REG_5380_MODE_SEL,y
         rts

FN_01_2gsPDMA:
         lda     CYAREG
         sta     SAVE_CYAREG
         lda     SCSI_CDB_CMD
         cmp     #SCSI_CMD_READ6
         bne     @FN_01_dma_send ;branch if CMD is not READ6
         jsr     FN_61      ;PREPARE DMA Receive
@FN_01_end:
         lda     #$2d
         jsr     CALL_FN_X1 ;CALL_FN_2D
         rts

@FN_01_dma_send:
         jsr     FN_71      ;PREPARE DMA Send
         jmp     @FN_01_end

LCC44:   lda     #$3c
         jsr     CALL_FN_X1 ;CALL_FN_3C
         jmp     LCC22

FN_11:   jsr     COPY_PD_BLK ;Data Xout (from BUF_PTR)
         lda     XFER_MODE
         beq     XOUT_PDMA  ;IIe PDMA
         cmp     #$01
         beq     XOUT_PDMA  ;IIgs PDMA
         jsr     SET_NATIVE_IF_NEEDED
         jsr     XOUT_PIO
         jmp     WRITE_BYTES_PIO

XOUT_PDMA:
         jsr     FN_71
         jsr     CHECK_NATIVE_NEEDED
         bcs     NATIVE_REQUIRED ;NATIVE if c=1
         jsr     LCE10
LCC6C:   ldy     SLOT_OFFSET
         lda     #$00
         sta     REG_5380_MODE_SEL,y
         rts

NATIVE_REQUIRED:
         lda     #$4c
         jsr     CALL_FN_X1 ;CALL_FN_4C
         jmp     LCC6C

CHECK_NATIVE_NEEDED:
         lda     CALL_TYPE
         and     #$40
         beq     @NATIVE_not_req
         lda     IS_IIgs
         beq     @NATIVE_not_req
         sec
         rts

@NATIVE_not_req:
         clc
         rts

COPY_PD_BLK:
         lda     BLK_c8c7
         sta     PD_PAR_BLK_LO
         lda     BLK_c8c7+1
         sta     PD_PAR_BLK_HI
         rts

WAIT_DATA_IN_REQ:
         lda     #$01
         sta     REG_5380_TCMD,y ;set expectation for DATA IN phase
         sta     TCOUNT_B0
@timoeut_loop:
         jsr     WAIT_FOR_REQ
         bcc     @req_asserted
         inc     TCOUNT_B0
         bne     @timoeut_loop
         beq     IOERROR

@req_asserted:
         lda     REG_5380_STAT2,y
         and     #$08
         beq     IOERROR    ;branch if phase mismatch
func_return:
         tya
         tax
         rts

IOERROR: lda     INIT_FLAG
         cmp     #$77
         bne     @ret_code_only ;branch if not init
         lda     BOOT_SEQ
         cmp     #$55
         beq     @ret_code_only ;branch if in boot sequence
         lda     #P8E_IO_ERR
         jsr     CALL_FN_60_RET ;ERROR_IOERROR
@ret_code_only:
         lda     #P8E_IO_ERR
         sta     RET_CODE   ;ERROR_IOERROR
         bne     func_return

XOUT_PIO:
         lda     #$00
         sta     REG_5380_TCMD,y ;set expectation for DATA OUT phase
         sta     TCOUNT_B0
@xout_pio_loop:
         jsr     WAIT_FOR_REQ
         bcc     @req_found
         dec     TCOUNT_B0
         bne     @xout_pio_loop
         beq     IOERROR

@req_found:
         tya
         tax
         rts

READ_BYTES_PIO:
         ldy     #$00       ;Read SCSI DATA
@read_more_data:
         jsr     CHECK_NATIVE_NEEDED
         bcc     @native_not_req
         lda     REG_5380_DATA,x
         sta     [BUF_PTR_L],y
         jmp     @data_read

@native_not_req:
         lda     REG_5380_DATA,x
         sta     (BUF_PTR_L),y
@data_read:
         iny                ;advance the index
         bne     @end_ptr_inc
         inc     BUF_PTR_H  ;advance the pointer if necessary
         bne     @end_ptr_inc
         jsr     CHECK_NATIVE_NEEDED
         bcc     @end_ptr_inc
         inc     BUF_PTR_VH
@end_ptr_inc:
         lda     #$10
         sta     REG_5380_ICMD,x ;assert ACK
@req_loop1:
         lda     REG_5380_STAT,x ;WAIT FOR REQ ASSERTION
         and     #$20       ;REQ mask bit
         bne     @req_loop1 ;branch if REQ not asserted
         lda     #$00
         sta     REG_5380_ICMD,x ;deassert ACK
@req_loop2:
         lda     REG_5380_STAT,x ;WAIT for REQ DEASSERTION
         and     #$20       ;REQ mask bit
         beq     @req_loop2 ;branch if REQ asserted
         lda     REG_5380_STAT2,x
         and     #$08
         beq     @done_reading ;branch if phase mismatch
         jmp     @read_more_data

@done_reading:
         lda     SAVE_SP_CMD
         cmp     #$04       ;SP CMD Control
         bne     @not_control ;branch if command not control
         sty     RX_LEN_LO  ;return the # of bytes read
         ldy     #$00
         sty     RX_LEN_HI
@not_control:
         txa
         tay
         jmp     RESTORE_EMU_IF_NEEDED

WRITE_BYTES_PIO:
         ldy     #$00
@write_more_data:
         jsr     CHECK_NATIVE_NEEDED
         bcs     @native_req
         lda     (BUF_PTR_L),y
         jmp     @skip_native

@native_req:
         lda     [BUF_PTR_L],y
@skip_native:
         sta     REG_5380_DATA_OUT,x ;put data on SCSI BUS
         lda     #$01
         sta     REG_5380_ICMD,x ;enable SCSI DATA buffers
         iny
@req1_loop:
         lda     REG_5380_STAT,x ;wait for REQ asserted by target
         and     #$20
         beq     @req1_loop
         lda     #$11
         sta     REG_5380_ICMD,x ;assert ACK
@req0_loop:
         lda     REG_5380_STAT,x ;wait for REQ to deassert
         and     #$20
         bne     @req0_loop
         lda     #$00
         sta     REG_5380_ICMD,x ;deassert REQ and disable DATA bus
         lda     REG_5380_STAT2,x
         and     #$08
         beq     @write_pio_end ;branch if phase not match
         jsr     DELAY_FF
         lda     REG_5380_STAT,x
         and     #$1c
         bne     @write_pio_end ;branch id phase not DATA OUT
         jmp     @write_more_data

@write_pio_end:
         txa
         tay
         jmp     RESTORE_EMU_IF_NEEDED

DELAY_FF:
         lda     #$ff
         sta     TCOUNT_B0
@delay_loop:
         dec     TCOUNT_B0
         bne     @delay_loop
         rts

FN_61:   jsr     WAIT_FOR_REQ_NOT_STATUS ;PREPARE_DMA_RECEIVE
         bcs     RET_IOERROR
         lda     #$01
         sta     REG_5380_TCMD,y ;set expectation for DATA IN phase
         lda     #$02       ;DMA enable mask
         sta     REG_IO_PDMA_EN,y
         sta     REG_5380_MODE_SEL,y ;enable DMA mode
         lda     #$00
         sta     REG_5380_START_IRDMA,y ;start DMA receive
         tya
         tax
         rts

RET_IOERROR:
         lda     #$27
         sta     RET_CODE
         rts

FN_71:   jsr     WAIT_FOR_REQ_NOT_STATUS ;PREPARE DMA send
         bcs     RET_IOERROR ;bug??? the routine called never sets carry
         lda     #$00
         sta     REG_5380_TCMD,y ;set expectation for DATA OUT phase
         lda     #$01
         sta     REG_5380_ICMD,y ;assert data bus
         lda     #$02       ;DMA enable mask
         sta     REG_IO_PDMA_EN,y
         sta     REG_5380_MODE_SEL,y ;enable DMA
         sta     REG_5380_START_WDMA,y ;????
         tya
         clc
         adc     #$09       ;no idea why they add 9 to the index
         tax
         lda     #$00
         jmp     WAIT_FOR_PHASE_MISMATCH

WAIT_FOR_REQ_NOT_STATUS:
         lda     #$00
         sta     TCOUNT_B0
         sta     TCOUNT_B2
@wait_for_req_loop:
         lda     REG_5380_STAT,y
         cmp     #$6c
         beq     @IOERROR_DUP ;branch if status phase and REQ
         and     #$20
         bne     @req_found ;branch if REQ asserted
         dec     TCOUNT_B0
         bne     @wait_for_req_loop
         dec     TCOUNT_B2
         bne     @wait_for_req_loop ;bug?? never set carry when timeout
@req_found:
         clc
         rts

@IOERROR_DUP:
         jmp     IOERROR

WAIT_FOR_PHASE_MISMATCH:
         sta     TCOUNT_B2
         sta     TCOUNT_B0
@wait_mismatch_loop:
         lda     REG_5380_STAT2-9,x ;compensate for the additional 9 in the index
         and     #$08
         bne     @wait_mismatch_end ;branch if phase mismatch
         dec     TCOUNT_B0
         bne     @wait_mismatch_loop
         dec     TCOUNT_B2
         bne     @wait_mismatch_loop
@wait_mismatch_end:
         rts

LCE10:   jsr     SET_TIMEOUT_02
@LCE13:  lda     REG_IO_DRQ-9,x
         bmi     @LCE3E
@LCE18:  dec     TCOUNT_B0
         bne     @LCE22
         dec     TCOUNT_B1
         beq     RET_27_RESTORE
@LCE22:  lda     REG_5380_STAT-9,x
         and     #$20
         bne     @LCE30
         lda     REG_IO_DRQ-9,x
         bmi     @LCE3E
         bpl     @LCE18

@LCE30:  lda     REG_IO_DRQ-9,x
         bmi     @LCE3E
         lda     REG_5380_STAT2-9,x
         and     #$08
         beq     RESTORE_EMU_IF_NEEDED_LOCAL
         bne     @LCE18

@LCE3E:  lda     (BUF_PTR_L),y
         sta     REG_IO_PDMA_DACK-9,x
         iny
         bne     @LCE13
         dec     TCOUNT_B2
         beq     @LCE50
         inc     BUF_PTR_H
         jmp     @LCE13

@LCE50:  lda     #$00
         sta     TCOUNT_B2
@LCE55:  lda     REG_IO_DRQ-9,x
         bmi     @LCE68
         lda     REG_5380_STAT2-9,x
         and     #$08
         beq     RESTORE_EMU_IF_NEEDED_LOCAL
         dec     TCOUNT_B2
         beq     RET_27_RESTORE
         bne     @LCE55

@LCE68:  sta     REG_IO_PDMA_DACK-9,x
         clc
         bcc     @LCE55

RESTORE_EMU_IF_NEEDED_LOCAL:
         jmp     RESTORE_EMU_IF_NEEDED

RET_27_RESTORE:
         lda     #$27
         sta     RET_CODE
         bne     RESTORE_EMU_IF_NEEDED_LOCAL

SET_TIMEOUT_02:
         lda     #$00
         ldy     #$00
         sta     TCOUNT_B0
         sta     TCOUNT_B1
         lda     #$02
         sta     TCOUNT_B2
         rts

FN_81:   tya                ;DMA READ
         tax
         jsr     DMA_READ
         txa
         tay
         lda     #$00
         sta     REG_5380_MODE_SEL,y
         rts

DMA_READ:
         jsr     SET_TIMEOUT_02
@drq_read_loop:
         lda     REG_IO_DRQ,x
         bmi     @drq_read_asserted ;branch if DRQ asserted
         dec     TCOUNT_B0
         bne     @drq_read_loop
         dec     TCOUNT_B1
         beq     RET_27
         bne     @drq_read_loop

@drq_read_asserted:
         lda     REG_IO_PDMA_DACK,x
         sta     (BUF_PTR_L),y
         iny
         bne     @drq_read_loop
         dec     TCOUNT_B2  ;this is not timeout but read page counter
         beq     @end_read_dma
         inc     BUF_PTR_H
         jmp     @drq_read_loop

@end_read_dma:
         sty     TCOUNT_B2  ;redundant??  gets here only when tcount==0
@end_dma_loop:
         lda     REG_IO_DRQ,x
         bmi     @got_dreq  ;branch on DRQ asserted
         lda     REG_5380_STAT2,x
         and     #$08
         beq     RESTORE_EMULATION_NEAR ;branch on phase mismatch
         dec     TCOUNT_B2  ;now TCOUNT is timeout
         beq     RET_27
         bne     @end_dma_loop

@got_dreq:
         lda     REG_IO_PDMA_DACK,x
         clc
         bcc     @end_dma_loop

RESTORE_EMULATION_NEAR:
         jmp     RESTORE_EMU_IF_NEEDED

RET_27:  lda     #$27
         sta     RET_CODE
         bne     RESTORE_EMULATION_NEAR

WAIT_FOR_REQ:
         ldx     #$ff
@req_loop:
         dex
         beq     @req_timeout
         lda     REG_5380_STAT,y
         and     #$20
         beq     @req_loop
         clc
         rts

@req_timeout:
         sec
         rts

SET_NATIVE_IF_NEEDED:
         lda     CALL_TYPE
         and     #$40
         beq     @set_native_end
         lda     IS_IIgs
         beq     @set_native_end
         jsr     SET_NATIVE_MODE
         lda     SAVE_CYAREG
         ora     #$80
         sta     CYAREG
@set_native_end:
         rts

SET_NATIVE_MODE:
         clc
         xce
         rts

RESTORE_EMU_IF_NEEDED:
         lda     CALL_TYPE
         and     #$40
         beq     @restore_mode_end
         lda     IS_IIgs
         beq     @restore_mode_end
         sec
         xce
         lda     SAVE_CYAREG
         sta     CYAREG
@restore_mode_end:
         rts

FN_21:   lda     #$f5
         sta     TMP_PTR_L
         lda     #$c8
         sta     TMP_PTR_H  ;TMP_PTR = $c8f5
         lda     #$00
         ldy     #$0b
@clr_loop_fn21:
         sta     (TMP_PTR_L),y
         dey
         bpl     @clr_loop_fn21 ;clear 12 bytes starting at 0xc8f5
         ldy     #$02
         lda     #$f9
         sta     (TMP_PTR_L),y
         iny
         lda     TMP_PTR_H
         sta     (TMP_PTR_L),y ;*($c8f5+2)=$c8f9
         lda     #$04
         ldy     #$07
         sta     (TMP_PTR_L),y ;*$(c8f5+7)=$04
         ldy     #$09
         ldx     #$01
@cpy_loop_fn21:
         lda     SCSI_CDB_CMD,x
         sta     (TMP_PTR_L),y
         iny
         inx
         cpx     #$04
         bne     @cpy_loop_fn21 ;copy SCSI CDB block number to offset $c8f5+9
         lda     #$03       ;CALL_FN_03 - Do Status
CALL_FN_X1:
         ldx     #$01
         ldy     SLOT_OFFSET
         jmp     BANKSWITCH ;CALL_FN_X1

FN_31:   lda     #$03       ;READ STATUS and MESSAGE
         jsr     SET_PHASE_AND_READ_STAT_OR_MSG ;set expectation for STATUS phase
         lda     SCSI_RD_c81f
         sta     CMD_STATUS
         lda     #$07
         jsr     SET_PHASE_AND_READ_STAT_OR_MSG ;set expectation for MESSAGE IN phase
         ldy     SLOT_OFFSET
         lda     #$00
         sta     REG_5380_ICMD,y
         sta     REG_IO_5380_RST,y
         rts

SET_PHASE_AND_READ_STAT_OR_MSG:
         sta     REG_5380_TCMD,y
         lda     #$04
         jmp     CALL_FN_X1 ;CALL_FN_04

FN_41:   lda     #SCSI_CMD_READ6 ;load CDB READ6
         jmp     LOAD_CDB_RW6

FN_51:   lda     #SCSI_CMD_WRITE6 ;load CDB WRTIE6
         jmp     LOAD_CDB_RW6

LOAD_CDB_RW6:
         sta     SCSI_CDB_CMD
         lda     #$06
         sta     SCSI_CMD_LEN
         lda     LBA_c8db
         sta     SCSI_CDB_LBA_LO
         lda     LBA_c8db+1
         sta     SCSI_CDB_LBA_HI
         lda     LBA_c8db+2
         sta     SCSI_CDB_LUN
         lda     #$01
         sta     SCSI_CDB_LEN
         rts

CALL_FN_60_RET:
         sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH ;CALL_FN_60_RET

FN_TABLE:
         .word   FN_01
         .word   FN_11
         .word   FN_21
         .word   FN_31
         .word   FN_41
         .word   FN_51
         .word   FN_61
         .word   FN_71
         .word   FN_81
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
