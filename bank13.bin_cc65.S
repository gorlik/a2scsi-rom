; Target assembler: cc65 v2.18.0 [--target none -C bank13.bin_cc65.cfg]
; 6502bench SourceGen v1.8.3
         .setcpu "65816"
TMP_PTR0 =       $19        ; temporary ZP pointer 
JMP_PTR  =       $1b        ; Jmp target ZP pointer 
MEM_PTR_L =      $f6        ; temporary ZP long pointer
MEM_PTR_H =      $f7
MEM_PTR_VH =     $f8
MEM_PTR_XH =     $f9
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
REG_5380_MODE_SEL = $c002   ; RW Mode select register
REG_5380_STAT2 = $c005      ; R Bus and status register
REG_IO_PDMA_DACK = $c008    ; RW PDMA/DACK
REG_IO_BANK_SEL = $c00a     ; W memory bank select
REG_IO_5380_RST = $c00b     ; W 5380 Reset
REG_IO_DRQ =     $c00e      ; R read DRQ on bit7
CYAREG   =       $c036      ;RW Configure Your Apple
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B2 =      $c802      ; timeout counter MSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
XFER_MODE =      $c804      ; 0x00 IIe PDMA, 0x01 IIgs PDMA, 0x02-0xff PIO 
TMP_c807 =       $c807      ; save BUF_PTR_VH ???
SAVE_CYAREG =    $c808      ; saved value of CYAREG
TMP_c80a =       $c80a      ; unknown
RET_CODE =       $c80b      ; 
BSW_TEMP =       $c80c      ; TEMP in BANKSWITCH
SCSI_CDB_CMD =   $c80e      ; SCSI CDB buffer
SLOT_OFFSET =    $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
UNK_c820 =       $c820      ; 0xff if PIO ?
DEV_SIZE =       $c827      ; device size in blocks (3-bytes reverese endian) - reused in some banks ???
TEMP_PTR_c8ca =  $c8ca      ; TEMP_BUF_PTR?
SAVE_SP2 =       $c8ed      ;saved SP - also used a random temp
IS_IIgs  =       $c8f3      ;0x01 if IIgs
SAVE_XFER_MODE = $c91f
DEV_STATUS =     $c9f3      ; seems a copy of device status from DIBTAB
PTR_SAVE =       $c9f4      ; TMP PTR save location

         .org    $cc00
         .a8
         .i8
FN_0D:   lda     #$86       ;fill DIBTAB at TMP_PTR0 
         ldy     #$00
         sty     TMP_c80a   ;TMP_c80a=0 - unnecessary as it is done again below
         sta     (TMP_PTR0),y ;at this point TMP_PTR0 points to DIBTAB[DEV_IDX]
         iny
         iny
         jsr     CPY_BLK_SIZE
         jsr     FN_4D      ;INQUIRY_CA00
         jsr     FILL_DEV_STATUS
         jsr     IDSTRING_CPY
         lda     #$00
         sta     TMP_c80a   ;TMP_c80a=0 - string len
@next_char:
         lda     $ca00,x
         cmp     #$20
         bmi     @skip_copy ;branch if non printable char (<$20)
         beq     @skip_copy ;branch if char is space ($20)
         cmp     #$7a
         bpl     @skip_copy ;branch if not printable >$7a
         sta     (TMP_PTR0),y ;copy char
         iny
         inc     TMP_c80a   ;str_len++
@skip_copy:
         inx
         cpx     #$21
         bpl     @copy_done ;branch if x>=$21
         lda     TMP_c80a
         cmp     #$10
         beq     @copy_done ;branch if str_len==$10
         bmi     @next_char ;else process next char
         beq     @copy_done ;redundant
@copy_done:
         tya
         pha
         ldy     #$06
         lda     TMP_c80a
         sta     (TMP_PTR0),y ;store ID string lenght into DIBTAB
         pla
         tay
         lda     #$10       ;check if str_len < $10
         sec
         sbc     TMP_c80a
         sta     TMP_c80a
         beq     @pad_done
         bmi     @pad_done
         lda     #$20       ;pad the string with spaces
@more_spaces:
         sta     (TMP_PTR0),y
         iny
         dec     TMP_c80a
         bne     @more_spaces
@pad_done:
         jsr     FILL_DEV_TYPE_SUBTYPE
         ldx     #$01
@cpy_loop:
         iny
         lda     CONST_0002,x
         sta     (TMP_PTR0),y
         dex
         bpl     @cpy_loop  ;DIBTAB ROM_VERSION=$0200
         ldy     SLOT_OFFSET
         rts

CPY_BLK_SIZE:
         ldx     #$02       ;copy BLK_SIZE from $c825 ???
@cpy_loop:
         lda     DEV_SIZE,x ;UNK_c827 should be BLK_SIZE here
         sta     (TMP_PTR0),y
         iny
         dex
         bpl     @cpy_loop
         lda     #$00
         sta     (TMP_PTR0),y
         iny
         rts

FILL_DEV_STATUS:
         iny                ;check SCSI device type
         tya
         pha
         ldx     #$00
         lda     $ca00,x
         beq     @DEV_DIRECT_ACCESS
         cmp     #$01
         beq     @DEV_SEQUENTIAL
         cmp     #$02
         beq     @DEV_PRINTER
         cmp     #$04
         beq     @DEV_WORM
         cmp     #$05
         beq     @DEV_CDROM
         cmp     #$06
         beq     @DEV_SCANNER
         cmp     #$10       ;bridging expander ????
         beq     @DEV_DIRECT_ACCESS
         bne     @DEV_UNKNOWN

@DEV_DIRECT_ACCESS:
         lda     #$f8
@store_dev_status:
         sta     DEV_STATUS
         ldy     #$01
         sta     (TMP_PTR0),y
         pla
         tay
         rts

@DEV_SEQUENTIAL:
         lda     #$78
         bne     @store_dev_status

@DEV_PRINTER:
         lda     #$58       ;format bit enabled ???
         bne     @store_dev_status

@DEV_WORM:
         lda     #$f0
         bne     @store_dev_status

@DEV_CDROM:
         lda     #$b4
         bne     @store_dev_status

@DEV_SCANNER:
         lda     #$38       ;format bit enabled ???
         bne     @store_dev_status

@DEV_UNKNOWN:
         lda     #$00
         beq     @store_dev_status

FILL_DEV_TYPE_SUBTYPE:
         lda     DEV_STATUS
         cmp     #$b4
         bne     @not_cd    ;branch if not CD-ROM
         lda     #$05       ;APPLE device type 5 (CD-ROM)
         bne     @store_apl_dev_type

@not_cd: cmp     #$f8
         bne     @not_direct_acc
         lda     $ca01      ;SCSI inquiry RMB
         and     #$80       ;RMB mask
         bne     @direct_removable
         lda     #$07       ;APPLE device type HDD
         bne     @store_apl_dev_type

@direct_removable:
         tya
         pha
         lda     TMP_PTR0
         sta     SAVE_XFER_MODE ;used as local temp
         lda     TMP_PTR0+1
         sta     $c920      ;local temp
         lda     #$9c
         jsr     CALL_FN_XD ;CALL_FN_9C - TMP_PTR0=SDAT[*$c800]; get BLK_COUNT from SDAT in TMP_PTR0
         lda     #$35
         ldy     #$0e
         sta     (TMP_PTR0),y ;set SDAT timeout to $35
         lda     SAVE_XFER_MODE ;restore from used as local temp
         sta     TMP_PTR0
         lda     $c920      ;restore from local temp
         sta     TMP_PTR0+1
         pla
         tay
         lda     #$06       ;APPLE device type tape
         bne     @store_apl_dev_type

@not_direct_acc:
         cmp     #$78
         bne     @not_tape
         lda     #$06       ;APPLE device type tape
         bne     @store_apl_dev_type

@not_tape:
         cmp     #$58
         bne     @not_printer
         lda     #$09       ;APPLE device type Printer
         bne     @store_apl_dev_type

@not_printer:
         cmp     #$38
         bne     @not_scanner
         lda     #$08       ;APPLE device type scanner
         bne     @store_apl_dev_type

@not_scanner:
         lda     #$03       ;APPLE device type nonspecific
@store_apl_dev_type:
         sta     (TMP_PTR0),y
         lda     $ca01
         bpl     @not_removable
         lda     #$c0       ;APPLE subtype ext + removable
         bne     @store_apple_subtype

@not_removable:
         lda     #$a0       ;APPLE subtype ext and not removable
@store_apple_subtype:
         iny
         sta     (TMP_PTR0),y
         rts

         .byte   $4c
         .byte   $58
         .byte   $cf
CONST_0002:
         .byte   $02
         .byte   $00

FN_4D:   tya                ;INQUIRY_CA00
         pha
         ldx     #$03
@save_BP:
         lda     BUF_PTR_L,x
         sta     $c82c,x
         dex
         bpl     @save_BP   ;SAVE BUF_PTR to $c82c
         lda     TMP_PTR0
         sta     PTR_SAVE
         lda     TMP_PTR0+1
         sta     PTR_SAVE+1 ;SAVE TMP_PTR0
         lda     MEM_PTR_L
         sta     TEMP_PTR_c8ca
         lda     MEM_PTR_H
         sta     TEMP_PTR_c8ca+1
         lda     MEM_PTR_VH
         sta     $c925
         lda     MEM_PTR_XH
         sta     $c926      ;SAVE TMP_PTR (all 4 bytes)
         lda     #$00
         sta     MEM_PTR_L
         lda     #$ca
         sta     MEM_PTR_H  ;set TMP_PTR to $ca00
         ldy     #$02
         lda     MEM_PTR_L
         sta     (MEM_PTR_L),y
         iny
         lda     MEM_PTR_H
         sta     (MEM_PTR_L),y
         iny
         lda     #$00
         sta     MEM_PTR_VH
         sta     MEM_PTR_XH
         sta     (MEM_PTR_L),y
         iny
         sta     (MEM_PTR_L),y ;*(TMP_PTR+2)=TMP_PTR - *($ca02)=$ca00
         lda     #$93
         jsr     CALL_FN_XD ;CALL_FN_93 - INQUIRY
         ldx     #$03
@rest_BP:
         lda     $c82c,x
         sta     BUF_PTR_L,x
         dex
         bpl     @rest_BP   ;RESTORE BUF_PTR
         lda     PTR_SAVE
         sta     TMP_PTR0
         lda     PTR_SAVE+1
         sta     TMP_PTR0+1 ;RESTORE TMP_PTR0
         lda     TEMP_PTR_c8ca
         sta     MEM_PTR_L
         lda     TEMP_PTR_c8ca+1
         sta     MEM_PTR_H
         lda     $c925
         sta     MEM_PTR_VH
         lda     $c926
         sta     MEM_PTR_XH ;RESTORE TMP_PTR (4 bytes)
         pla
         tay
         rts

         .byte   $99
         .byte   $0b
         .byte   $c0
         .byte   $a9
         .byte   $27
         .byte   $4c
         .byte   $58
         .byte   $cf

CALL_FN_XD:
         ldy     SLOT_OFFSET
         ldx     #$0d
         jsr     BANKSWITCH
         rts

IDSTRING_CPY:
         tya
         pha
         ldx     #$00
         ldy     #$07       ;vendor position in inquiry data
@vendor_str_cpy1:
         iny
         cpy     #$18       ;stop at 16 chars
         beq     LCE01
         lda     $ca00,y
         cmp     #$20
         bmi     @vendor_str_cpy1
         beq     @vendor_str_cpy1
         cmp     #$7a
         beq     @LCDE1
         bpl     @vendor_str_cpy1
@LCDE1:  tya
         pha
dev_str_cpy2:
         inx                ;bug??? - something seems wrong with the second strcpy
         iny
         cmp     #$18
         beq     @LCDF8
         lda     $ca00,y
         cmp     #$20
         beq     @LCDF8
         bpl     dev_str_cpy2
         cmp     #$7a
         bmi     dev_str_cpy2
         beq     dev_str_cpy2
@LCDF8:  txa
         sta     TMP_c80a
         pla
         tax
         pla
         tay
         rts

LCE01:   txa
         sta     TMP_c80a
         pla
         tay
         rts

FN_1D:   lda     #$15
         jsr     CALL_FN_XD ;CALL_FN_15 - FN_35, FN_1C, FN_6A - load info from SDAT[DEV_IDX], LBA+=PART_START, memcpy($ca00,&DIBTAB[DEV_IDX])
         lda     #$bf
         jsr     CALL_FN_XD ;CALL_FN_BF - set TPM_PTR to $ca00, check if device is online
         lda     DEV_SIZE   ;no idea what is UNK_c827
         beq     @FN_1D_end
         lda     #$ff
         sta     DEV_SIZE+1
         sta     DEV_SIZE+2
@FN_1D_end:
         rts

FN_2D:   tsx
         stx     SAVE_SP2
         ldy     #$00
         txa
         cmp     #$60
         bcs     @stack_free
         lda     #$b5
         jsr     CALL_FN_XD ;CALL_FN_B5 - DMA read
         jmp     FN_2D_end

@stack_free:
         sbc     #$22
         tax
         stx     TMP_PTR0
         dex
         dex
         txs
         inx
         inx
         lda     SCSI_CDB_CMD
@LCE40:  lda     code_fragment,y
         sta     $0100,x
         inx
         iny
         cpy     #$08
         bne     @LCE58
         jsr     IS_NATIVE_MODE_REQ2
         bcs     @LCE58
         lda     #$97
         sta     $0100,x
         inx
         iny
@LCE58:  cpy     #$1e
         bne     @LCE40
         ldx     SLOT_OFFSET
         lda     #$01
         sta     TMP_PTR0+1
         lda     SAVE_CYAREG
         ora     #$80
         sta     CYAREG
         ldy     #$00
         sty     TCOUNT_B0
         sty     TCOUNT_B1
         lda     #$02
         sta     TCOUNT_B2
         jsr     SET_NATIVE_IF_NEEDED
         jmp     (TMP_PTR0)

LCE7E:   nop
         jsr     IS_NATIVE_MODE_REQ2
         bcs     @LCE86
         sec
         xce
@LCE86:  ldx     SAVE_SP2
         txs
         lda     SAVE_CYAREG
         sta     CYAREG
FN_2D_end:
         lda     #$00
         ldy     SLOT_OFFSET
         sta     REG_IO_5380_RST,y
         sta     REG_5380_MODE_SEL,y
         rts

code_fragment:
         lda     REG_IO_DRQ,x ;this fragment is copied on the stack
         bpl     @LCEAC
         lda     REG_IO_PDMA_DACK,x
         sta     (BUF_PTR_L),y
         iny
         bne     code_fragment
         jmp     @LCECE

@LCEAC:  jmp     @LCEBA

         .byte   $bd
         .byte   $0e
         .byte   $c0
         .byte   $10
         .byte   $f8
         .byte   $bd
         .byte   $08
         .byte   $c0
         .byte   $18
         .byte   $90
         .byte   $f5

@LCEBA:  dec     TCOUNT_B0
         bne     @LCEC4
         dec     TCOUNT_B1
         beq     @LCEE6
@LCEC4:  lda     REG_5380_STAT2,x
         and     #$08
         beq     @LCEEB
         jmp     (TMP_PTR0)

@LCECE:  dec     TCOUNT_B2
         beq     @LCEDC
         inc     BUF_PTR_H
         bne     @LCED9
         inc     BUF_PTR_VH
@LCED9:  jmp     (TMP_PTR0)

@LCEDC:  lda     #$13
         clc
         adc     TMP_PTR0
         sta     TMP_PTR0
         jmp     (TMP_PTR0)

@LCEE6:  lda     #$27
         sta     RET_CODE
@LCEEB:  jmp     LCE7E

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

sec_rts: sec
         rts

SET_NATIVE:
         clc
         xce
         rts

         .byte   $38
         .byte   $fb
         .byte   $60

SET_NATIVE_IF_NEEDED:
         jsr     IS_NATIVE_MODE_REQ2
         bcs     sec_rts    ;just return should be ok
         jmp     SET_NATIVE

         .byte   $20
         .byte   $14
         .byte   $cf
         .byte   $b0
         .byte   $eb
         .byte   $4c
         .byte   $01
         .byte   $cf

IS_NATIVE_MODE_REQ2:
         lda     CALL_TYPE  ;this one is reverse return value vs the one in bank 15
         and     #$40
         beq     sec_rts    ;branch if not ext call
         lda     IS_IIgs
         cmp     #$01
         bne     sec_rts    ;branch if not IIgs
         clc
         rts

FN_3D:   lda     XFER_MODE  ;auto select XFER_MODE
         cmp     #$03       ;if(XFER_MODE==3) overrides the auto selection - not documented in manual
         bne     end_sel_xfer_mode
         lda     IS_IIgs
         cmp     #$01
         bne     SET_XFER_MODE_IIe_PDMA
         sta     XFER_MODE  ;set XFER_MODE IIgs PDMA
         jmp     end_sel_xfer_mode

SET_XFER_MODE_IIe_PDMA:
         lda     #$00
         sta     XFER_MODE
end_sel_xfer_mode:
         rts

FN_5D:   lda     #$ff       ;FORCE PIO MODE
         sta     UNK_c820
         lda     XFER_MODE
         sta     TMP_c80a
         lda     #$03
         sta     XFER_MODE
         lda     BUF_PTR_VH
         sta     TMP_c807
         lda     #$00
         sta     BUF_PTR_VH
         rts

         .byte   $8d
         .byte   $0b
         .byte   $c8
         .byte   $a9
         .byte   $60
         .byte   $a2
         .byte   $00
         .byte   $4c
         .byte   $cc
         .byte   $cf
FN_TABLE:
         .word   FN_0D
         .word   FN_1D
         .word   FN_2D
         .word   FN_3D
         .word   FN_4D
         .word   FN_5D
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

         .byte   $00
         .byte   $00
         .byte   $00
         .byte   $00
