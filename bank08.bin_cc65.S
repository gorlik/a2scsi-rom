; Target assembler: cc65 v2.18.0 [--target none -C bank08.bin_cc65.cfg]
; 6502bench SourceGen v1.1.0
         .setcpu "65816"
TMP_PTR1 =       $1b        ; temporary ZP pointer 
PD_PAR_BUF_HI =  $45        ;PRODOS input parameter Buffer hi address
PD_PAR_BLK_LO =  $46        ;PRODOS input parameter Block lo
PD_PAR_BLK_HI =  $47        ;PRODOS input parameter Block hi
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
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B2 =      $c802      ; timeout counter MSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
SEL_TARGET =     $c806      ; SCSI (BUS?) ID of selected target
INIT_FLAG =      $c809      ; card initialized flag (init=$77)
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SCSI_CMD_LEN =   $c80d      ; SCSI COMMAND lenght
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SCSI_CDB_LUN =   $c80f      ; 
SCSI_CDB_LBA_HI = $c810
SCSI_CDB_LBA_LO = $c811
SCSI_CDB_LEN =   $c812
SCSI_CDB_CTRL =  $c813
SAVE_Y   =       $c81a      ; slot adress (n+8)<<4 
SAVE_SP_CMD_B =  $c81b      ; saved SmartPort Command
CMD_STATUS =     $c81e      ; SCSI CMD status - 0x00 OK, 0x02 Check condition
SCSI_RD_c81f =   $c81f      ; SCSI STATUS or MESSAGE return from FN_04 
SAVE_ENTRY_SP =  $c821      ; stack pointer saved at the PD/SM entry point
LBA_c8db =       $c8db      ; LBA to use in CDB (?) (copied to CDB_LBA)
BOOT_SEQ =       $c8e3      ;$55 if in boot process
RX_LEN_LO =      $c8e4      ;bytes read if call successfull
RX_LEN_HI =      $c8e5      ;bytes read if call successfull
TIMEOUT  =       $c9f6      ; each unit is 1.25s
MON_SLOOP =      $faba

         .org    $cc00
         .byte   $a2
         .byte   $20
         .byte   $a2
         .byte   $00
         .byte   $a2
         .byte   $03
         .byte   $a2
         .byte   $00
         .byte   $ad
         .byte   $ff
         .byte   $cf
         .byte   $d8
         .byte   $08
         .byte   $78
         .byte   $a9
         .byte   $60
         .byte   $8d
         .byte   $f8
         .byte   $07
         .byte   $20
         .byte   $f8
         .byte   $07
         .byte   $ba
         .byte   $bd
         .byte   $00
         .byte   $01
         .byte   $8d
         .byte   $f8
         .byte   $07
         .byte   $28
         .byte   $ad
         .byte   $ff
         .byte   $cf
         .byte   $ad
         .byte   $f8
         .byte   $07
         .byte   $85
         .byte   $1a
         .byte   $a9
         .byte   $00
         .byte   $85
         .byte   $19
         .byte   $a8
         .byte   $b1
         .byte   $19
         .byte   $a0
         .byte   $0a
         .byte   $a9
         .byte   $00
         .byte   $91
         .byte   $19
         .byte   $a9
         .byte   $55
         .byte   $8d
         .byte   $e3
         .byte   $c8
         .byte   $ad
         .byte   $f8
         .byte   $07
         .byte   $29
         .byte   $0f
         .byte   $18
         .byte   $69
         .byte   $08
         .byte   $0a
         .byte   $0a
         .byte   $0a
         .byte   $0a
         .byte   $8d
         .byte   $1a
         .byte   $c8
         .byte   $a8
         .byte   $a2
         .byte   $00
         .byte   $a9
         .byte   $05
         .byte   $20
         .byte   $cc
         .byte   $cf
         .byte   $a9
         .byte   $01
         .byte   $8d
         .byte   $1d
         .byte   $c8
         .byte   $8d
         .byte   $00
         .byte   $c8
         .byte   $20
         .byte   $82
         .byte   $ce
         .byte   $4c
         .byte   $44
         .byte   $ce
         .byte   $18
         .byte   $90
         .byte   $01
         .byte   $38
         .byte   $d8
         .byte   $08
         .byte   $78
         .byte   $a9
         .byte   $60
         .byte   $8d
         .byte   $f8
         .byte   $07
         .byte   $20
         .byte   $f8
         .byte   $07
         .byte   $ba
         .byte   $bd
         .byte   $00
         .byte   $01
         .byte   $8d
         .byte   $f8
         .byte   $07
         .byte   $29
         .byte   $0f
         .byte   $18
         .byte   $69
         .byte   $08
         .byte   $0a
         .byte   $0a
         .byte   $0a
         .byte   $0a
         .byte   $48
         .byte   $a5
         .byte   $19
         .byte   $48
         .byte   $a5
         .byte   $1a
         .byte   $48
         .byte   $ad
         .byte   $ff
         .byte   $cf
         .byte   $ad
         .byte   $f8
         .byte   $07
         .byte   $85
         .byte   $1a
         .byte   $a9
         .byte   $00
         .byte   $85
         .byte   $19
         .byte   $8d
         .byte   $e3
         .byte   $c8
         .byte   $a8
         .byte   $b1
         .byte   $19
         .byte   $a0
         .byte   $0a
         .byte   $a9
         .byte   $00
         .byte   $91
         .byte   $19
         .byte   $68
         .byte   $85
         .byte   $1a
         .byte   $68
         .byte   $85
         .byte   $19
         .byte   $68
         .byte   $a8
         .byte   $8c
         .byte   $1a
         .byte   $c8
         .byte   $ba
         .byte   $8e
         .byte   $21
         .byte   $c8
         .byte   $20
         .byte   $77
         .byte   $cf
         .byte   $28
         .byte   $90
         .byte   $13
         .byte   $a2
         .byte   $00
         .byte   $a9
         .byte   $02
         .byte   $20
         .byte   $cc
         .byte   $cf
         .byte   $20
         .byte   $72
         .byte   $cf
         .byte   $ae
         .byte   $e4
         .byte   $c8
         .byte   $ac
         .byte   $e5
         .byte   $c8
         .byte   $4c
         .byte   $ce
         .byte   $cd
         .byte   $a9
         .byte   $01
         .byte   $8d
         .byte   $1d
         .byte   $c8
         .byte   $ad
         .byte   $09
         .byte   $c8
         .byte   $c9
         .byte   $77
         .byte   $f0
         .byte   $05
         .byte   $a9
         .byte   $05
         .byte   $20
         .byte   $88
         .byte   $ce
         .byte   $20
         .byte   $86
         .byte   $ce
         .byte   $a9
         .byte   $15
         .byte   $20
         .byte   $88
         .byte   $ce
         .byte   $a5
         .byte   $42
         .byte   $d0
         .byte   $03
         .byte   $4c
         .byte   $bb
         .byte   $cd
         .byte   $c9
         .byte   $01
         .byte   $d0
         .byte   $03
         .byte   $4c
         .byte   $00
         .byte   $cd
         .byte   $c9
         .byte   $02
         .byte   $d0
         .byte   $03
         .byte   $4c
         .byte   $7d
         .byte   $cd
         .byte   $c9
         .byte   $03
         .byte   $d0
         .byte   $eb
         .byte   $4c
         .byte   $d2
         .byte   $cd
         .byte   $55
         .byte   $55
         .byte   $55
         .byte   $82
         .byte   $00
         .byte   $00
         .byte   $1f
         .byte   $5d

         .a8
         .i8
FN_98:   jsr     CALL_FN_3A
         jsr     S_CE0E
FN_18:   jsr     FN_08
FN_48:   lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$04
         beq     @B_CD23
         lda     REG_5380_STAT,y
         cmp     #$6c
         beq     @B_CD28
         jsr     CALL_FN_42
         lda     TCOUNT_B2
         beq     @B_CD28
         bne     FN_48

@B_CD23: lda     #$01
         jsr     CALL_FN_X0 ;CALL_FN_01
@B_CD28: jsr     FN_A8
         jmp     B_CDD7

FN_A8:   jsr     S_CDAC
FN_38:   lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$0c
         beq     @B_CD48
         cmp     #$1c
         beq     @B_CD62
         jsr     CALL_FN_42
         lda     TCOUNT_B2
         beq     @B_CD4D
         bne     FN_38

@B_CD48: lda     #$03
         jsr     S_CF58
@B_CD4D: lda     #$00
         sta     TCOUNT_B2
@B_CD52: lda     REG_5380_STAT,y
         and     #$1c
         cmp     #$1c
         beq     @B_CD62
         dec     TCOUNT_B2
         beq     @B_CD6F
         bne     @B_CD52

@B_CD62: lda     #$07
         jsr     S_CF6A
         lda     #$00
         sta     REG_5380_ICMD,y
         sta     REG_IO_5380_RST,y
@B_CD6F: ldy     SAVE_Y
         rts

CALL_FN_3A:
         lda     #$3a
         jmp     CALL_FN_X0

CALL_FN_42:
         lda     #$42
         jmp     CALL_FN_X0

         .byte   $ad
         .byte   $f3
         .byte   $c9
         .byte   $c9
         .byte   $b4
         .byte   $f0
         .byte   $14
         .byte   $20
         .byte   $73
         .byte   $cd
         .byte   $20
         .byte   $15
         .byte   $ce

FN_28:   jsr     FN_08
FN_58:   lda     #$11
         jsr     CALL_FN_X0
         jsr     FN_A8
         jmp     B_CDD7

         .byte   $a9
         .byte   $2b
         .byte   $8d
         .byte   $0b
         .byte   $c8
         .byte   $4c
         .byte   $9e
         .byte   $cf

FN_08:   jsr     CALL_FN_3A_dup
FN_B8:   jsr     SCSI_ARBITRATE
         jsr     S_CEC5
         jsr     CALL_FN_14
S_CDAC:  lda     #$ff
         sta     TCOUNT_B0
         sta     TCOUNT_B1
         lda     TIMEOUT
         sta     TCOUNT_B2
         rts

         .byte   $a9
         .byte   $25
         .byte   $20
         .byte   $88
         .byte   $ce
         .byte   $a9
         .byte   $1d
         .byte   $20
         .byte   $88
         .byte   $ce
         .byte   $20
         .byte   $72
         .byte   $cf
         .byte   $ac
         .byte   $28
         .byte   $c8
         .byte   $ae
         .byte   $29
         .byte   $c8
         .byte   $a9
         .byte   $00
         .byte   $18
         .byte   $60
         .byte   $a9
         .byte   $06
         .byte   $20
         .byte   $88
         .byte   $ce

B_CDD7:  lda     PD_PAR_BUF_HI
         cmp     #$08
         beq     @B_CDE9
         lda     INIT_FLAG
         cmp     #$77
         bne     @B_CDE9
         lda     RET_CODE
         bne     @B_CDF0
@B_CDE9: jsr     CALL_FN_12
         lda     #$00
         clc
         rts

@B_CDF0: lda     SCSI_CDB_CMD
         beq     @B_CDE9
         lda     SAVE_SP_CMD_B
         cmp     #$04
         beq     @B_CDE9
         lda     RET_CODE
         cmp     #$02
         beq     @B_CE06
         jmp     FN_68

@B_CE06: lda     #$16
         jsr     CALL_FN_X0 ;CALL_FN_16
         jmp     @B_CDE9

S_CE0E:  jsr     @CALL_FN_84
         lda     #$08
         bne     @B_CE1C

         .byte   $20
         .byte   $3f
         .byte   $ce
         .byte   $a9
         .byte   $0a
         .byte   $d0
         .byte   $00

@B_CE1C: sta     SCSI_CDB_CMD
         lda     #$06
         sta     SCSI_CMD_LEN
         lda     LBA_c8db+2
         sta     SCSI_CDB_LUN
         lda     PD_PAR_BLK_HI
         sta     SCSI_CDB_LBA_HI
         lda     PD_PAR_BLK_LO
         sta     SCSI_CDB_LBA_LO
         lda     #$01
         sta     SCSI_CDB_LEN
         lda     #$00
         sta     SCSI_CDB_CTRL
         rts

@CALL_FN_84:
         lda     #$84
         jmp     CALL_FN_X0

         .byte   $a9
         .byte   $01
         .byte   $85
         .byte   $42
         .byte   $8d
         .byte   $1d
         .byte   $c8
         .byte   $a9
         .byte   $00
         .byte   $85
         .byte   $46
         .byte   $85
         .byte   $47
         .byte   $a9
         .byte   $15
         .byte   $20        ;CALL_FN_15
         .byte   $88
         .byte   $ce
         .byte   $a9
         .byte   $08
         .byte   $85
         .byte   $45
         .byte   $a9
         .byte   $00
         .byte   $85
         .byte   $44
         .byte   $a9
         .byte   $55
         .byte   $8d
         .byte   $e3
         .byte   $c8
         .byte   $20
         .byte   $00
         .byte   $cd
         .byte   $ae
         .byte   $01
         .byte   $08
         .byte   $f0
         .byte   $13
         .byte   $ae
         .byte   $00
         .byte   $08
         .byte   $e0
         .byte   $01
         .byte   $d0
         .byte   $0c
         .byte   $8e
         .byte   $e3
         .byte   $c8
         .byte   $ad
         .byte   $1a
         .byte   $c8
         .byte   $29
         .byte   $70
         .byte   $aa
         .byte   $4c
         .byte   $01
         .byte   $08
@CALL_FN_45:
         .byte   $a9
         .byte   $45
         .byte   $d0
         .byte   $06
@CALL_FN_75:
         .byte   $a9
         .byte   $75
         .byte   $d0
         .byte   $02
         .byte   $a9
         .byte   $25

CALL_FN_X0:
         ldx     #$00
         jmp     BANKSWITCH

CALL_FN_3A_dup:
         lda     #$3a
         bne     CALL_FN_X0

SCSI_ARBITRATE:
         lda     REG_5380_MODE_SEL,y
         and     #$fe
         sta     REG_5380_MODE_SEL,y ;reset arbitrate bit
         lda     REG_IO_DEV_ID,y
         sta     REG_5380_DATA_OUT,y
         lda     REG_5380_MODE_SEL,y
         ora     #$01
         sta     REG_5380_MODE_SEL,y
         lda     REG_5380_ICMD,y
         and     #$20
         bne     SCSI_ARBITRATE ;lost SCSI arbitration, try again
         lda     REG_5380_DATA,y
         sec
         sbc     REG_IO_DEV_ID,y
         beq     @B_CEBD
         sec
         sbc     REG_IO_DEV_ID,y
         bmi     @B_CEBD
@B_CEBD: lda     REG_5380_ICMD,y
         and     #$20
         bne     SCSI_ARBITRATE ;lost SCSI arbitration, try again
         rts

S_CEC5:  lda     #$04
         nop
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
         ldx     #$ff
         stx     TCOUNT_B0
@B_CEEE: jsr     @S_CF27
         bcc     @B_CF04
         dec     TCOUNT_B0
         bne     @B_CEEE
         lda     BOOT_SEQ
         cmp     #$55
         beq     @B_CF04
         lda     #$27
         sta     RET_CODE
@B_CF04: lda     #$00
         sta     REG_5380_ICMD,y
         clc
         rts

         .byte   $a2
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

@S_CF27: ldx     #$00
@B_CF29: dex
         beq     @B_CF51
         lda     REG_5380_STAT,y
         and     #$40
         beq     @B_CF29
         clc
         rts

         .byte   $a2
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

@B_CF51: sec
         rts

CALL_FN_14:
         lda     #$14
         jmp     CALL_FN_X0

S_CF58:  sta     REG_5380_TCMD,y
         lda     #$04
         jsr     CALL_FN_X0 ;CALL_FN_04
         lda     SCSI_RD_c81f
         sta     CMD_STATUS
         sta     RET_CODE
         rts

S_CF6A:  sta     REG_5380_TCMD,y
         lda     #$04
         jmp     CALL_FN_X0 ;CALL_FN_04

CALL_FN_12:
         lda     #$12
         jmp     CALL_FN_X0

         .byte   $a2
         .byte   $07
         .byte   $b5
         .byte   $f6
         .byte   $9d
         .byte   $a8
         .byte   $c8
         .byte   $b5
         .byte   $15
         .byte   $9d
         .byte   $b0
         .byte   $c8
         .byte   $b5
         .byte   $42
         .byte   $9d
         .byte   $bc
         .byte   $c8
         .byte   $ca
         .byte   $10
         .byte   $ee
         .byte   $a2
         .byte   $0a
         .byte   $b5
         .byte   $15
         .byte   $9d
         .byte   $b0
         .byte   $c8
         .byte   $ca
         .byte   $e0
         .byte   $07
         .byte   $d0
         .byte   $f6
         .byte   $60

FN_78:   jmp     $e000

FN_88:   jmp     MON_SLOOP

FN_68:   jsr     CALL_FN_12
         sta     REG_IO_5380_RST,y
         ldx     SAVE_ENTRY_SP
         inx
         txs
         ldy     RX_LEN_HI
         ldx     RX_LEN_LO
         lda     RET_CODE
         sec
         rts

FN_TABLE:
         .word   FN_08
         .word   FN_18
         .word   FN_28
         .word   FN_38
         .word   FN_48
         .word   FN_58
         .word   FN_68
         .word   FN_78
         .word   FN_88
         .word   FN_98
         .word   FN_A8
         .word   FN_B8

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

         .byte   $d7
         .byte   $00
         .byte   $00
         .byte   $00
