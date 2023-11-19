; Target assembler: cc65 v2.18.0 [--target none -C bank15.bin_cc65.cfg]
; 6502bench SourceGen v1.8.3
         .setcpu "65816"
TMP_PTR0 =       $19        ; temporary ZP pointer 
JMP_PTR  =       $1b        ; Jmp target ZP pointer 
MON_CV   =       $25        ;cursor vertical displacement
MEM_PTR_L =      $f6        ; temporary ZP long pointer
MEM_PTR_H =      $f7
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
BUF_PTR_XH =     $fd
REG_5380_DATA =  $c000      ; R current SCSI data lines status
REG_5380_ICMD =  $c001      ; RW Initiator command register
REG_5380_TCMD =  $c003      ; RW target command register
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
BSW_TEMP =       $c80c      ; TEMP in BANKSWITCH
SLOT_OFFSET =    $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
BOOT_SEQ =       $c8e3      ; $55 if in boot process
SAVE_SP2 =       $c8ed      ;saved SP - also used a random temp
IS_IIgs  =       $c8f3      ;0x01 if IIgs
LDIO_SIZE =      $c9ee
TMP_c9f1 =       $c9f1      ; 2-byte temp
MON_SETTXT =     $fb39      ;set screen to text mode
MON_HOME =       $fc58      ;clear screen and reset text output to top-left
MON_COUT =       $fded      ;print Acc to output device via $36-37
MON_SETKBD =     $fe89      ;reset char input handler to ROM
MON_SETVID =     $fe93      ;reset char output handler to ROM

         .org    $cc00
         .a8
         .i8
FN_0F:   jsr     INIT_PM_SIZE ;Init Partition Map entry @ BUF_PTR
         ldx     #$00
         ldy     #$30
@string_cpy1:
         lda     String_Apple_PRODOS,x ;Fill type of partition with "Apple PRODOS"
         sta     (BUF_PTR_L),y
         inx
         iny
         cpy     #$3a
         bne     @string_cpy1
         ldy     #$10
         ldx     #$00
@string_cpy2:
         lda     String_Apple_II,x ;Fill name of partition with "APPLE II"
         sta     (BUF_PTR_L),y
         iny
         inx
         cpx     #$08
         bne     @string_cpy2
         lda     #$00
         sta     (BUF_PTR_L),y
         beq     RET_LOAD_Y

String_Apple_PRODOS:
         .byte   "Apple PRODOS"
String_Apple_II:
         .byte   "Apple //"

FN_1F:   lda     #$00
         ldy     #$08       ;clear range $08-$10
@clr_loop:
         sta     (BUF_PTR_L),y
         iny
         cpy     #$10
         bne     @clr_loop
         ldy     #$09
         lda     #$01
         sta     (BUF_PTR_L),y ;put $01 at offset $09
         iny
         iny
         sta     (BUF_PTR_L),y ;put $01 at offset $0B
RET_LOAD_Y:
         ldy     SLOT_OFFSET
         rts

FN_2F:   jsr     INIT_PM_TABLE
         ldx     #$00
         ldy     #$30
@string_cpy3:
         lda     String_apple_part_map,x
         sta     (BUF_PTR_L),y
         inx
         iny
         cpx     #$13
         bne     @string_cpy3
         ldy     #$10
         ldx     #$00
@string_cpy4:
         lda     String_Apple_II,x
         sta     (BUF_PTR_L),y
         iny
         inx
         cpx     #$08
         bne     @string_cpy4
         lda     #$00
         sta     (BUF_PTR_L),y
         ldy     SLOT_OFFSET
         rts

String_apple_part_map:
         .byte   "Apple_partition_map"

INIT_PM_TABLE:
         jsr     INIT_PM_SIG
         ldy     #$0f
         lda     #$3f
         sta     (BUF_PTR_L),y ;set partition size to $3f blocks
         lda     #$02       ;sector 2
         ldy     #$0b
         sta     (BUF_PTR_L),y ;set starting sector to 2
         ldy     #$57
         lda     #$3f
         sta     (BUF_PTR_L),y ;set status of partition to $57
         rts

INIT_PM_SIZE:
         jsr     INIT_PM_SIG
         ldy     #$0c
         ldx     #$00
@psize_loop:
         lda     $c8d2,x    ;copy partition size into PM from $c8d2
         sta     (BUF_PTR_L),y
         iny
         inx
         cpx     #$04
         bne     @psize_loop
         lda     #$40
         ldy     #$0b
         sta     (BUF_PTR_L),y ;set PM partition start to block $40 (64)
         ldy     #$54
         ldx     #$00
@dsize_loop:
         lda     $c8d2,x    ;copy size of data from $c8d2
         sta     (BUF_PTR_L),y
         iny
         inx
         cpx     #$04
         bne     @dsize_loop
         rts

INIT_PM_SIG:
         lda     #$50       ;initialize partition map at BUF_PTR
         ldy     #$00       ;fill partition map signature at BUF_PTR
         sta     (BUF_PTR_L),y
         iny
         lda     #$4d
         sta     (BUF_PTR_L),y
         ldy     #$07
         lda     #$02       ;2 partitions
         sta     (BUF_PTR_L),y ;2 partiton in map
         lda     #$3f
         ldy     #$5b
         sta     (BUF_PTR_L),y ;part status 0x3f valid, allocated, boot info, in use, readable, writeble
         rts

FN_4F:   jsr     MON_SETVID ;print SCSI BOOT ERROR
         jsr     MON_SETKBD
         jsr     MON_SETTXT
         jsr     MON_HOME
         ldx     #$17
         stx     MON_CV
         ldx     #$00
         lda     @LCD0B,x
         tay
         inx
@LCCFD:  lda     @LCD0C,x
         jsr     MON_COUT   ;output a character
         inx
         dey
         bne     @LCCFD
         lda     #$70
         bne     CALL_FN_XF ;CALL_FN_70 RUN BASIC

@LCD0B:  .byte   $0d
@LCD0C:  .byte   $0f
         .byte   "SCSI BOOT ERROR"

CALL_FN_XF:
         ldx     #$0f
         ldy     SLOT_OFFSET
         jsr     BANKSWITCH
         rts

FN_5F:   lda     #$00       ;READ AND DISCARD DATA
         sta     REG_IO_5380_RST,y ;reset 5380
         tya
         tax
         lda     #$01
         sta     REG_5380_TCMD,x ;expect DATA IN
@more_discard_data:
         lda     REG_5380_DATA,x ;discard all read data
         lda     #$10
         sta     REG_5380_ICMD,x ;assert ACK
         lda     #$00       ;deassertion seems wrong (should wait for req to deassert first)
         sta     REG_5380_ICMD,x ;deassert ACK
         lda     REG_5380_STAT,x ;redundant?
         and     #$20
         lda     REG_5380_STAT,x
         and     #$1c
         beq     RESET_5380_ALT ;branch if DATA OUT
         jmp     @more_discard_data

RESET_5380_ALT:
         lda     #$00
         sta     REG_IO_5380_RST,y
         rts

FN_7F:   jsr     CHECK_DISK_CHANGE
         bcc     no_switch
         lda     #$0d
         jsr     CALL_FN_XF ;CALL_FN_0D - SEND INQUIRY and UPDATE DIBTAB entry
         lda     #$7a
         bne     LCD6D      ;CALL_FN_7A - copy DIBTAB from TMP_PTR to BUF_PTR

FN_6F:   jsr     CHECK_DISK_CHANGE
         bcc     no_switch
         lda     #$0d
         jsr     CALL_FN_XF ;CALL_FN_0D - SEND INQUIRY and UPDATE DIBTAB entry
         lda     #$8a       ;CALL_FN_8A - set DEV_STATUS, copy DIBTAB entry from *(TMP_PTR0-1) to *BUF_PTR
LCD6D:   jsr     CALL_FN_XF
no_switch:
         jsr     CPY_C916_BUF_PTR
         ldy     SLOT_OFFSET
         rts

CHECK_DISK_CHANGE:
         ldy     #$00
         jsr     IS_NATIVE_REQ
         bcc     @LCD82
         lda     [BUF_PTR_L],y
         bcs     @LCD84

@LCD82:  lda     (BUF_PTR_L),y
@LCD84:  sta     $c916      ;*$c916=DEV_STATUS from partial DIBTAB copy at *BUF_PTR
         and     #$01       ;open/disk switch flag
         beq     @no_disk_change ;branch if disk not switched
         lda     CALL_TYPE
         sta     $c918      ;save CALL_TYPE
         lda     BUF_PTR_L
         sta     $c9f7
         lda     BUF_PTR_H
         sta     $c9f8
         lda     BUF_PTR_VH
         sta     $c9f9
         lda     BUF_PTR_XH
         sta     $c9fa      ;save BUF_PTR
         lda     #$0c
         jsr     CALL_FN_XF ;CALL_FN_0C - Set new SDAT
         lda     $c918
         sta     CALL_TYPE  ;restore CALL_TYPE
         lda     $c9f7
         sta     BUF_PTR_L
         lda     $c9f8
         sta     BUF_PTR_H
         lda     $c9f9
         sta     BUF_PTR_VH
         lda     $c9fb
         sta     BUF_PTR_XH ;restore BUF_PTR
         sec
         rts

@no_disk_change:
         clc
         rts

CPY_C916_BUF_PTR:
         ldy     #$00       ;copy DEV_STATUS from $c916 to BUF_PTR[0]
         jsr     IS_NATIVE_REQ
         bcs     @cpy_c916_native
         lda     $c916
         sta     (BUF_PTR_L),y
         rts

@cpy_c916_native:
         lda     $c916
         clc
         xce
         sta     [BUF_PTR_L],y
         sec
         xce
         rts

IS_NATIVE_REQ:
         lda     CALL_TYPE
         and     #$40
         beq     @not_native
         lda     IS_IIgs
         bne     @native
@not_native:
         clc
         rts

@native: sec
         rts

FN_8F:   jsr     SET_TIMEOUT_FF
@FN_8F_loop:
         lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$0c
         beq     @FN_8F_get_status ;branch if STATUS phase
         jsr     CALL_FN_42 ;Decrement TIMEOUT3
         lda     TCOUNT_B2
         beq     @FN_8F_status_timeout
         bne     @FN_8F_loop

@FN_8F_get_status:
         lda     #$03
         jsr     READ_STATUS_MESSAGE_PHASE
@FN_8F_status_timeout:
         lda     #$00
         sta     TCOUNT_B2
FN_9F:   lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$1c
         beq     @FN_9F_get_message ;branch if MESSAGE IN phase
         dec     TCOUNT_B2
         beq     @FN_9F_timeout
         bne     FN_9F      ;message timeout loop

@FN_9F_get_message:
         lda     #$07
         jsr     READ_STATUS_MESSAGE_PHASE
         lda     #$00
         sta     REG_5380_ICMD,y ;release BUS
         sta     REG_IO_5380_RST,y ;reset 5380
@FN_9F_timeout:
         ldx     #$00
         ldy     #$00
@delay_loop:
         dex
         bne     @delay_loop
         dey
         bne     @delay_loop
         ldy     SLOT_OFFSET
         rts

READ_STATUS_MESSAGE_PHASE:
         sta     REG_5380_TCMD,y
         lda     #$04
         jmp     CALL_FN_XF ;CALL_FN_04

CALL_FN_42:
         lda     #$42       ;Decrement TIMEOUT3
         jmp     CALL_FN_XF ;CALL_FN_42

SET_TIMEOUT_FF:
         lda     #$ff
         sta     TCOUNT_B0
         sta     TCOUNT_B2
         rts

FN_AF:   lda     REG_5380_STAT,y ;attempt to clear SCSI phase errors
         beq     RESET_5380 ;branch if BUS free (what about parity?)
         cmp     #$bf       ;bug?
         beq     LCE79      ;branch if only BUSY is not asserted
         and     #$1c
         cmp     #$0c
         beq     FN_8F      ;branch to GET_STATUS_AND_MESSAGE if STATUS phase
         cmp     #$1c
         beq     FN_9F      ;branch to GET_MESSAGE if MESSAGE IN phase
         cmp     #$04
         bne     @FN_AF_skip_read ;branch if not DATA IN phase
         jsr     FN_5F      ;READ AND DISCARD DATA
@FN_AF_skip_read:
         lda     REG_5380_STAT,y
         and     #$5c
         cmp     #$40
         beq     CALL_FN_2C ;branch if DATA OUT and BUSY - write data until not busy
RESET_5380:
         lda     #$00
         sta     REG_IO_5380_RST,y
         rts

LCE79:   lda     BOOT_SEQ
         cmp     #$55
         bne     ERROR_NODRIVE ;branch if not in boot process
         lda     #$45
         jmp     CALL_FN_XF ;CALL_FN_45 - BOOT FAIL

ERROR_NODRIVE:
         sta     REG_IO_5380_RST,y
         lda     #$28       ;NODRIVE
         ldy     SLOT_OFFSET
         jmp     CALL_FN_60_RET

CALL_FN_2C:
         lda     #$2c       ;write data until not busy
         jmp     CALL_FN_XF ;CALL_FN_2C

FN_3F:   tsx
         stx     SAVE_SP2   ;save the original SP
         ldy     #$00
         txa
         cmp     #$60
         bcs     @stack_free ;branch if least $60 bytes free on the stack
         lda     #$b5
         jsr     CALL_FN_XF ;CALL_FN_B5 - DMA READ
         jmp     RET_00_SAVE_Y

@stack_free:
         sbc     #$17
         tax
         stx     TMP_PTR0   ;store SP-$17 to $19
         dex
         dex
         txs                ;SP=SP-$19
         inx
         inx
@copy_loop:
         lda     STACK_CODE,y ;the routine is copied to the stack to patch it
         sta     $0100,x    ;for IIgs operation. Not sure if this is really necessary
         inx                ;as it could be implemented as 2 different routines in ROM
         iny
         cpy     #$08       ;patch 9th byte if native
         bne     @skip_patch
         jsr     CHECK_NATIVE_REQUIRED
         bcs     @skip_patch
         lda     #$97       ;change LDA(),y (16-bit) to LDA[],y (24-bit)
         sta     $0100,x
         inx
         iny
@skip_patch:
         cpy     #$13       ;size of stack routine
         bne     @copy_loop
         ldx     SLOT_OFFSET
         lda     #$01
         sta     TMP_PTR0+1 ;store MSB of stack routine
         lda     SAVE_CYAREG
         ora     #$80
         sta     CYAREG     ;set IIgs fast mode
         ldy     #$00
         sty     TCOUNT_B0
         sty     TCOUNT_B1
         lda     #$02
         sta     TCOUNT_B2
         jsr     SET_NATIVE_IF_REQ
         jmp     (TMP_PTR0) ;jmp to stack routine

FN_3F_done:
         nop
         jsr     CHECK_NATIVE_REQUIRED
         bcs     @skip1
         sec                ;return to emulation mode
         xce
@skip1:  ldx     SAVE_SP2
         txs                ;restore sp
         lda     SAVE_CYAREG
         sta     CYAREG     ;restore original speed
RET_00_SAVE_Y:
         lda     #$00
         ldy     SLOT_OFFSET
         rts

STACK_CODE:
         lda     REG_IO_DRQ,x ;this code is copied to the stack
         bpl     @no_data   ;branch if DRQ not asserted
         lda     REG_IO_PDMA_DACK,x
         sta     (BUF_PTR_L),y
         iny
         bne     STACK_CODE
         jmp     @inc_ptr

@no_data:
         jmp     @check_timeout ;end of stack code

@check_timeout:
         dec     TCOUNT_B0
         bne     @check_phase
         dec     TCOUNT_B1
         beq     @ret_err_27 ;branch if timeout
@check_phase:
         lda     REG_5380_STAT2,x
         and     #$08
         beq     @ret_ok
         jmp     (TMP_PTR0) ;jump to stack routine

@inc_ptr:
         inc     BUF_PTR_H
         bne     @skip_vh
         inc     BUF_PTR_VH
@skip_vh:
         inc     TMP_c9f1+1
         lda     TMP_c9f1+1
         cmp     LDIO_SIZE+1
         beq     @ret_ok
         jmp     (TMP_PTR0) ;jump back to stack routine

@ret_err_27:
         lda     #$27
         sta     RET_CODE
         sty     TMP_c9f1
@ret_ok: jmp     FN_3F_done

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

SET_NATIVE_MODE:
         clc
         xce
         rts

         .byte   $38        ;SET_EMULATION_MODE seems dead code
         .byte   $fb
         .byte   $60

SET_NATIVE_IF_REQ:
         jsr     CHECK_NATIVE_REQUIRED
         bcs     @set_native_rts
         jsr     SET_NATIVE_MODE
@set_native_rts:
         rts

         .byte   $20
         .byte   $76
         .byte   $cf
         .byte   $b0
         .byte   $03
         .byte   $20
         .byte   $61
         .byte   $cf
         .byte   $60

CHECK_NATIVE_REQUIRED:
         lda     CALL_TYPE  ;C=0 if NATIVE
         and     #$40
         beq     @LCF86     ;not extended call
         lda     IS_IIgs
         cmp     #$01
         bne     @LCF86
         clc
         rts

@LCF86:  sec
         rts

FN_BF:   lda     #$ca
         sta     MEM_PTR_H
         sta     BUF_PTR_H
         lda     #$00
         sta     RET_CODE
         sta     MEM_PTR_L
         sta     BUF_PTR_L  ;TMP_PTR=$ca00; BUF_PTR=$ca00
         lda     #$9a
         jsr     CALL_FN_XF ;CALL_FN_9A - same as FN_2A
         lda     $ca00
         and     #$10
         beq     ERROR_2F   ;branch if device not online
         rts

ERROR_2F:
         lda     #$2f
         bne     CALL_FN_60_RET

CALL_FN_60_RET:
         sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH

FN_TABLE:
         .word   FN_0F
         .word   FN_1F
         .word   FN_2F
         .word   FN_3F
         .word   FN_4F      ;SCSI BOOT ERROR
         .word   FN_5F
         .word   FN_6F
         .word   FN_7F
         .word   FN_8F
         .word   FN_9F
         .word   FN_AF
         .word   FN_BF
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
