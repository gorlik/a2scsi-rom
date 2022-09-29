; Target assembler: cc65 v2.18.0 [--target none -C bank06.bin_cc65.cfg]
; 6502bench SourceGen v1.1.0
         .setcpu "65816"
SCSI_CMD_READ6 = $08
SCSI_CMD_WRITE6 = $0a

TMP_PTR1 =       $1b        ; temporary ZP pointer 
PD_PAR_BLK_LO =  $46        ;PRODOS input parameter Block lo
PD_PAR_BLK_HI =  $47        ;PRODOS input parameter Block hi
TMP_PTR_L =      $f6        ; temporary ZP long pointer
TMP_PTR_H =      $f7
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
REG_5380_DATA =  $c000      ; R current SCSI data lines status
REG_5380_DATA_OUT = $c000   ; W SCSI data output register
REG_5380_ICMD =  $c001      ; RW Initiator command register
REG_5380_MODE_SEL = $c002   ; RW Mode select register
REG_5380_SEL =   $c004      ; W Select enable register
REG_IO_DEV_ID =  $c009      ; R SCSI device ID
REG_IO_BANK_SEL = $c00a     ; W memory bank select
TCOUNT_B0 =      $c801      ; timeout counter LSB
SEL_TARGET =     $c806      ; SCSI (BUS?) ID of selected target
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SCSI_CMD_LEN =   $c80d      ; SCSI COMMAND lenght
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SCSI_CDB_LUN =   $c80f      ; 
SCSI_CDB_LBA_HI = $c810
SCSI_CDB_LBA_LO = $c811
SCSI_CDB_LEN =   $c812
SAVE_Y   =       $c81a      ; slot adress (n+8)<<4 
SAVE_SP_CMD_B =  $c81b      ; saved SmartPort Command
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
CMD_STATUS =     $c81e      ; SCSI CMD status - 0x00 OK, 0x02 Check condition
SDAT_BASE =      $c831      ;start of SDAT table (extends to $C8A7)
TEMP_c8c6 =      $c8c6      ;unknown
TEMP_c8ca =      $c8ca      ; TEMP_BUF_PTR?
UNK_c8cf =       $c8cf      ; unknown
PTR_c8d0 =       $c8d0      ; temp pointer storage (?)
TEMP_c8da =      $c8da      ;unknown
PTR_c8df =       $c8df      ;unknown
SAVE_SP2 =       $c8ed      ;saved SP
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB

         .org    $cc00
         .a8
         .i8
FN_06:   lda     DEV_STATUS
         cmp     #$b4
         bne     @LCC0C
         lda     #$2b
         jmp     LCFAB

@LCC0C:  lda     BUF_PTR_L
         sta     PTR_c8df
         lda     BUF_PTR_H
         sta     PTR_c8df+1
         jsr     FN_26
         bcs     @LCC1C
         rts

@LCC1C:  jsr     @CALL_FN_D3
         jsr     LCC32
         lda     #$0c
         jmp     CALL_FN_X06_SY ;CALL_FN_0C

@CALL_FN_D3:
         lda     #$d3
CALL_FN_X06_SY:
         ldx     #$06
         ldy     SAVE_Y
         jsr     BANKSWITCH
         rts

LCC32:   jsr     @LCC39
         jsr     @LCC92
         rts

@LCC39:  lda     #$00
         sta     BUF_PTR_L
         sta     TMP_PTR_L
         lda     #$ca
         sta     BUF_PTR_H
         sta     TMP_PTR_H
         ldy     #$02
         lda     TMP_PTR_L
         sta     (TMP_PTR_L),y
         iny
         lda     TMP_PTR_H
         sta     (TMP_PTR_L),y
         lda     #$c3
         jsr     CALL_FN_X06_SY ;CALL_FN_C3
         lda     #$00
         sta     BUF_PTR_L
         lda     #$ca
         sta     BUF_PTR_H
         ldy     #$03
         lda     (BUF_PTR_L),y
         sta     $c92c
         sec
         ldx     DEV_STATUS
         cpx     #$f8
         beq     @LCC71
         sbc     #$40
         jmp     @LCC73

@LCC71:  sbc     #$45
@LCC73:  sta     $c8d2,y
         dey
@LCC77:  lda     (BUF_PTR_L),y
         sta     $c929,y
         sbc     #$00
         sta     $c8d2,y
         dey
         bpl     @LCC77
         ldy     #$06
         lda     (BUF_PTR_L),y
         sta     PTR_c8d0
         iny
         lda     (BUF_PTR_L),y
         sta     PTR_c8d0+1
         rts

@LCC92:  lda     #$00
         sta     PD_PAR_BLK_LO
         sta     PD_PAR_BLK_HI
         sta     BUF_PTR_L
         lda     #$ca
         sta     BUF_PTR_H
         jsr     @LCD0B
         lda     #$45
         ldy     #$00
         sta     (BUF_PTR_L),y
         iny
         lda     #$52
         sta     (BUF_PTR_L),y
         lda     PTR_c8d0
         iny
         sta     (BUF_PTR_L),y
         iny
         lda     PTR_c8d0+1
         sta     (BUF_PTR_L),y
         ldx     #$00
         ldy     #$04
@LCCBC:  lda     $c929,x
         sta     (BUF_PTR_L),y
         inx
         iny
         cpx     #$08
         bne     @LCCBC
         ldy     #$11
         lda     #$01
         sta     (BUF_PTR_L),y
         lda     #$1f
         jsr     CALL_FN_X06_SY ;CALL_FN_1F
         jsr     @LCCF3
         lda     #$01
         jsr     @LCCFB
         lda     #$2f
         jsr     CALL_FN_X06_SY ;CALL_FN_2F
         jsr     @LCCF3
         lda     #$02
         jsr     @LCCFB
         lda     #$0f
         jsr     CALL_FN_X06_SY ;CALL_FN_0F
         jsr     @LCCF3
         ldy     SAVE_Y
         rts

@LCCF3:  jsr     LCD27
         lda     #$20
         jmp     CALL_FN_X06_SY

@LCCFB:  sta     PD_PAR_BLK_LO
         lda     #$00
         sta     PD_PAR_BLK_HI
         sta     BUF_PTR_L
         lda     #$ca
         sta     BUF_PTR_H
         jsr     @LCD0B
         rts

@LCD0B:  lda     #$00
         tay
@LCD0E:  sta     (BUF_PTR_L),y
         iny
         bne     @LCD0E
         rts

FN_26:   lda     #$47
         jsr     CALL_FN_X06_SY ;CALL_FN_47
         lda     UNK_c8cf
         beq     @ret_fail
         clc
         rts

@ret_fail:
         sec
         rts

         .byte   $a9
         .byte   $08
         .byte   $4c
         .byte   $2c
         .byte   $cd

LCD27:   lda     #$0a
         jmp     @LCD2C

@LCD2C:  sta     SCSI_CDB_CMD
         lda     #$06
         sta     SCSI_CMD_LEN
         lda     #$00
         sta     SCSI_CDB_LUN
         lda     PD_PAR_BLK_HI
         sta     SCSI_CDB_LBA_HI
         lda     PD_PAR_BLK_LO
         sta     SCSI_CDB_LBA_LO
         lda     #$01
         sta     SCSI_CDB_LEN
         rts

         .byte   $a5
         .byte   $46
         .byte   $8d
         .byte   $c7
         .byte   $c8
         .byte   $a5
         .byte   $47
         .byte   $8d
         .byte   $c8
         .byte   $c8
         .byte   $60
         .byte   $ad
         .byte   $c7
         .byte   $c8
         .byte   $85
         .byte   $46
         .byte   $ad
         .byte   $c8
         .byte   $c8
         .byte   $85
         .byte   $47
         .byte   $60

FN_16:   lda     SCSI_CDB_CMD
         cmp     #SCSI_CMD_READ6
         beq     @FN_16_READ6 ;branch if SCSI READ6 command
         cmp     #SCSI_CMD_WRITE6 ;redundant ???
         rts

@FN_16_READ6:
         lda     #$00
         sta     RET_CODE
         jsr     COPY_CMD_c81b
         jsr     LCDAC
         bcs     @LCD8C
         jsr     LCE3C
         bcc     @LCD85
         jsr     LCE63
         bcc     @LCD85
         jsr     LCE80
         bcs     LCDA2
@LCD85:  clc
         lda     #$00
         sta     RET_CODE
         rts

@LCD8C:  jsr     LCEDF
         lda     SAVE_SP_CMD_B
         cmp     #$0a
         beq     @LCD9D
         jsr     LCEA0
         bcs     LCDA2
         bcc     @LCD85

@LCD9D:  jsr     LCEB9
         bcc     @LCD85
LCDA2:   lda     #$27
         jmp     LCFAB

LCDA7:   lda     #$49
         jmp     CALL_FN_X06_SY ;CALL_FN_49

LCDAC:   jsr     LCDA7
         ldx     #$02
         lda     $c901,x
         cmp     #$06
         beq     FN_66
         cmp     #$02
         beq     FN_66
         and     #$07
         cmp     #$01
         beq     @LCDC5
         sec
         bcs     @LCDC6

@LCDC5:  clc
@LCDC6:  ldy     SAVE_Y
         rts

LCDCA:   ldx     #$0c
         lda     $c901,x
         rts

FN_66:   jsr     LCDCA
         cmp     #$28
         beq     LCDDF
         cmp     #$b7
         beq     LCE27
         cmp     #$b0
         beq     LCDF5
LCDDF:   jsr     LCDF9
         lda     CALL_TYPE
         cmp     #$01
         bne     @LCDED
         lda     #$27
         bne     LCDEF

@LCDED:  lda     #$2e
LCDEF:   ldy     SAVE_Y
         jmp     LCFAB

LCDF5:   lda     #$2f
         bne     LCDEF

LCDF9:   lda     #$0c
         jmp     CALL_FN_X06_SY ;CALL_FN_0C

FN_56:   lda     #$ff
         sta     SAVE_SP2
@LCE03:  lda     #$a3
         jsr     CALL_FN_X06_SY ;CALL_FN_A3
         lda     CMD_STATUS
         beq     @LCE25
         jsr     LCE2F
         jsr     LCDA7
         jsr     LCDCA
         cmp     #$28
         beq     @LCE25
         cmp     #$b0
         beq     @LCE25
         dec     SAVE_SP2
         bne     @LCE03
         sec
         rts

@LCE25:  clc
         rts

LCE27:   jsr     FN_56
         bcc     LCDDF
         jmp     LCDA2

LCE2F:   tya
         ldx     #$ff
         ldy     #$c0
@LCE34:  dex
         bne     @LCE34
         dey
         bne     @LCE34
         tay
         rts

LCE3C:   lda     #$00
         sta     TEMP_c8ca-1
         sta     TEMP_c8c6
@loop1:  jsr     LCE9D      ;TEMP_c8c6 count from 0 to 9
         bcc     @LCE4C
         inc     TEMP_c8ca-1
@LCE4C:  inc     TEMP_c8c6
         lda     TEMP_c8c6
         cmp     #$0a
         bne     @loop1
         lda     TEMP_c8ca-1
         cmp     #$0a
         beq     @LCE60
         cmp     #$05
         rts

@LCE60:  jmp     LCDA2

LCE63:   lda     #$00
         sta     TEMP_c8c6
@loop2:  jsr     LCEB9      ;TEMP_c8c6 count from 0 to 9
         bcs     @LCE7E
         jsr     LCE9D
         bcs     @LCE7E
         inc     TEMP_c8c6
         lda     TEMP_c8c6
         cmp     #$0a
         bne     @loop2
         clc
         rts

@LCE7E:  sec
         rts

LCE80:   lda     #$21
         jsr     CALL_FN_X06 ;CALL_FN_21
         lda     #$3d
         jsr     CALL_FN_X06 ;CALL_FN_3D
         lda     RET_CODE
         bne     @LCE9B
         jsr     LCEB9
         bcs     @LCE95
         rts

@LCE95:  jsr     LCE63
         bcs     LCE80
         rts

@LCE9B:  sec
         rts

LCE9D:   jsr     LCEDF
LCEA0:   lda     #$41
         jsr     CALL_FN_X06_SY ;CALL_FN_41
         jsr     CALL_FN_00
         jsr     CALL_FN_01
         lda     #$a0
         jsr     CALL_FN_X06_SY ;CALL_FN_A0
LCEB0:   lda     CMD_STATUS
         beq     @LCEB7
         sec
         rts

@LCEB7:  clc
         rts

LCEB9:   jsr     LCEDF
         lda     #$51
         jsr     CALL_FN_X06_SY ;CALL_FN_51
         jsr     CALL_FN_00
         jsr     CALL_FN_11
         lda     #$a0
         jsr     CALL_FN_X06_SY ;CALL_FN_A0
         jmp     LCEB0

CALL_FN_00:
         lda     #$00
CALL_FN_X06:
         ldx     #$06
         jsr     BANKSWITCH
         rts

CALL_FN_01:
         lda     #$01
         bne     CALL_FN_X06

CALL_FN_11:
         lda     #$11
         bne     CALL_FN_X06

LCEDF:   lda     #$00
         sta     BUF_PTR_L
         lda     #$ca
         sta     BUF_PTR_H
         rts

COPY_CMD_c81b:
         lda     SCSI_CDB_CMD
         sta     SAVE_SP_CMD_B
         rts

FN_46:   lda     #$02       ;try to call FN_36 twice
         sta     TEMP_c8da
@loop3:  lda     #$00
         sta     RET_CODE
         jsr     FN_36
         bcc     @LCF03     ;call to FN_36 was successfull
         dec     TEMP_c8da
         bne     @loop3     ;loop one more time
@LCF03:  rts

FN_36:   jsr     LCF21      ;CALL_FN_3A
         bcs     RET_EC_27
         jsr     SCSI_ARBITRATE_ALT
         bcs     RET_EC_27
         jsr     SCSI_SELECT_ALT
         bcs     RET_EC_27
         lda     #$44
         jsr     CALL_FN_X06_SY ;CALL_FN_44
         clc
         rts

RET_EC_27:
         lda     #$27
         sta     RET_CODE
         sec
         rts

LCF21:   jsr     CALL_FN_3A
         bcs     RET_EC_27  ;seems redundant as the same is in the calling function
         rts

SCSI_ARBITRATE_ALT:
         lda     REG_5380_MODE_SEL,y
         and     #$fe
         sta     REG_5380_MODE_SEL,y ;reset arbitrate bit
         lda     REG_IO_DEV_ID,y
         sta     REG_5380_DATA_OUT,y ;put scsi id on the bus
         lda     REG_5380_MODE_SEL,y
         ora     #$01
         sta     REG_5380_MODE_SEL,y ;initiate arbitration
         lda     REG_5380_ICMD,y
         and     #$20
         bne     SCSI_ARBITRATE_ALT ;lost SCSI arbitration, try again
         lda     REG_5380_DATA,y
         sec
         sbc     REG_IO_DEV_ID,y
         beq     @LCF55     ;only this device requested to arbitrate
         sec
         sbc     REG_IO_DEV_ID,y
         bmi     @LCF55     ;we are the highest priority
         sec                ;we are not the highest priority
         rts                ;return fail - bug(?) does not reset arbitrate bit

@LCF55:  lda     REG_5380_ICMD,y ;check again for lost arbitration
         and     #$20
         bne     SCSI_ARBITRATE_ALT ;arbitration lost try again
         clc
         rts                ;return success

SCSI_SELECT_ALT:
         lda     #$04       ;very similar to SCSI SELECT
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
         sta     TCOUNT_B0
@retry_not_busy:
         jsr     WAIT_NOT_BUSY
         bcc     @end_sel
         dec     TCOUNT_B0
         bne     @retry_not_busy
         jmp     ret_fail2

@end_sel:
         lda     #$00
         sta     REG_5380_ICMD,y
         clc
         rts

CALL_FN_3A:
         lda     #$3a
         jmp     CALL_FN_X06_SY ;CALL_FN_3A

WAIT_NOT_BUSY:
         lda     #$4b
         jsr     CALL_FN_X06_SY ;CALL_FN_4B
         lda     SDAT_BASE-1
         beq     ret_fail2
         clc
         rts

ret_fail2:
         sec
         rts

LCFAB:   sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH

FN_TABLE:
         .word   FN_06
         .word   FN_16
         .word   FN_26
         .word   FN_36
         .word   FN_46
         .word   FN_56
         .word   FN_66
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea
         .byte   $ea

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

         .byte   $02
         .byte   $31
         .byte   $34
         .byte   $30
