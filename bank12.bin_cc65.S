; Target assembler: cc65 v2.18.0 [--target none -C bank12.bin_cc65.cfg]
; 6502bench SourceGen v1.8.3
         .setcpu "65816"
TMP_PTR0 =       $19        ; temporary ZP pointer 
TMP_PTR1 =       $1b        ; temporary ZP pointer 
PD_PAR_CMD =     $42        ;PRODOS input parameter COMMAND number
PD_PAR_BLK_LO =  $46        ;PRODOS input parameter Block lo
PD_PAR_BLK_HI =  $47        ;PRODOS input parameter Block hi
TMP_PTR_L =      $f6        ; temporary ZP long pointer
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
P8_IBAKVER =     $bffc      ;undefined; reserved for future use
P8_KVERSION =    $bfff      ;version no. (release ID)
REG_5380_DATA_OUT = $c000   ; W SCSI data output register
REG_5380_ICMD =  $c001      ; RW Initiator command register
REG_5380_STAT =  $c004      ; R SCSI status
REG_5380_STAT2 = $c005      ; R Bus and status register
REG_IO_PDMA_DACK = $c008    ; RW PDMA/DACK
REG_IO_BANK_SEL = $c00a     ; W memory bank select
REG_IO_5380_RST = $c00b     ; W 5380 Reset
REG_IO_DRQ =     $c00e      ; R read DRQ on bit7
SLTROMSEL =      $c02d      ;RW slot vs. ROM selection
SHADOW   =       $c035      ;RW inhibit shadowing
CYAREG   =       $c036      ;RW Configure Your Apple
DEV_IDX  =       $c800      ; index into the SDAT/DIBTAB tables
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B2 =      $c802      ; timeout counter MSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
XFER_MODE =      $c804      ; 0x00 IIe PDMA, 0x01 IIgs PDMA, 0x02-0xff PIO 
SEL_TARGET =     $c806      ; SCSI (BUS?) ID of selected target
SAVE_CYAREG =    $c808      ; saved value of CYAREG
INIT_FLAG =      $c809      ; card initialized flag (init=$77)
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SAVE_Y   =       $c81a      ; slot adress (n+8)<<4 
SAVE_SP_CMD_B =  $c81b      ; saved SmartPort Command
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
PART_START =     $c824      ; partition start (3 bytes) seems to be in reverse endian (?)
UNK_c827 =       $c827      ; 3-byte unknown in reverse endian as the above
BLK_c8c7 =       $c8c7      ; saved PRODOS BLOCK from input parameters
LBA_c8db =       $c8db      ; LBA to use in CDB (?) (copied to CDB_LBA)
BOOT_SEQ =       $c8e3      ;$55 if in boot process
IIgs_PDMA =      $c8f3      ;0x01 if IIgs PDMA
DBITAB_BASE =    $c931      ;start of DIBTAB (extends to $C9ED)
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB
TIMEOUT  =       $c9f6      ; each unit is 1.25s

         .org    $cc00
         .a8
         .i8
FN_0C:   lda     SEL_TARGET
         sta     $c929
         lda     DEV_IDX
         sta     $c92a
         lda     #$73
         jsr     CALL_FN_XC ;CALL_FN_73
         lda     #$a5
         sta     INIT_FLAG
         jsr     CALL_FN_XC ;CALL_FN_A5
         lda     $c929
         sta     SEL_TARGET
         lda     $c92a
         sta     DEV_IDX
         jsr     FN_9C
         lda     #$83
         jsr     CALL_FN_XC ;CALL_FN_83
         jmp     LCCE3

CALL_FN_XC:
         ldx     #$0c
         ldy     SAVE_Y
         jsr     BANKSWITCH
         rts

FN_1C:   lda     CALL_TYPE  ;add partition start to BLK number
         cmp     #$01
         bne     @FN_1C_smartport
         lda     PD_PAR_BLK_LO
         sta     BLK_c8c7
         lda     PD_PAR_BLK_HI
         sta     BLK_c8c7+1
         clc
         lda     PART_START+2
         adc     PD_PAR_BLK_LO
         sta     PD_PAR_BLK_LO
         sta     LBA_c8db
         lda     PART_START+1
         adc     PD_PAR_BLK_HI
         sta     PD_PAR_BLK_HI
         sta     LBA_c8db+1
         lda     #$00
         adc     PART_START
         sta     LBA_c8db+2
@FN_1C_check_err:
         bcc     @FN_1C_end
         jmp     ERR_BADBLOCK

@FN_1C_end:
         ldy     SAVE_Y
         rts

@FN_1C_smartport:
         and     #$40
         beq     @FN_1C_not_ext
         lda     IIgs_PDMA
         cmp     #$01
         beq     @FN_1C_2gs
         ldy     #$06
         bne     @FN_1C_ext_2e

@FN_1C_not_ext:
         ldy     #$04
@FN_1C_ext_2e:
         clc
         lda     (TMP_PTR_L),y
         adc     PART_START+2
         sta     LBA_c8db
         iny
         lda     (TMP_PTR_L),y
         adc     PART_START+1
         sta     LBA_c8db+1
         iny
         lda     (TMP_PTR_L),y
         adc     PART_START
         sta     LBA_c8db+2
         jmp     @FN_1C_check_err

@FN_1C_2gs:
         ldy     #$06
         clc
         xce
         lda     [TMP_PTR_L],y
         adc     PART_START+2
         sta     LBA_c8db
         iny
         lda     [TMP_PTR_L],y
         adc     PART_START+1
         sta     LBA_c8db+1
         iny
         lda     [TMP_PTR_L],y
         adc     PART_START
         sta     LBA_c8db+2
         sec
         xce
         jmp     @FN_1C_check_err

FN_2C:   lda     #$00       ;send random data to SCSI until not busy ???
         sta     REG_IO_5380_RST,y
FN_2C_retry:
         sta     REG_5380_DATA_OUT,y
         lda     #$11
         sta     REG_5380_ICMD,y ;assert data bus and ACK
         lda     REG_5380_STAT,y
         lda     #$00
         sta     REG_5380_ICMD,y ;deassert all
         lda     REG_5380_STAT,y
         and     #$40
         bne     FN_2C_retry ;retry if BUSY
         rts

         .byte   $ac
         .byte   $1a
         .byte   $c8
         .byte   $60

LCCE3:   ldx     DEV_IDX
         lda     #$31
@LCCE8:  dex
         bmi     @LCCF0
         clc
         adc     #$1b
         bne     @LCCE8
@LCCF0:  sta     TMP_PTR0
         lda     #$c9
         sta     TMP_PTR0+1
         ldx     #$a4
         lda     #$00
@LCCFA:  sta     DBITAB_BASE,x
         dex
         bne     @LCCFA
         sta     DBITAB_BASE
         rts

FN_9C:   lda     #$a4
         jsr     CALL_FN_XC ;CALL_FN_A4
         lda     #$85
         jmp     CALL_FN_XC ;CALL_FN_85

FN_7C:   lda     CALL_TYPE
         cmp     #$01
         beq     IS_RW_prodos
         bne     IS_RW_smartport

RW_OP:   lda     DEV_STATUS ;get here if CMD is read or write op (1,2,8 or 9)
         cmp     #$f8
         bne     @LCD31
         lda     UNK_c827+2 ;add 5 to UNK_c827
         clc
         adc     #$05
         sta     UNK_c827+2
         bcc     @LCD31
         inc     UNK_c827+1
         bne     @LCD31
         inc     UNK_c827
@LCD31:  ldy     #$02
         clc                ;UNK_c827 = UNK_c827 + PART_START
@add_loop:
         lda     UNK_c827,y
         adc     PART_START,y
         sta     UNK_c827,y
         dey
         bpl     @add_loop
         lda     LBA_c8db+2
         sbc     #$1f
         bcs     ERR_BADBLOCK ;branch if *($c8dd) > $20 ($1f ?)
         lda     LBA_c8db+2 ;compare *($c8dd) and *($UNK_c827) - $c8dd seems in reverse endian
         sec                ;there might be a bug in the comparison
         sbc     UNK_c827
         bcc     FN_7C_end
         bne     ERR_BADBLOCK
         lda     LBA_c8db+1
         sec
         sbc     UNK_c827+1
         bcc     FN_7C_end
         bne     ERR_BADBLOCK
         lda     LBA_c8db
         sec
         sbc     UNK_c827+2
         bcc     FN_7C_end
         bne     ERR_BADBLOCK
FN_7C_end:
         clc
         ldy     SAVE_Y
         rts

ERR_BADBLOCK:
         lda     #$2d
         ldy     SAVE_Y
         jmp     CALL_FN_60_RET ;return fail

IS_RW_prodos:
         lda     PD_PAR_CMD
         jmp     FN_7C_skip

IS_RW_smartport:
         lda     SAVE_SP_CMD_B
FN_7C_skip:
         cmp     #$01
         beq     RW_OP
         cmp     #$02
         beq     RW_OP
         cmp     #$08
         beq     RW_OP
         cmp     #$09
         beq     RW_OP
         bne     FN_7C_end

LCD8F:   tya
         clc
         adc     #$09
         tax
         lda     #$00
         sta     TCOUNT_B2
         sta     TCOUNT_B0
@LCD9C:  lda     P8_IBAKVER,x
         and     #$08
         bne     @LCDAD
         dec     TCOUNT_B0
         bne     @LCD9C
         dec     TCOUNT_B2
         bne     @LCD9C
@LCDAD:  rts

FN_6C:   jsr     LCD8F
         jsr     SET_TIMEOUT
@LCDB4:  lda     REG_5380_STAT2,x
         bmi     @LCDDA
@LCDB9:  jsr     DEC_TIMEOUT
         bcs     LCDF2
         lda     P8_IBAKVER-1,x
         and     #$20
         bne     @LCDCC
         lda     REG_5380_STAT2,x
         bmi     @LCDDA
         bpl     @LCDB9

@LCDCC:  lda     REG_5380_STAT2,x
         bmi     @LCDDA
         lda     P8_IBAKVER,x
         and     #$08
         beq     LCDEA
         bne     @LCDB9

@LCDDA:  lda     (BUF_PTR_L),y
         sta     P8_KVERSION,x
         iny
         bne     @LCDB4
         inc     BUF_PTR_H
         inc     DEV_STATUS-1
         jmp     @LCDB4

LCDEA:   dey
         sty     $c9f1
         ldy     SAVE_Y
         rts

LCDF2:   lda     #$27
         sta     RET_CODE
         bne     LCDEA

FN_5C:   jsr     LCD8F
         jsr     SET_TIMEOUT
         jsr     LCF37
@LCE02:  lda     REG_5380_STAT2,x
         bmi     @LCE28
@LCE07:  jsr     DEC_TIMEOUT
         bcs     @LCE43
         lda     P8_IBAKVER-1,x
         and     #$20
         bne     @LCE1A
         lda     REG_5380_STAT2,x
         bmi     @LCE28
         bpl     @LCE07

@LCE1A:  lda     REG_5380_STAT2,x
         bmi     @LCE28
         lda     P8_IBAKVER,x
         and     #$08
         beq     @LCE3C
         bne     @LCE07

@LCE28:  lda     [BUF_PTR_L],y
         sta     P8_KVERSION,x
         iny
         bne     @LCE02
         inc     DEV_STATUS-1
         inc     BUF_PTR_H
         bne     @LCE02
         inc     BUF_PTR_VH
         jmp     @LCE02

@LCE3C:  dey
         sty     $c9f1
         jmp     LCF4C

@LCE43:  jmp     LCEAC

FN_4C:   jsr     LCD8F
         jsr     SET_TIMEOUT
         jsr     LCF37
@LCE4F:  lda     REG_5380_STAT2,x
         bmi     @LCE75
@LCE54:  jsr     DEC_TIMEOUT
         bcs     LCEAC
         lda     P8_IBAKVER-1,x
         and     #$20
         bne     @LCE67
         lda     REG_5380_STAT2,x
         bmi     @LCE75
         bpl     @LCE54

@LCE67:  lda     REG_5380_STAT2,x
         bmi     @LCE75
         lda     P8_IBAKVER,x
         and     #$08
         beq     @LCEA9
         bne     @LCE54

@LCE75:  lda     [BUF_PTR_L],y
         sta     P8_KVERSION,x
         iny
         bne     @LCE4F
         dec     TCOUNT_B2
         beq     @LCE8B
         inc     BUF_PTR_H
         bne     @LCE4F
         inc     BUF_PTR_VH
         jmp     @LCE4F

@LCE8B:  lda     #$00
         sta     TCOUNT_B2
@LCE90:  lda     REG_5380_STAT2,x
         bmi     @LCEA3
         lda     P8_IBAKVER,x
         and     #$08
         beq     @LCEA9
         dec     TCOUNT_B2
         beq     LCEAC
         bne     @LCE90

@LCEA3:  sta     P8_KVERSION,x
         clc
         bcc     @LCE90

@LCEA9:  jmp     LCF4C

LCEAC:   jsr     LCF4C
         lda     #$27
         sta     RET_CODE
         jmp     LCDEA

SET_TIMEOUT:
         lda     #$00
         tay
         sta     TCOUNT_B0
         sta     TCOUNT_B1
         lda     TIMEOUT
         sta     TCOUNT_B2
         rts

DEC_TIMEOUT:
         dec     TCOUNT_B0
         bne     @LCED6
         dec     TCOUNT_B1
         bne     @LCED6
         dec     TCOUNT_B2
         beq     @LCED8
@LCED6:  clc
         rts

@LCED8:  sec
         rts

FN_3C:   jsr     SET_TIMEOUT
         lda     #$02
         sta     TCOUNT_B2
         jsr     LCF37
         ldx     SAVE_Y
@LCEE8:  lda     REG_IO_DRQ,x
         bmi     @LCEF9
         dec     TCOUNT_B0
         bne     @LCEE8
         dec     TCOUNT_B1
         beq     @LCF2E
         bne     @LCEE8

@LCEF9:  lda     REG_IO_PDMA_DACK,x
         sta     [BUF_PTR_L],y
         iny
         bne     @LCEE8
         dec     TCOUNT_B2
         beq     @LCF0F
         inc     BUF_PTR_H
         bne     @LCEE8
         inc     BUF_PTR_VH
         jmp     @LCEE8

@LCF0F:  sty     TCOUNT_B2
@LCF12:  lda     REG_IO_DRQ,x
         bmi     @LCF25
         lda     REG_5380_STAT2,x
         and     #$08
         beq     @LCF2B
         dec     TCOUNT_B2
         beq     @LCF2E
         bne     @LCF12

@LCF25:  lda     REG_IO_PDMA_DACK,x
         clc
         bcc     @LCF12

@LCF2B:  jmp     LCF4C

@LCF2E:  jsr     LCF4C
         lda     #$27
         sta     RET_CODE
         rts

LCF37:   lda     CALL_TYPE
         and     #$40
         beq     @LCF4B
         lda     IIgs_PDMA
         beq     @LCF4B
         lda     SAVE_CYAREG
         ora     #$80
         sta     CYAREG
@LCF4B:  rts

LCF4C:   lda     CALL_TYPE
         and     #$40
         beq     @LCF61
         lda     IIgs_PDMA
         beq     @LCF61
         lda     SAVE_CYAREG
         sta     CYAREG
         ldy     SAVE_Y
@LCF61:  rts

FN_8C:   lda     #$00
         sta     XFER_MODE
         sta     IIgs_PDMA
         php
         sei
         lda     SLTROMSEL
         sta     SAVE_CYAREG
         lda     #$54
         sta     SLTROMSEL
         ldx     #$05
@LCF79:  lda     SLTROMSEL
         cmp     #$54
         bne     @LCFA6
         dex
         bne     @LCF79
         lda     SAVE_CYAREG
         sta     SLTROMSEL
         lda     #$01
         sta     XFER_MODE
         sta     IIgs_PDMA
         lda     BOOT_SEQ
         cmp     #$55
         bne     @LCF9D
         lda     #$08
         sta     SHADOW
@LCF9D:  lda     CYAREG
         sta     SAVE_CYAREG
         ldy     SAVE_Y
@LCFA6:  plp
         rts

CALL_FN_60_RET:
         sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH

FN_TABLE:
         .word   FN_0C
         .word   FN_1C      ;add partition start to BLK number
         .word   FN_2C      ;send random data until not busy
         .word   FN_3C
         .word   FN_4C
         .word   FN_5C
         .word   FN_6C
         .word   FN_7C
         .word   FN_8C
         .word   FN_9C
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

         .byte   $00
         .byte   $00
         .byte   $00
         .byte   $00
