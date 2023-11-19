; Target assembler: cc65 v2.18.0 [--target none -C bank02.bin_cc65.cfg]
; 6502bench SourceGen v1.7.3
         .setcpu "65816"
SCSI_CMD_READ6 = $08
SCSI_CMD_WRITE6 = $0a
P8E_WRITE_PROT = $2b        ;Disk write protected

TMP_PTR0 =       $19        ; temporary ZP pointer 
JMP_PTR  =       $1b        ; Jmp target ZP pointer 
TMP_PTR2 =       $1d        ; temporary ZP pointer 
PD_PAR_UNIT =    $43        ;PRODOS input parameter UNIT number
MEM_PTR_L =      $f6        ; temporary ZP long pointer
MEM_PTR_H =      $f7
MEM_PTR_VH =     $f8
MEM_PTR_XH =     $f9
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
BUF_PTR_XH =     $fd
REG_5380_STAT =  $c004      ; R SCSI status
REG_IO_BANK_SEL = $c00a     ; W memory bank select
REG_IO_5380_RST = $c00b     ; W 5380 Reset
DEV_IDX  =       $c800      ; index into the SDAT/DIBTAB tables
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B2 =      $c802      ; timeout counter MSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
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
SAVE_ENTRY_SP =  $c821      ; stack pointer saved at the PD/SM entry point
PART_START =     $c824      ; partition start (3 bytes - reverse endian)
SDAT     =       $c831      ;start of SDAT table (extends to $C8A7)
LBA      =       $c8db      ; LBA to read/write (little endian - adjusted for PART_START) to use in CDB (gets copied to CDB_LBA)
RX_LEN_LO =      $c8e4      ; bytes read if call successfull
RX_LEN_HI =      $c8e5      ; bytes read if call successfull
SAVE_SP_CMD_TEMP = $c8e6    ; saved Smartport COMMAND number
SAVE_SP_UNIT =   $c8e8      ; saved Smartport UNIT number
IS_IIgs  =       $c8f3      ;0x01 if IIgs
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB
LDIO_SIZE_HI =   $c9ff

         .org    $cc00
         .a8
         .i8
FN_02:   tsx                ;main smartport entry
         txa
         clc
         adc     #$06       ;stack offset for address of SP inline parameters
         tax                ;should be 5 for 3 JSR but likely there is an extra push
         lda     $0100,x
         sta     TMP_PTR2
         inx
         inc     TMP_PTR2
         lda     $0100,x
         sta     TMP_PTR2+1
         lda     TMP_PTR2
         bne     @skip_inc
         inc     TMP_PTR2+1 ;add 1 to LSB to compensate for return address-1 of the JSR
@skip_inc:
         ldy     #$00
         sty     RET_CODE
         lda     (TMP_PTR2),y
         sta     SAVE_SP_CMD
         iny
         lda     (TMP_PTR2),y
         sta     MEM_PTR_L
         iny
         lda     (TMP_PTR2),y
         sta     MEM_PTR_H  ;TMP_PTR2=smartport inline paramters
         ldx     SAVE_ENTRY_SP
         lda     SAVE_SP_CMD
         and     #$40
         sta     CALL_TYPE  ;set call type to 0x40 if extended call
         beq     @std_call
         iny
         lda     (TMP_PTR2),y
         sta     MEM_PTR_VH ;copy byte 2 of smartport parameter address to TMP_PTR2
         ldx     IS_IIgs
         cpx     #$00
         bne     @ext_call
         cmp     #$00
         bne     ERROR_BADCTRLPARM ;error if address 16..23 is not 0 and not IIgs
@ext_call:
         iny
         lda     (TMP_PTR2),y
         sta     MEM_PTR_XH ;copy byte 3 of smartport parameter address to TMP_PTR2
@std_call:
         lda     SAVE_SP_CMD
         and     #$0f
         sta     SAVE_SP_CMD ;remove extended flag from saved CMD number
         ldx     SAVE_ENTRY_SP
         txa
         clc
         adc     #$02       ;this is plus 2 becasue ENTRY_SP is saved before the PHP (should be +1)
         tax
         lda     CALL_TYPE
         and     #$40
         bne     @ext_call_fix
         lda     $0100,x
         clc
         adc     #$03       ;add 3 to the ret address for std calls
         sta     $0100,x
         bcc     @done_fixing
@call_fix_msb:
         inx
         lda     $0100,x
         clc
         adc     #$01
         sta     $0100,x
         bcc     @done_fixing
@ext_call_fix:
         lda     $0100,x
         clc
         adc     #$05
         sta     $0100,x    ;add 5 to return address for ext calls
         bcs     @call_fix_msb
@done_fixing:
         ldx     SAVE_SP_CMD ;redundant
         cpx     #$40       ;ext_flag has already been stripped from SAVE_SP_CMD_B
         bcs     ERROR_BADCTRLPARM ;never taken
         lda     CALL_TYPE
         and     #$40
         beq     @not_ext
         lda     IS_IIgs
         beq     @not_ext
         jmp     LDA_TMP_PTR_NATIVE_1

@not_ext:
         ldy     #$00
         cpx     #$04
         beq     param_count_ok ;bug?? - skip parameter count check if CMD==CONTROL ($04)
         lda     (MEM_PTR_L),y
         cmp     CMD_PARAM_COUNT_TABLE,x
         beq     param_count_ok ;branch if parameter count matches expectations
ERROR_BADCTRLPARM:
         lda     #$22
         jmp     CALL_FN_60_RETY_ALT ;ERROR_BADCTRLPARAM

param_count_ok:
         iny
         lda     (MEM_PTR_L),y
got_dev_idx:
         sta     DEV_IDX
         sta     SAVE_SP_UNIT
         cmp     #$08
         bcs     ERROR_BADUNIT ;branch if unit number > 8
         cpx     #$00
         beq     SP_unit_valid ;branch if Smartport CMD == $00 (Status)
         cpx     #$05
         beq     SP_unit_valid ;branch if Smartport CMD == $05 (Init)
         cmp     #$00
         bne     SP_unit_valid ;branch if unit number != 0
ERROR_BADUNIT:
         lda     #$11
         jmp     CALL_FN_60_RETY_ALT ;ERROR_BADUNIT

SP_unit_valid:
         sta     PD_PAR_UNIT
         stx     SAVE_SP_CMD_TEMP
         ldy     SLOT_OFFSET
         lda     REG_5380_STAT,y
         cmp     #$bf       ;?????
         bne     @LCCF0
         lda     SAVE_SP_CMD
         bne     @LCCF0     ;branch if CMD !=0
         lda     DEV_IDX
         bne     @LCCF0     ;branch if DEV_IDX!=0
         lda     CALL_TYPE
         beq     @LCD1E
         cmp     #$40
         beq     @LCD1E
@LCCF0:  lda     INIT_FLAG
         cmp     #$77
         beq     @init_done
         lda     MEM_PTR_L
         jsr     SAVE_TMP_PTR_IDX
         lda     #$05
         jsr     CALL_FN_X2 ;CALL_FN_05 - Init card
         jsr     RESTORE_TMP_PTR_IDX
@init_done:
         lda     DEV_IDX
         bne     @dev_not_0 ;branch if DEV_IDX!=0
         jsr     SET_PTR0_SDAT_BASE
         lda     #$85
         jsr     CALL_FN_X2 ;CALL_FN_85 - Set BLK COUNT from SDAT
         jmp     @dev_equ_0

@dev_not_0:
         lda     #$75
         jsr     CALL_FN_X2 ;CALL_FN_75 - TMP_PTR0=&SDAT[DEV_IDX], set BLK_COUNT
@dev_equ_0:
         lda     #$15
         jsr     CALL_FN_X2 ;CALL_FN_15 - FN_35, FN_1C, FN_6A - load info from SDAT[DEV_IDX], BLK_NUMBER+=PART_START
@LCD1E:  ldx     SAVE_SP_CMD_TEMP
         lda     SP_CMD_TABLE_H,x
         sta     TMP_PTR2+1
         lda     SP_CMD_TABLE_L,x
         sta     TMP_PTR2
         jmp     (TMP_PTR2)

CALL_FN_60_RETY_ALT:
         sta     RET_CODE   ;seems redundant as CALL_FN_60_RET saves RET_CODE
CALL_FN_60_RETY:
         ldy     SLOT_OFFSET
         jmp     CALL_FN_60_RET

LDA_TMP_PTR_NATIVE_1:
         clc                ;SET NATIVE mode
         xce
         ldy     #$01
         lda     [MEM_PTR_L],y
         sta     DEV_IDX
         sec                ;Go back to EMULATION mode
         xce
         lda     DEV_IDX
         jmp     got_dev_idx

SET_PTR0_SDAT_BASE:
         lda     #<SDAT
         sta     TMP_PTR0
         lda     #>SDAT
         sta     TMP_PTR0+1 ;TMP_PTR0=SDAT_BASE
         rts

SAVE_TMP_PTR_IDX:
         lda     MEM_PTR_L
         sta     $c8e9
         lda     MEM_PTR_H
         sta     $c8ea
         lda     DEV_IDX
         sta     LDIO_SIZE_HI-1
         rts

RESTORE_TMP_PTR_IDX:
         lda     $c8e9
         sta     MEM_PTR_L
         lda     $c8ea
         sta     MEM_PTR_H
         lda     LDIO_SIZE_HI-1
         sta     DEV_IDX
         rts

CTRL_CODE_TABLE_L:
         .byte   <SP_DEVICE_RESET ;$00 - DeviceReset
         .byte   <ERROR_BADCTL_ALT ;$01 - Reserved
         .byte   <ERROR_BADCTL_ALT ;$02 - Reserved
         .byte   <ERROR_BADCTL_ALT ;$03 - Reserved
         .byte   <CALL_FN_2E ;$04 - Eject (SCSI $C0)
         .byte   <CALL_FN_A3 ;$05 - TestUnit Ready (SCSI $00)
         .byte   <CALL_FN_B3 ;$06 - RequestSense (SCSI $03)
         .byte   <CALL_FN_03 ;$07 - ReassignBlocks (SCSI $07)
         .byte   <CALL_FN_5A ;$08 - ModeSelect (SCSI $15)
         .byte   <CALL_FN_23 ;$09 - ModeSense (SCSI $1A)
         .byte   <CALL_FN_33 ;$0A - Reserve (SCSI $16)
         .byte   <CALL_FN_43 ;$0B - Release (SCSI $17)
         .byte   <CALL_FN_53 ;$0C - ReadDefectData (SCSI $37 ???)
         .byte   <CALL_FN_C3 ;$0D - ReadCapacity (SCSI $25)
         .byte   <CALL_FN_63 ;$0E - SendDiagnostic (SCSI $1D)
         .byte   <CALL_FN_93 ;$0F - Inquiry (SCSI $12)
         .byte   <ERROR_BADCTL ;$10 - not supported
         .byte   <ERROR_BADCTL ;$11 - not supported
         .byte   <CALL_FN_E3 ;$12 - HardReset
         .byte   <CALL_FN_4A ;$13 - SetBlockSize
         .byte   <CALL_FN_1B ;$14 - SetTimeout
         .byte   <CALL_FN_D3 ;$15 - FormatUnit (SCSI $04)
         .byte   <CALL_FN_5B ;$16 - ExtendedSeek (SCSI $2B)
         .byte   <ERROR_BADCTL ;$17 - ReceiveDiagnostic (SCSI $1C) - documented in the TRM as supported - bug ???
         .byte   <CALL_FN_5B ;$18 - StartUnit (SCSI $18)
         .byte   <CALL_FN_5B ;$19 - StopUnit (SCSI $19)
         .byte   <CALL_FN_5B ;$1A - PreventRemoval (SCSI $1E)
         .byte   <CALL_FN_5B ;$1B - AllowRemoval (SCSI $1E)
         .byte   <CALL_FN_5B ;$1C - Verify (SCSI $2F)
         .byte   <CALL_FN_5B ;$1D - RezeroUnit (SCSI $01)
         .byte   <CALL_FN_5B ;$1E - Patch1Call
         .byte   <CALL_FN_0C ;$1F - SetNewSDAT
         .byte   <CALL_FN_1E ;$20 - AudioSearch (SCSI $C8)
         .byte   <CALL_FN_1E ;$21 - AudioPlay (SCSI $C9)
         .byte   <CALL_FN_1E ;$22 - AudioPause (SCSI $CA)
         .byte   <CALL_FN_1E ;$23 - unknown
         .byte   <CALL_FN_1E ;$24 - AudioStatus (SCSI $CC)
         .byte   <CALL_FN_1E ;$25 - AudioScan (SCSI $CD)
         .byte   <CALL_FN_1E ;$26 - Eject (SCSI $C0)
         .byte   <CALL_FN_1E ;$27 - ReadTOC (SCSI $C1)
         .byte   <CALL_FN_1E ;$28 - ReadQSubcode (SCSI $C2)
         .byte   <CALL_FN_1E ;$29 - ReadHeader (SCSI $C3)
         .byte   <CALL_FN_1E ;$2A - SetInterleave (SCSI $04)
CTRL_CODE_TABLE1_H:
         .byte   >SP_DEVICE_RESET
         .byte   >ERROR_BADCTL_ALT
         .byte   >ERROR_BADCTL_ALT
         .byte   >ERROR_BADCTL_ALT
         .byte   >CALL_FN_2E
         .byte   >CALL_FN_A3
         .byte   >CALL_FN_B3
         .byte   >CALL_FN_03
         .byte   >CALL_FN_5A
         .byte   >CALL_FN_23
         .byte   >CALL_FN_33
         .byte   >CALL_FN_43
         .byte   >CALL_FN_53
         .byte   >CALL_FN_C3
         .byte   >CALL_FN_63
         .byte   >CALL_FN_93
         .byte   >ERROR_BADCTL
         .byte   >ERROR_BADCTL
         .byte   >CALL_FN_E3
         .byte   >CALL_FN_4A
         .byte   >CALL_FN_1B
         .byte   >CALL_FN_D3
         .byte   >CALL_FN_5B
         .byte   >ERROR_BADCTL
         .byte   >CALL_FN_5B
         .byte   >CALL_FN_5B
         .byte   >CALL_FN_5B
         .byte   >CALL_FN_5B
         .byte   >CALL_FN_5B
         .byte   >CALL_FN_5B
         .byte   >CALL_FN_5B
         .byte   >CALL_FN_0C
         .byte   >CALL_FN_1E
         .byte   >CALL_FN_1E
         .byte   >CALL_FN_1E
         .byte   >CALL_FN_1E
         .byte   >CALL_FN_1E
         .byte   >CALL_FN_1E
         .byte   >CALL_FN_1E
         .byte   >CALL_FN_1E
         .byte   >CALL_FN_1E
         .byte   >CALL_FN_1E
         .byte   >CALL_FN_1E
SP_CMD_TABLE_L:
         .byte   <SP_CMD_00_STATUS
         .byte   <SP_CMD_01_READ_BLK
         .byte   <SP_CMD_02_WRITE_BLK
         .byte   <SP_CMD_03_FORMAT
         .byte   <SP_CMD_04_CONTROL
         .byte   <SP_CMD_05_INIT
         .byte   <SP_CMD_06_07_OPEN_CLOSE
         .byte   <SP_CMD_06_07_OPEN_CLOSE
         .byte   <SP_CMD_08_READ
         .byte   <SP_CMD_09_WRITE
SP_CMD_TABLE_H:
         .byte   >SP_CMD_00_STATUS
         .byte   >SP_CMD_01_READ_BLK
         .byte   >SP_CMD_02_WRITE_BLK
         .byte   >SP_CMD_03_FORMAT
         .byte   >SP_CMD_04_CONTROL
         .byte   >SP_CMD_05_INIT
         .byte   >SP_CMD_06_07_OPEN_CLOSE
         .byte   >SP_CMD_06_07_OPEN_CLOSE
         .byte   >SP_CMD_08_READ
         .byte   >SP_CMD_09_WRITE
CMD_PARAM_COUNT_TABLE:
         .byte   $03
         .byte   $03
         .byte   $03
         .byte   $01
         .byte   $03
         .byte   $01
         .byte   $01
         .byte   $01
         .byte   $04
         .byte   $04

SET_LEN_512:
         lda     #$02
         sta     RX_LEN_HI
         lda     #$00
         sta     RX_LEN_LO
         rts

SP_CMD_01_READ_BLK:
         jsr     SET_LEN_512
         lda     #SCSI_CMD_READ6
         sta     SCSI_CDB_CMD
         jsr     FN_52
         lda     #$10       ;CALL_FN_10 - EXECUTE SCSI DATA read CMD
CALL_FN_X2_RESTORE_RET:
         jsr     CALL_FN_X2
         jmp     RESTORE_ZP_RET

SP_CMD_02_WRITE_BLK:
         jsr     SET_LEN_512
         lda     DEV_STATUS
         cmp     #$b4       ;check WP flag
         bne     @do_write  ;branch if not WP
         lda     #P8E_WRITE_PROT
         jmp     CALL_FN_60_RETY

@do_write:
         lda     #SCSI_CMD_WRITE6
         sta     SCSI_CDB_CMD
         jsr     FN_52
         lda     #$20       ;CALL_FN_20 - EXECUTE SCSI DATA write CMD
         bne     CALL_FN_X2_RESTORE_RET

SP_CMD_03_FORMAT:
         lda     #$ca
         sta     BUF_PTR_H
         lda     #$00
         sta     BUF_PTR_L  ;set BUF_PTR to $ca00
         lda     #$06       ;CALL_FN_06 - Format unit and initialize PM if no PM detected
         bne     CALL_FN_X2_RESTORE_RET

SP_CMD_05_INIT:
         lda     SAVE_SP_UNIT
         bne     ERROR_BADUNIT_DUP ;init can be done only on unit 0
         lda     #$05
         sta     INIT_FLAG
         jsr     CALL_FN_X2 ;CALL_FN_05 - Init card
         jmp     RESTORE_ZP_RET ;could replace with CALL_FN_X2_RESTORE_RET

ERROR_BADUNIT_DUP:
         jmp     ERROR_BADUNIT

FN_52:   lda     CALL_TYPE
         and     #$40
         beq     @std_call_52
         lda     IS_IIgs
         bne     @ext_call_52
@std_call_52:
         lda     #$06       ;the following 2 are common to both code paths
         sta     SCSI_CMD_LEN
         ldy     #$02
         lda     (MEM_PTR_L),y
         sta     BUF_PTR_L
         iny
         lda     (MEM_PTR_L),y
         sta     BUF_PTR_H  ;BUF_PTR=*(MEM_PTR+2)
         ldx     #$02       ;probably useless
         lda     IS_IIgs    ;seems useless
         beq     @LCE62     ;seems useless
@LCE62:  lda     LBA
         sta     SCSI_CDB_LBA_LO
         lda     LBA+1
         sta     SCSI_CDB_LBA_HI
         lda     LBA+2
         sta     SCSI_CDB_LUN ;CDB_LBA=LBA
@fn_52_end:
         lda     #$01
         sta     SCSI_CDB_LEN
         lda     #$00
         sta     SCSI_CDB_CTRL
         lda     #$7c
         jmp     CALL_FN_X2 ;CALL_FN_7C - add PART_START to UNK_c827

@ext_call_52:
         lda     #$06       ;(bug?) should NATIVE be set before calling this??
         sta     SCSI_CMD_LEN
         ldy     #$02
         lda     [MEM_PTR_L],y
         sta     BUF_PTR_L
         iny
         lda     [MEM_PTR_L],y
         sta     BUF_PTR_H
         iny
         lda     [MEM_PTR_L],y
         sta     BUF_PTR_VH
         iny
         lda     [MEM_PTR_L],y
         sta     BUF_PTR_XH ;BUF_PTR=*(TMP_PTR+2); 4 bytes
         iny
         lda     [MEM_PTR_L],y
         clc
         adc     PART_START+2
         sta     LBA
         sta     SCSI_CDB_LBA_LO
         iny
         lda     [MEM_PTR_L],y
         adc     PART_START+1
         sta     LBA+1
         sta     SCSI_CDB_LBA_HI
         iny
         lda     [MEM_PTR_L],y
         adc     PART_START
         sta     SCSI_CDB_LUN
         sta     LBA+2      ;LBA_c8db=*(TMP_PTR+6)+PART_START, CDB_LBA=LBA_c8db
         jmp     @fn_52_end

SP_CMD_04_CONTROL:
         lda     CALL_TYPE  ;process Smartport Control command ($04)
         and     #$40
         beq     CMD_04_not_ext
         lda     IS_IIgs
         beq     CMD_04_not2gs
         clc
         xce
         ldy     #$06
         lda     [MEM_PTR_L],y
         tax
         sec
         xce
         txa
         jmp     CMD_04_check_valid

CMD_04_not2gs:
         ldy     #$06
         jmp     CMD_04_load_emulation

CMD_04_not_ext:
         ldy     #$04
CMD_04_load_emulation:
         lda     (MEM_PTR_L),y ;get the control code
CMD_04_check_valid:
         cmp     #$2b       ;last implemented control code is $2a
         bcc     CTRL_CODE_TABLE_IDX_A ;branch if control code is valid
ERROR_BADCTL:
         lda     #$21
         jmp     CALL_FN_60_RETY

CTRL_CODE_TABLE_IDX_A:
         tax
         lda     CTRL_CODE_TABLE_L,x
         beq     ERROR_BADCTL ;; BUG???? what if the low address is 0?
         sta     JMP_PTR
         lda     CTRL_CODE_TABLE1_H,x
         sta     JMP_PTR+1
         ldx     #$02
         jmp     (JMP_PTR)

CALL_FN_93:
         lda     #$93
         bne     CALL_FN_X2 ;CALL_FN_93

CALL_FN_A3:
         lda     #$a3
         bne     CALL_FN_X2 ;CALL_FN_A3

CALL_FN_B3:
         lda     #$b3
         bne     CALL_FN_X2 ;CALL_FN_B3

CALL_FN_C3:
         lda     #$c3
         bne     CALL_FN_X2 ;CALL_FN_C3

CALL_FN_E3:
         lda     #$e3
         bne     CALL_FN_X2 ;CALL_FN_E3

CALL_FN_D3:
         lda     #$d3
         bne     CALL_FN_X2 ;CALL_FN_D3

CALL_FN_03:
         lda     #$03
         bne     CALL_FN_X2 ;CALL_FN_03

CALL_FN_5A:
         lda     #$5a
         bne     CALL_FN_X2 ;CALL_FN_5A

CALL_FN_23:
         lda     #$23
         bne     CALL_FN_X2 ;CALL_FN_23

CALL_FN_33:
         lda     #$33
         bne     CALL_FN_X2 ;CALL_FN_33

CALL_FN_43:
         lda     #$43
         bne     CALL_FN_X2 ;CALL_FN_43

CALL_FN_53:
         lda     #$53
         bne     CALL_FN_X2 ;CALL_FN_53

CALL_FN_63:
         lda     #$63
         bne     CALL_FN_X2 ;CALL_FN_63

CALL_FN_4A:
         lda     #$4a
         bne     CALL_FN_X2 ;CALL_FN_4A

CALL_FN_1B:
         lda     #$1b
         bne     CALL_FN_X2 ;CALL_FN_1B

CALL_FN_0C:
         lda     #$0c
         bne     CALL_FN_X2 ;CALL_FN_0C

CALL_FN_5B:
         lda     #$5b
         bne     CALL_FN_X2 ;CALL_FN_5B

CALL_FN_1E:
         lda     #$1e       ;FN_1E - handle smartport control $20..$2A
CALL_FN_X2:
         ldx     #$02
         ldy     SLOT_OFFSET
         jmp     BANKSWITCH ;CALL_FN_X2_SAVE_Y

CALL_FN_2E:
         lda     #$2e
         bne     CALL_FN_X2 ;CALL_FN_2E - Eject

SP_CMD_08_READ:
         lda     #$09
         bne     CALL_FN_X2 ;CALL_FN_09 - Smartport Read

SP_CMD_09_WRITE:
         lda     #$19
         bne     CALL_FN_X2 ;CALL_FN_19 - Smartport Write

SP_CMD_00_STATUS:
         lda     #$24
         jsr     CALL_FN_X2 ;CALL_FN_24
RESTORE_ZP_RET:
         jsr     FN_12      ;restore ZP
         ldy     SLOT_OFFSET
         lda     RET_CODE
         cmp     #$08
         beq     RET_IOERROR_27
         lda     RET_CODE
         bne     RET_IOERROR
         lda     #$00
         clc
         rts

RET_IOERROR_27:
         lda     #$27
         sta     RET_CODE
RET_IOERROR:
         sta     REG_IO_5380_RST,y
         lda     #$27
         bne     CALL_FN_60_RET

FN_12:   lda     #$94
         jmp     CALL_FN_X2 ;CALL_FN_94

ERROR_BADCTL_ALT:
         jmp     ERROR_BADCTL

SP_CMD_06_07_OPEN_CLOSE:
         lda     #$6b
         jsr     CALL_FN_X2 ;CALL_FN_6B - jsr to B1:$c806
         bne     RESTORE_ZP_RET
SP_DEVICE_RESET:
         lda     SAVE_SP_UNIT
         beq     ERROR_BADUNIT_LOCAL
         lda     #$af
         jmp     CALL_FN_X2 ;CALL_FN_AF - BUS_FREE

ERROR_BADUNIT_LOCAL:
         jmp     ERROR_BADUNIT_DUP

FN_22:   lda     #$4f
         jmp     CALL_FN_X2 ;CALL_FN_4F

FN_42:   dec     TCOUNT_B0
         bne     @fn_42_end
         dec     TCOUNT_B1
         bne     @fn_42_end
         dec     TCOUNT_B2
@fn_42_end:
         rts

CALL_FN_60_RET:
         sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH

FN_TABLE:
         .word   FN_02
         .word   FN_12
         .word   FN_22
         .word   FN_42
         .word   FN_42
         .word   FN_52
         .word   FN_52
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
         sta     $1c
         jsr     DO_CALL_FN
         pla
         and     #$0f
         sta     REG_IO_BANK_SEL,y
         clc
         rts

DO_CALL_FN:
         jmp     (JMP_PTR)

         .byte   $02
         .byte   $31
         .byte   $34
         .byte   $30
