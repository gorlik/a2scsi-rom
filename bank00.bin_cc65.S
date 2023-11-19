; Target assembler: cc65 v2.18.0 [--target none -C bank00.bin_cc65.cfg]
; 6502bench SourceGen v1.1.0
         .setcpu "65816"
SCSI_CMD_READ6 = $08
SCSI_CMD_WRITE6 = $0a
P8E_WRITE_PROT = $2b        ;Disk write protected

TMP_PTR0 =       $19        ; temporary ZP pointer 
JMP_PTR  =       $1b        ; Jmp target ZP pointer 
PD_PAR_CMD =     $42        ;PRODOS input parameter COMMAND number
PD_PAR_BUF_LO =  $44        ;PRODOS input parameter Buffer lo address
PD_PAR_BUF_HI =  $45        ;PRODOS input parameter Buffer hi address
PD_PAR_BLK_LO =  $46        ;PRODOS input parameter Block lo
PD_PAR_BLK_HI =  $47        ;PRODOS input parameter Block hi
MEM_PTR_L =      $f6        ; temporary ZP long pointer
ACTV_PERIP_SLOT = $07f8     ;slot num ($Cn) of active peripheral card
REG_5380_DATA =  $c000      ; R current SCSI data lines status
REG_5380_DATA_OUT = $c000   ; W SCSI data output register
REG_5380_ICMD =  $c001      ; RW Initiator command register
REG_5380_MODE_SEL = $c002   ; RW Mode select register
REG_5380_TCMD =  $c003      ; RW target command register
REG_5380_SEL =   $c004      ; W Select enable register
REG_5380_STAT =  $c004      ; R SCSI status
REG_IO_DEV_ID =  $c009      ; R SCSI device ID
REG_IO_BANK_SEL = $c00a     ; W memory bank select
REG_IO_5380_RST = $c00b     ; W 5380 Reset
DEV_IDX  =       $c800      ; index into the SDAT/DIBTAB tables
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B2 =      $c802      ; timeout counter MSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
SEL_TARGET =     $c806      ; SCSI (BUS?) ID of selected target
INIT_FLAG =      $c809      ; card initialized flag (init=$77)
RET_CODE =       $c80b      ; 
BSW_TEMP =       $c80c      ; TEMP in BANKSWITCH
SCSI_CMD_LEN =   $c80d      ; SCSI COMMAND lenght
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SCSI_CDB_LUN =   $c80f      ; 
SCSI_CDB_LBA_HI = $c810
SCSI_CDB_LBA_LO = $c811
SCSI_CDB_LEN =   $c812
SCSI_CDB_CTRL =  $c813
SLOT_OFFSET =    $c81a      ; slot adress (n+8)<<4 
SAVE_SP_CMD =    $c81b      ; saved SmartPort Command
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
CMD_STATUS =     $c81e      ; SCSI CMD status - 0x00 OK, 0x02 Check condition
SCSI_RD_c81f =   $c81f      ; SCSI STATUS or MESSAGE return from FN_04 
SAVE_ENTRY_SP =  $c821      ; stack pointer saved at the PD/SM entry point
UNK_c827 =       $c827      ; 3-byte unknown in reverse endian as the above
SAVE_ZP_F6 =     $c8a8      ;saved zero page locations $f6-$fd
SAVE_ZP_15 =     $c8b0      ;saved zero page locations $15-$1e
PD_PAR_CMD_CPY = $c8bc      ;PRODOS input parameter COMMAND number
LBA      =       $c8db      ; LBA to read/write (little endian - adjusted for PART_START) to use in CDB (gets copied to CDB_LBA)
BOOT_SEQ =       $c8e3      ; $55 if in boot process
RX_LEN_LO =      $c8e4      ; bytes read if call successfull
RX_LEN_HI =      $c8e5      ; bytes read if call successfull
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB
TIMEOUT  =       $c9f6      ; each unit is 1.25s
CLRROM   =       $cfff      ;disable slot C8 ROM
MON_SLOOP =      $faba

         .org    $cc00
         .byte   $a2
         .byte   $20        ;PRODOS block device signature
         .byte   $a2
         .byte   $00        ;PRODOS block device signature
         .byte   $a2
         .byte   $03        ;PRODOS block device signature
         .byte   $a2
         .byte   $00        ;SmartPort Signature byte

         .a8
         .i8
         lda     CLRROM     ;Boot code
         cld
         php
         sei                ;this fragment retrieves the slot number
         lda     #$60       ;opcode for RTS
         sta     ACTV_PERIP_SLOT
         jsr     ACTV_PERIP_SLOT
         tsx
         lda     $0100,x    ;retrieve the Cn slot number from the stack
         sta     ACTV_PERIP_SLOT ;store $Cn slot address
         plp                ;restore interrupt
         lda     CLRROM
         lda     ACTV_PERIP_SLOT
         sta     TMP_PTR0+1
         lda     #$00
         sta     TMP_PTR0   ;$19, $1A contain $Cn00
         tay
         lda     (TMP_PTR0),y ;enable card ROM (read from $Cn00)
         ldy     #$0a
         lda     #$00
         sta     (TMP_PTR0),y ;write $00 to $Cn0A - likely a bug as the bank register is $C0nA
         lda     #$55
         sta     BOOT_SEQ
         lda     ACTV_PERIP_SLOT
         and     #$0f
         clc
         adc     #$08
         asl     A
         asl     A
         asl     A
         asl     A          ;A=(n+8)<<4
         sta     SLOT_OFFSET ;slot offset in C0xx space
         tay
         ldx     #$00
         lda     #$05
         jsr     BANKSWITCH ;CALL_FN_05 (card init)
         lda     #$01
         sta     CALL_TYPE
         sta     DEV_IDX
         jsr     CALL_FN_75 ;TMP_PTR0=&SDAT[DEV_IDX], BLK_COUNT=SDAT[DEV_IDX].blk_count, save CYAREG
         jmp     LOAD_BLOCK_0

ENTRY_PRODOS:
         clc                ;PRODOS call entry point
         bcc     skip_sp

ENTRY_SMP:
         sec                ;Smartport call entry point
skip_sp: cld
         php                ;save flags to remember if call is prodos/smartport & interrup status
         sei
         lda     #$60       ;opcode for RTS
         sta     ACTV_PERIP_SLOT
         jsr     ACTV_PERIP_SLOT
         tsx
         lda     $0100,x
         sta     ACTV_PERIP_SLOT ;store $Cn slot address
         and     #$0f
         clc
         adc     #$08
         asl     A
         asl     A
         asl     A
         asl     A
         pha                ;push (n+8)<<4
         lda     TMP_PTR0
         pha
         lda     TMP_PTR0+1
         pha                ;save $19 and $1A
         lda     CLRROM
         lda     ACTV_PERIP_SLOT ;A=$Cn
         sta     TMP_PTR0+1
         lda     #$00
         sta     TMP_PTR0   ;TMP_PTR0 contain $Cn00
         sta     BOOT_SEQ   ;clear $C8E3
         tay
         lda     (TMP_PTR0),y ;enable card ROM (read from $Cn00)
         ldy     #$0a
         lda     #$00
         sta     (TMP_PTR0),y ;write $00 to $Cn0A - likely a bug as the bank register is $C0nA
         pla
         sta     TMP_PTR0+1
         pla
         sta     TMP_PTR0   ;restore $19 and $1A
         pla
         tay                ;Y=(n+8)<<4
         sty     SLOT_OFFSET
         tsx
         stx     SAVE_ENTRY_SP
         jsr     SAVE_ZP_COPY_PARAM
         plp                ;restore interrupts
         bcc     @prodos_path
         ldx     #$00       ;smartport path
         lda     #$02
         jsr     BANKSWITCH ;CALL_FN_02 - process Smartport Command
         jsr     CALL_FN_12 ;Restore ZP and return
         ldx     RX_LEN_LO
         ldy     RX_LEN_HI
         jmp     ret_ok

@prodos_path:
         lda     #$01
         sta     CALL_TYPE
         lda     INIT_FLAG  ;check if card is initialized
         cmp     #$77
         beq     @init_set
         lda     #$05
         jsr     CALL_FN_X0 ;CALL_FN_05 - init card
@init_set:
         jsr     CALL_FN_25 ;DEV_IDX=PD_UNIT, TMP_PTR0=&SDAT[DEV_IDX], BLK_COUNT=SDAT[DEV_IDX].blk_count
         lda     #$15
         jsr     CALL_FN_X0 ;CALL_FN_15 - get info from SDAT[DEV_IDX], BLK_NUMBER+=PART_START, memcpy($ca00,DIBTAB[DEV_IDX])
         lda     PD_PAR_CMD
         bne     @cmd_not_0
@cmd_0:  jmp     PRODOS_STATUS ;PRODOS CMD 0: STATUS 

@cmd_not_0:
         cmp     #$01
         bne     @cmd_not_01
         jmp     FN_90      ;PRODOS CMD 1: READ BLK

@cmd_not_01:
         cmp     #$02
         bne     @cmd_not_012
         jmp     PRODOS_WRITE ;PRODOS CMD 2: WRITE BLK

@cmd_not_012:
         cmp     #$03
         bne     @cmd_0
         jmp     PRODOS_FORMAT ;PRODOS CMD 3: FORMAT

         .byte   $55
         .byte   $55
         .byte   $55
         .byte   $82        ;SMARTPORT ID type SCSI + support for extended calls
         .word   $0000      ;PRODOS Device Size
         .byte   $1f        ;PRODOS Device Status
@PRODOS_ENTRY_ADDR:
         .byte   <ENTRY_PRODOS ;LSB of the PRODOS entry point (MUST be at $CCFF)

FN_90:   jsr     CALL_FN_3A_DUP ;PRODOS Read
         jsr     SCSI_READ_CMD
FN_10:   jsr     FN_00      ;EXEC SCSI DATA_IN
FN_40:   lda     REG_5380_STAT,y ;DATA READ - Xin + DoStatus
         and     #$1c       ;MSG_IO_CD_MASK
         cmp     #$04       ;data in Phase
         beq     @Read_data ;branch if DATA IN phase
         lda     REG_5380_STAT,y
         cmp     #$6c
         beq     @FN_40_end ;branch if STATUS phase
         jsr     CALL_FN_42 ;decrement TIMEOUT
         lda     TCOUNT_B2
         beq     @FN_40_end
         bne     FN_40

@Read_data:
         lda     #$01
         jsr     CALL_FN_X0 ;CALL_FN_01 - Data Xin - data read to BUF_PTR
@FN_40_end:
         jsr     FN_A0      ;get STATUS and MESSAGE IN
         jmp     CMD_end

FN_A0:   jsr     SET_TIMEOUT ;DoStatusTimeout
FN_30:   lda     REG_5380_STAT,y ;DoStatus
         and     #$1c
         cmp     #$0c
         beq     @FN_30_read_status ;detected STATUS phase
         cmp     #$1c
         beq     @FN_30_read_message ;detected MESSAGE IN phase
         jsr     CALL_FN_42 ;decrement TIMEOUT3
         lda     TCOUNT_B2
         beq     @FN_30_status_timeout
         bne     FN_30

@FN_30_read_status:
         lda     #$03       ;set expectation for STATUS phase
         jsr     CALL_FN_04_PHASE_RET ;read status and save it to CMD_STATUS
@FN_30_status_timeout:
         lda     #$00
         sta     TCOUNT_B2
@FN_30_msg_loop:
         lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$1c
         beq     @FN_30_read_message ;detected MESSAGE IN phase
         dec     TCOUNT_B2
         beq     @FN_30_end
         bne     @FN_30_msg_loop

@FN_30_read_message:
         lda     #$07       ;set expectation for MESSAGE IN phase
         jsr     CALL_FN_04_PHASE
         lda     #$00
         sta     REG_5380_ICMD,y
         sta     REG_IO_5380_RST,y
@FN_30_end:
         ldy     SLOT_OFFSET
         rts

CALL_FN_3A_DUP:
         lda     #$3a       ;BUS_FREE
         jmp     CALL_FN_X0 ;CALL_FN_3A_DUP

CALL_FN_42:
         lda     #$42
         jmp     CALL_FN_X0 ;Decrement TIMEOUT3

PRODOS_WRITE:
         lda     DEV_STATUS
         cmp     #$b4
         beq     ERROR_NOWRITE
         jsr     CALL_FN_3A_DUP ;BUS_FREE
         jsr     SCSI_WRITE_CMD
FN_20:   jsr     FN_00      ;EXECUTE SCSI DATA send COMMAND
FN_50:   lda     #$11       ;DATA WRITE (without DoPhases)
         jsr     CALL_FN_X0 ;CALL_FN_11 (Data Xout)
         jsr     FN_A0      ;get STATUS and MESSAGE
         jmp     CMD_end

ERROR_NOWRITE:
         lda     #P8E_WRITE_PROT
         sta     RET_CODE
         jmp     FN_60

FN_00:   jsr     CALL_FN_3A ;DoPhases (busfree + DoPhasesNF)
FN_B0:   jsr     SCSI_ARBITRATE ;DoPhasesNF (dophases without busfree)
         jsr     SCSI_SELECT
         jsr     CALL_FN_14 ;Send SCSI CMD
SET_TIMEOUT:
         lda     #$ff
         sta     TCOUNT_B0
         sta     TCOUNT_B1
         lda     TIMEOUT
         sta     TCOUNT_B2
         rts

PRODOS_STATUS:
         lda     #$25
         jsr     CALL_FN_X0 ;CALL_FN_25
         lda     #$1d
         jsr     CALL_FN_X0 ;CALL_FN_1D
         jsr     CALL_FN_12 ;restore ZP and return
         ldy     UNK_c827+1
         ldx     UNK_c827+2
ret_ok:  lda     #$00
         clc
         rts

PRODOS_FORMAT:
         lda     #$06
         jsr     CALL_FN_X0 ;CALL_FN_06
CMD_end: lda     PD_PAR_BUF_HI
         cmp     #$08       ;trying to detect boot ???
         beq     RESTORE_ZP_RET ;branch if PD_BUF_H==$08
         lda     INIT_FLAG
         cmp     #$77
         bne     RESTORE_ZP_RET ;branch if not init (also during boot)
         lda     RET_CODE
         bne     scsi_cmd_end ;branch if RET_CODE!=0
RESTORE_ZP_RET:
         jsr     CALL_FN_12 ;restore ZP and return
         lda     #$00
         clc
         rts

scsi_cmd_end:
         lda     SCSI_CDB_CMD
         beq     RESTORE_ZP_RET ;end if SCSI CMD==TEST_UNIT_READY
         lda     SAVE_SP_CMD
         cmp     #$04       ;smartport CMD Control
         beq     RESTORE_ZP_RET ;end if smartport CMD==Control
         lda     RET_CODE
         cmp     #$02
         beq     CALL_FN_16_and_end
         jmp     FN_60      ;PD cmd exit fail

CALL_FN_16_and_end:
         lda     #$16
         jsr     CALL_FN_X0 ;CALL_FN_16
         jmp     RESTORE_ZP_RET

SCSI_READ_CMD:
         jsr     CALL_FN_84 ;copy PD_PAR_BUF into BUF_PTR
         lda     #SCSI_CMD_READ6 ;SCSI CMD READ6
         bne     scsi_rw

SCSI_WRITE_CMD:
         jsr     CALL_FN_84 ;copy PD_PAR_BUF into BUF_PTR
         lda     #SCSI_CMD_WRITE6 ;SCSI CMD WRITE6
         bne     scsi_rw

scsi_rw: sta     SCSI_CDB_CMD ;create a r/w SCSI CDB from the PD input paramteres
         lda     #$06
         sta     SCSI_CMD_LEN
         lda     LBA+2
         sta     SCSI_CDB_LUN
         lda     PD_PAR_BLK_HI
         sta     SCSI_CDB_LBA_HI
         lda     PD_PAR_BLK_LO
         sta     SCSI_CDB_LBA_LO
         lda     #$01       ;transfer 1 block
         sta     SCSI_CDB_LEN
         lda     #$00
         sta     SCSI_CDB_CTRL
         rts

CALL_FN_84:
         lda     #$84       ;copy PD_PAR_BUF into BUF_PTR
         jmp     CALL_FN_X0

LOAD_BLOCK_0:
         lda     #$01       ;build a PRODOS CMD buffer
         sta     PD_PAR_CMD ;PRODOS READ CMD
         sta     CALL_TYPE  ;PRODOS CALL TYPE
         lda     #$00
         sta     PD_PAR_BLK_LO
         sta     PD_PAR_BLK_HI ;load block 0
         lda     #$15
         jsr     CALL_FN_X0 ;CALL_FN_15 - get info from SDAT[DEV_IDX], BLK_NUMBER+=PART_START, memcpy($ca00,DIBTAB[DEV_IDX])
         lda     #$08
         sta     PD_PAR_BUF_HI
         lda     #$00
         sta     PD_PAR_BUF_LO ;load block at $0800
         lda     #$55
         sta     BOOT_SEQ
         jsr     FN_90      ;PRODOS READ_BLK
         ldx     $0801
         beq     @CALL_FN_45 ;branch if not bootable
         ldx     $0800
         cpx     #$01
         bne     @CALL_FN_45 ;branch if not bootable
         stx     BOOT_SEQ
         lda     SLOT_OFFSET
         and     #$70
         tax
         jmp     $0801      ;jump to bootblock entry point

@CALL_FN_45:
         lda     #$45
         bne     CALL_FN_X0 ;CALL_FN_45 - next boot device or error if last

CALL_FN_75:
         lda     #$75
         bne     CALL_FN_X0 ;CALL_FN_75 - TMP_PTR0=&SDAT[DEV_IDX], BLK_COUNT=SDAT[DEV_IDX].blk_count

CALL_FN_25:
         lda     #$25       ;DEV_IDX=PD_UNIT, TMP_PTR0=&SDAT[DEV_IDX], BLK_COUNT=SDAT[DEV_IDX].blk_count
CALL_FN_X0:
         ldx     #$00
         jmp     BANKSWITCH ;CALL_FN_X0

CALL_FN_3A:
         lda     #$3a
         bne     CALL_FN_X0 ;CALL_FN_3A - BUS_FREE

SCSI_ARBITRATE:
         lda     REG_5380_MODE_SEL,y
         and     #$fe
         sta     REG_5380_MODE_SEL,y ;reset arbitrate bit
         lda     REG_IO_DEV_ID,y
         sta     REG_5380_DATA_OUT,y ;put scsi id on the bus
         lda     REG_5380_MODE_SEL,y
         ora     #$01
         sta     REG_5380_MODE_SEL,y ;set the arbitrate bit
         lda     REG_5380_ICMD,y ;Check the lost arbitration bit
         and     #$20
         bne     SCSI_ARBITRATE ;lost SCSI arbitration, try again
         lda     REG_5380_DATA,y
         sec
         sbc     REG_IO_DEV_ID,y
         beq     @arb_win   ;only this devce tried to arbitrate
         sec                ;multiple devices arbitrate
         sbc     REG_IO_DEV_ID,y ;check if this device is the highest priority
         bmi     @arb_win   ;bug (?) still fall through
@arb_win:
         lda     REG_5380_ICMD,y ;Check the lost arbitration bit again (?)
         and     #$20
         bne     SCSI_ARBITRATE ;lost SCSI arbitration, try again
         rts

SCSI_SELECT:
         lda     #$04
         nop
         sta     REG_5380_ICMD,y ;assert busy
         nop
         lda     REG_IO_DEV_ID,y ;get conroller SCSI ID
         ora     SEL_TARGET
         sta     REG_5380_DATA_OUT,y ;put SCSI ID on the BUS
         lda     #$0d
         sta     REG_5380_ICMD,y ;assert BUSY, SELECT and enable DATA bus buffers
         lda     #$00
         sta     REG_5380_MODE_SEL,y ;no parity, initiator mode, no interrupts, no arbitration
         lda     #$00
         sta     REG_5380_SEL,y ;no interrupt on SEL
         lda     #$05
         sta     REG_5380_ICMD,y ;deassert BUSY (SEL and DATA buffers on)
         ldx     #$ff
         stx     TCOUNT_B0
@retry_not_busy:
         jsr     @WAIT_NOT_BUSY
         bcc     @end_sel
         dec     TCOUNT_B0
         bne     @retry_not_busy
         lda     BOOT_SEQ
         cmp     #$55
         beq     @end_sel
         lda     #$27
         sta     RET_CODE
@end_sel:
         lda     #$00
         sta     REG_5380_ICMD,y ;deassert SEL and disable DATA buffers
         clc
         rts

         .byte   $a2        ;unreachable code (copies of WAIT_NOT_BUSY)
         .byte   $00
         .byte   $ca
         .byte   $f0
         .byte   $41
         .byte   $b9
         .byte   $01
         .byte   $c0
         .byte   $29
         .byte   $40
         .byte   $d0
         .byte   $f6
         .byte   $18
         .byte   $60
         .byte   $a2
         .byte   $00
         .byte   $ca
         .byte   $f0
         .byte   $33
         .byte   $b9
         .byte   $01
         .byte   $c0
         .byte   $29
         .byte   $40
         .byte   $f0
         .byte   $f6
         .byte   $18
         .byte   $60

@WAIT_NOT_BUSY:
         ldx     #$00
@bus_busy:
         dex
         beq     @ret_fail
         lda     REG_5380_STAT,y
         and     #$40
         beq     @bus_busy
         clc
         rts

         .byte   $a2        ;unreachable code
         .byte   $ff
         .byte   $ca
         .byte   $f0
         .byte   $17
         .byte   $b9
         .byte   $04
         .byte   $c0
         .byte   $29
         .byte   $20
         .byte   $d0
         .byte   $f6
         .byte   $18
         .byte   $60
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

@ret_fail:
         sec
         rts

CALL_FN_14:
         lda     #$14
         jmp     CALL_FN_X0 ;CALL_FN_14 - send SCSI CMD from buf at $c80e

CALL_FN_04_PHASE_RET:
         sta     REG_5380_TCMD,y
         lda     #$04
         jsr     CALL_FN_X0 ;CALL_FN_04 read STAUS or MESSAGE
         lda     SCSI_RD_c81f
         sta     CMD_STATUS
         sta     RET_CODE
         rts

CALL_FN_04_PHASE:
         sta     REG_5380_TCMD,y
         lda     #$04
         jmp     CALL_FN_X0 ;CALL_FN_04 read STATUS or MESSAGE

CALL_FN_12:
         lda     #$12       ;restore ZP and return
         jmp     CALL_FN_X0 ;CALL_FN_12

SAVE_ZP_COPY_PARAM:
         ldx     #$07
@cpy_loop1:
         lda     MEM_PTR_L,x ;copy from $F6-$FD to $C8A8-C8AF
         sta     SAVE_ZP_F6,x
         lda     $15,x
         sta     SAVE_ZP_15,x ;copy from $15-$1C to $C8B0-C8B7
         lda     PD_PAR_CMD,x
         sta     PD_PAR_CMD_CPY,x ;copy from $42-$49 (PD input param) to $C8BC-C8C3 
         dex
         bpl     @cpy_loop1
         ldx     #$0a
@cpy_loop2:
         lda     $15,x
         sta     SAVE_ZP_15,x ;copy from $1D-$1F to $C8B8-C8BA
         dex
         cpx     #$07
         bne     @cpy_loop2
         rts

FN_70:   jmp     $e000      ;RUN BASIC

FN_80:   jmp     MON_SLOOP  ;next boot device

FN_60:   jsr     CALL_FN_12 ;Restore ZP and return
         sta     REG_IO_5380_RST,y ;Reset 5380
         ldx     SAVE_ENTRY_SP
         inx
         txs                ;restore SP
         ldy     RX_LEN_HI  ;setting x and y is likely unecessary as the call failed
         ldx     RX_LEN_LO
         lda     RET_CODE
         sec
         rts

FN_TABLE:
         .word   FN_00
         .word   FN_10
         .word   FN_20
         .word   FN_30      ;Get Status and message with external timeout
         .word   FN_40
         .word   FN_50
         .word   FN_60      ;Smartport Return Fail
         .word   FN_70      ;RUN BASIC
         .word   FN_80      ;jmp SLOOP (next boot device)
         .word   FN_90
         .word   FN_A0      ;Get status and Message with setting timeout
         .word   FN_B0

         .org    $cfcc
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
         jsr     @DO_CALL_FN
         pla
         and     #$0f
         sta     REG_IO_BANK_SEL,y
         clc
         rts

@DO_CALL_FN:
         jmp     (JMP_PTR)

         .byte   $02
         .byte   $31
         .byte   $34
         .byte   $30
