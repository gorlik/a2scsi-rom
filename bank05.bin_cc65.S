; Target assembler: cc65 v2.18.0 [--target none -C bank05.bin_cc65.cfg]
; 6502bench SourceGen v1.1.0
         .setcpu "65816"
TMP_PTR0 =       $19        ; temporary ZP pointer 
TMP_PTR1 =       $1b        ; temporary ZP pointer 
PD_PAR_UNIT =    $43        ;PRODOS input parameter UNIT number
PD_PAR_BLK_LO =  $46        ;PRODOS input parameter Block lo
PD_PAR_BLK_HI =  $47        ;PRODOS input parameter Block hi
TMP_PTR_L =      $f6        ; temporary ZP long pointer
TMP_PTR_H =      $f7
TMP_PTR_VH =     $f8
TMP_PTR_XH =     $f9
BUF_PTR_L =      $fa        ; ZP long BUF pointer
BUF_PTR_H =      $fb
BUF_PTR_VH =     $fc
BUF_PTR_XH =     $fd
ACTV_PERIP_SLOT = $07f8     ;slot num ($Cn) of active peripheral card
REG_5380_STAT2 = $c005      ; R Bus and status register
REG_IO_PDMA_DACK = $c008    ; RW PDMA/DACK
REG_IO_BANK_SEL = $c00a     ; W memory bank select
REG_IO_5380_RST = $c00b     ; W 5380 Reset
REG_IO_DRQ =     $c00e      ; R read DRQ on bit7
CYAREG   =       $c036      ;RW Configure Your Apple
DEV_IDX  =       $c800      ; index into the SDAT/DIBTAB tables
TCOUNT_B0 =      $c801      ; timeout counter LSB
TCOUNT_B1 =      $c803      ; timeout counter middle byte when using 24-bit counter
SEL_TARGET =     $c806      ; SCSI (BUS?) ID of selected target
SAVE_CYAREG =    $c808      ; saved value of CYAREG
INIT_FLAG =      $c809      ; card initialized flag (init=$77)
RET_CODE =       $c80b      ; 
BSW_SAVE_X =     $c80c      ; save X in BANKSWITCH
SAVE_Y   =       $c81a      ; slot adress (n+8)<<4 
CALL_TYPE =      $c81d      ; 0x00 std SP call - 0x40 extended SP call - 0x01 PRODOS call
BLKSIZE_H2 =     $c822      ; byte1 of block size copy
PART_START =     $c824      ; partition start (3 bytes) seems to be in reverse endian (?)
UNK_c827 =       $c827      ; 3-byte unknown in reverse endian as the above
SDAT_BASE =      $c831      ;start of SDAT table (extends to $C8A7)
TEMP_c8c6 =      $c8c6      ;unknown
TEMP_c8ca =      $c8ca      ; TEMP_BUF_PTR?
UNK_c8cc =       $c8cc      ;unknown
UNK_c8cf =       $c8cf      ; unknown
PTR_c8d7 =       $c8d7      ; temp pointer storage (?)
PTR_c8df =       $c8df      ;unknown
BLK_c8e1 =       $c8e1      ;unknown
BOOT_SEQ =       $c8e3      ;$55 if in boot process
IIgs_PDMA =      $c8f3      ;0x01 if IIgs PDMA
UNK_c8f4 =       $c8f4      ;unknown
BLKSIZE_H =      $c92f      ;byte1 of block size
BLKSIZE_L =      $c930      ;byte0 of block size
DBITAB_BASE =    $c931      ;start of DIBTAB (extends to $C9ED)
TIMEOUT  =       $c9f6      ; each unit is 1.25s
PD_UNIT  =       $c9fd      ; PRODOS UNIT from the parameter if prodos call

         .org    $cc00
         .a8
         .i8
ENABLE_NATIVE:
         clc                ;enable 65816 native mode
         xce
         rts

DISABLE_NATIVE_IF_NEEDED:
         lda     CALL_TYPE
         and     #$40
         beq     @DISABLE_NATIVE_end ;branch if not ext call
         lda     IIgs_PDMA
         beq     @DISABLE_NATIVE_end ;branch if not IIgs
         sec
         xce                ;disable native mode
@DISABLE_NATIVE_end:
         rts

CALL_FN_8C:
         lda     #$8c
CALL_FN_X5:
         ldx     #$05
         jsr     BANKSWITCH
         rts

CLR_PART_START:
         lda     #$00
         sta     PART_START
         sta     PART_START+1
         sta     PART_START+2
         rts

SET_BUFPTR_CA00:
         lda     #$00
         sta     BUF_PTR_VH
         sta     BUF_PTR_XH
         sta     BUF_PTR_L
         lda     #$ca
         sta     BUF_PTR_H
         rts

RESTORE_BUF_PTR_c8ca:
         lda     TEMP_c8ca
         sta     BUF_PTR_L
         lda     TEMP_c8ca+1
         sta     BUF_PTR_H
         rts

SAVE_BUF_PTR_c8ca:
         lda     BUF_PTR_L
         sta     TEMP_c8ca
         lda     BUF_PTR_H
         sta     TEMP_c8ca+1
         rts

         .byte   $a5
         .byte   $fa
         .byte   $8d
         .byte   $df
         .byte   $c8
         .byte   $a5
         .byte   $fb
         .byte   $8d
         .byte   $e0
         .byte   $c8
         .byte   $60

RESTORE_BUF_PTR_c8df:
         lda     PTR_c8df
         sta     BUF_PTR_L
         lda     PTR_c8df+1
         sta     BUF_PTR_H
         rts

FN_95:   inc     UNK_c8f4   ;fill table entry (???)
         lda     BUF_PTR_L
         sta     PTR_c8d7
         lda     BUF_PTR_H
         sta     PTR_c8d7+1
         lda     PD_PAR_BLK_LO
         sta     BLK_c8e1
         lda     PD_PAR_BLK_HI
         sta     BLK_c8e1+1
         lda     #$56
         jsr     CALL_FN_X5 ;CALL_FN_56
         lda     #$37
         jsr     CALL_FN_X5 ;CALL_FN_37
         lda     UNK_c8cf
         bne     @LCCDD
         lda     #$57
         jsr     CALL_FN_X5 ;CALL_FN_57
         lda     TMP_PTR0
         sta     BUF_PTR_L
         lda     TMP_PTR0+1
         sta     BUF_PTR_H
         lda     #$86
         ldx     #$00
         sta     (BUF_PTR_L,x)
         inc     BUF_PTR_L
         lda     BUF_PTR_L
         sta     TMP_PTR_L
         lda     BUF_PTR_H
         sta     TMP_PTR_H
         lda     #$00
         sta     TMP_PTR_VH
         sta     TMP_PTR_XH
         ldy     #$02
         lda     TMP_PTR_L
         sta     (TMP_PTR_L),y
         iny
         lda     TMP_PTR_H
         sta     (TMP_PTR_L),y
         ldy     SAVE_Y
         jsr     SAVE_BUF_PTR_c8ca
         lda     #$c3
         jsr     CALL_FN_X5 ;CALL_FN_C3
         jsr     CLR_PART_START
         jsr     RESTORE_BUF_PTR_c8ca
         ldx     #$02
         ldy     #$0b
@LCCC8:  lda     PART_START,x
         sta     (BUF_PTR_L),y
         dey
         dex
         bpl     @LCCC8
         lda     SEL_TARGET
         ldy     #$0c
         sta     (BUF_PTR_L),y
         iny
         lda     #$0c
         sta     (BUF_PTR_L),y
@LCCDD:  jsr     RESTORE_BUF_PTR_c8df
         ldy     SAVE_Y
         lda     PTR_c8d7
         sta     BUF_PTR_L
         lda     PTR_c8d7+1
         sta     BUF_PTR_H
         lda     BLK_c8e1
         sta     PD_PAR_BLK_LO
         lda     BLK_c8e1+1
         sta     PD_PAR_BLK_HI
         ldy     SAVE_Y
         rts

FN_05:   lda     #$0c       ;init card
         sta     TIMEOUT
         lda     #$15
         sta     REG_IO_BANK_SEL,y ;switch to RAM bank 1
         lda     #$60
         sta     $c800      ;put RTS to RAM BANK1 entry point ???
         sta     $c803
         sta     $c806
         lda     #$05
         sta     REG_IO_BANK_SEL,y ;back to RAM bank 0
         lda     #$05
         sta     UNK_c8cc
         lda     INIT_FLAG  ;check if already initialized
         cmp     #$77
         beq     init_done  ;branch if already init
         jsr     Zero_tables ;Fill SDAT and DIBTAB with zeros
FN_A5:   jsr     CALL_FN_8C
         lda     #$00
         sta     UNK_c8f4
         sta     DEV_IDX
         lda     #$06       ;scan the bus starting with dev 6
         sta     TEMP_c8c6
@FN_05_next_device:
         jsr     ID_TO_BUS  ;convert ID to bus ID (1<<id)
         lda     #$00
         sta     RET_CODE
         lda     #$46
         jsr     CALL_FN_X5 ;CALL_FN_46
         lda     RET_CODE
         bne     @LCD49
         jsr     FN_95
@LCD49:  dec     TEMP_c8c6
         lda     TEMP_c8c6
         bpl     @FN_05_next_device ;loop through all the IDs
         lda     UNK_c8f4
         beq     LCD64
         lda     #$77
         sta     INIT_FLAG
LCD5B:   lda     #$00
         sta     RET_CODE
         sta     REG_IO_5380_RST,y
init_done:
         rts

LCD64:   lda     BOOT_SEQ
         cmp     #$55
         beq     LCD5B      ;branch if in boot sequence
         lda     #$27
         jsr     CALL_FN_60_RET ;ERROR_IOERROR
ID_TO_BUS:
         ldx     TEMP_c8c6
         lda     ID_TO_BUS_TABLE,x
         sta     SEL_TARGET
         rts

ID_TO_BUS_TABLE:
         .byte   $01        ;table of ID to bus ID value
         .byte   $02
         .byte   $04
         .byte   $08
         .byte   $10
         .byte   $20
         .byte   $40

Zero_tables:
         ldx     #$76       ;Fill SDAT and DIBTAB with zeros
         lda     #$00
@ZT_loop1:
         sta     SDAT_BASE,x
         sta     DBITAB_BASE,x
         dex
         bpl     @ZT_loop1
         ldx     #$6b
         lda     #$00
@ZT_loop2:
         sta     $c982,x    ;clear memory at $c982 for $6b bytes
         dex
         bpl     @ZT_loop2
         rts

FN_35:   ldx     DEV_IDX    ;get SDAT info (include partition offset)
         lda     #$31       ;find the SDAT entry for DEV_IDX
@FN_35_loop1:
         dex
         bmi     @LCDA7
         clc
         adc     #$11
         jmp     @FN_35_loop1

@LCDA7:  sta     TMP_PTR0   ;A contains the SDAT offset
         lda     #$c8
         sta     TMP_PTR0+1 ;TMP_PTR0 points to SDAT entry
         ldy     #$07
         lda     (TMP_PTR0),y ;get bytes per block byte 1
         sta     BLKSIZE_H
         sta     BLKSIZE_H2
         iny
         lda     (TMP_PTR0),y ;get bytes per block byte 0 (should be 0)
         sta     BLKSIZE_L
         ldy     #$0c
         ldx     #$02
FN_35_part_cpy_loop:
         lda     (TMP_PTR0),y ;copy partition start
         sta     PART_START,x
         dey
         dex
         bpl     FN_35_part_cpy_loop
         ldy     #$0d
         lda     (TMP_PTR0),y ;get software ID code from SDAT entry
         sta     SEL_TARGET
         iny
         lda     (TMP_PTR0),y ;get TIMEOUT from SDAT entry
         sta     TIMEOUT
         ldy     SAVE_Y
         rts

         .byte   $ac
         .byte   $1a
         .byte   $c8
         .byte   $4c
         .byte   $6b
         .byte   $cd

CALL_FN_1C:
         lda     #$1c
         jsr     CALL_FN_X5 ;CALL_FN_1C
         rts

FN_15:   lda     IIgs_PDMA
         cmp     #$01
         bne     @not_2gs
         lda     CYAREG
         sta     SAVE_CYAREG
@not_2gs:
         jsr     FN_35      ;load info from SDAT entry
         jsr     CALL_FN_1C ;CALL_FN_1C
         jsr     SET_BUFPTR_CA00
         lda     #$6a
         jsr     CALL_FN_X5 ;CALL_FN_6A
         rts

FN_45:   ldx     $00        ;next boot device ???
         bne     @LCE12
         ldx     $01
         cpx     ACTV_PERIP_SLOT
         bne     @LCE12
         lda     #$80
         bne     @LCE14     ;CALL_FN_80

@LCE12:  lda     #$22
@LCE14:  jsr     BANKSWITCH ;CALL_FN_22
FN_25:   jsr     LCEC8
FN_75:   jsr     LCE31
FN_85:   jsr     SAVE_TMP_PTR0_c829_3b
         lda     IIgs_PDMA
         cmp     #$01
         bne     @not_2gs
         lda     CYAREG
         sta     SAVE_CYAREG
@not_2gs:
         ldy     SAVE_Y
         rts

LCE31:   jsr     COPY_PD_UNIT
         lda     #$31
         sta     TMP_PTR0
         lda     #$c8
         sta     TMP_PTR0+1 ;TMP_PTR0=SDAT_BASE
         lda     #$01
         sta     TCOUNT_B0
         ldx     #$06
         ldy     #$00
@SDAT_loop:
         lda     (TMP_PTR0),y ;search for device in the DEV_IDX position in SDAT ????
         cmp     #$86
         bne     @SDAT_next_entry ;branch if SDAT entry is invalid
         lda     DEV_IDX
         cmp     TCOUNT_B0
         beq     GET_DEV_IDX_X_REV
         inc     TCOUNT_B0
@SDAT_next_entry:
         lda     TMP_PTR0
         clc
         adc     #$11
         sta     TMP_PTR0
         dex
         bpl     @SDAT_loop
         lda     BOOT_SEQ
         cmp     #$55
         bne     @LCE6B     ;branch if not boot sequence
         ldx     #$01
         bne     GET_DEV_IDX_X_REV ;no idea why device 5 is selected

@LCE6B:  lda     PD_UNIT
         cmp     #$20
         bne     @LCE74
         beq     @LCE78

@LCE74:  cmp     #$a0
         bne     ERROR_NODRIVE_DUP
@LCE78:  lda     SAVE_Y
         cmp     #$d0
         bne     ERROR_NODRIVE_DUP
         lda     DEV_IDX
         sec
         sbc     #$02
         sta     DEV_IDX
         bmi     ERROR_NODRIVE_DUP
         bpl     LCE31

ERROR_NODRIVE_DUP:
         lda     CALL_TYPE  ;likely unnecessary function
         cmp     #$01
         bne     ERROR_NODRIVE
         lda     #$28       ;redundant code
         bne     LCE99      ;redundant code

ERROR_NODRIVE:
         lda     #$28
LCE99:   ldy     SAVE_Y
         jmp     CALL_FN_60_RET

GET_DEV_IDX_X_REV:
         lda     ID_TO_BUS_ID_REV_TABLE,x
         sta     SEL_TARGET
         lda     ID_TO_ID_REV_TABLE,x
         sta     DEV_IDX
         rts

ID_TO_BUS_ID_REV_TABLE:
         .byte   $40
         .byte   $20
         .byte   $10
         .byte   $08
         .byte   $04
         .byte   $02
         .byte   $01
ID_TO_ID_REV_TABLE:
         .byte   $06
         .byte   $05
         .byte   $04
         .byte   $03
         .byte   $02
         .byte   $01
         .byte   $00

SAVE_TMP_PTR0_c829_3b:
         ldx     #$02       ;copy 3 bytes from TMP_PTR0 to $c829
         ldy     #$04
@cpy_loop_3b:
         lda     (TMP_PTR0),y
         sta     UNK_c827,x
         dey
         dex
         bpl     @cpy_loop_3b
         rts

LCEC8:   jsr     COPY_PD_UNIT ;seems code to find the DEV_IDX from the prodos unit
         lda     PD_UNIT    ;will fail if called from a smartport path
         clc
         sbc     #$80
         bcs     @LCEEE
         ldx     #$01
@LCED5:  stx     DEV_IDX
         lda     SAVE_Y
         cmp     #$d0
         bne     @LCEED
         lda     PD_UNIT
         and     #$7f
         cmp     #$20
         bne     @LCEED
         inx
         inx
         stx     DEV_IDX
@LCEED:  rts

@LCEEE:  ldx     #$02
         bne     @LCED5

COPY_PD_UNIT:
         lda     CALL_TYPE  ;should not be called from smartport path
         cmp     #$01
         bne     @LCEFE
         lda     PD_PAR_UNIT
         sta     PD_UNIT
@LCEFE:  rts

PDMA_INIT:
         jsr     ENABLE_NATIVE_IF_NEEDED
         tya
         tax
         ldy     #$00
         sty     TCOUNT_B0
         sty     TCOUNT_B1
         rts

FN_65:   jsr     PDMA_INIT  ;PDMA WRITE
         txa
         clc
         adc     #$09       ;adding 9 seem totally unnecessary
         tax
@wait_for_DRQ_write:
         lda     REG_IO_DRQ-9,x ;REG_IO_DRQ
         bmi     @Write_data ;branch if DRQ asserted
         lda     REG_5380_STAT2-9,x
         and     #$08
         beq     FN_65_end  ;branch if phase mismatch
         dec     TCOUNT_B0
         bne     @wait_for_DRQ_write
         dec     TCOUNT_B1
         beq     RET_FAIL_27
         bne     @wait_for_DRQ_write

@Write_data:
         lda     (BUF_PTR_L),y
         sta     REG_IO_PDMA_DACK-9,x
         iny
         bne     @wait_for_DRQ_write
         inc     BUF_PTR_H
         jmp     @wait_for_DRQ_write

FN_65_end:
         ldy     SAVE_Y
         jsr     DISABLE_NATIVE_IF_NEEDED
func_rts:
         rts

RET_FAIL_27:
         lda     #$27
         sta     RET_CODE
         bne     FN_65_end

FN_55:   jsr     PDMA_INIT  ;PDMA READ
         ldx     SAVE_Y
@wait_for_DRQ_read:
         lda     REG_IO_DRQ,x
         bmi     @Read_data ;branch if DRQ asserted
         lda     REG_5380_STAT2,x
         and     #$08
         beq     FN_65_end  ;branch if phase mismatch
         dec     TCOUNT_B0
         bne     @wait_for_DRQ_read
         dec     TCOUNT_B1
         beq     RET_FAIL_27
         bne     @wait_for_DRQ_read

@Read_data:
         lda     REG_IO_PDMA_DACK,x
         sta     (BUF_PTR_L),y
         iny
         bne     @wait_for_DRQ_read
         inc     BUF_PTR_H
         lda     BUF_PTR_H
         cmp     #$cf
         bne     @LCF7A
         lda     #$ca
         sta     BUF_PTR_H  ;wrap around buffer
@LCF7A:  jmp     @wait_for_DRQ_read

ENABLE_NATIVE_IF_NEEDED:
         lda     CALL_TYPE
         and     #$40
         beq     func_rts
         jmp     ENABLE_NATIVE

FN_B5:   lda     CALL_TYPE
         and     #$40
         beq     CALL_FN_81
         lda     #$3c
         bne     LCF94      ;CALL_FN_3C

CALL_FN_81:
         lda     #$81       ;CALL_FN_81
LCF94:   jmp     CALL_FN_X5

CALL_FN_60_RET:
         sta     RET_CODE
         lda     #$60
         ldx     #$00
         jmp     BANKSWITCH

FN_TABLE:
         .word   FN_05
         .word   FN_15
         .word   FN_25
         .word   FN_35      ;load info from SDAT entry
         .word   FN_45      ;boot failure
         .word   FN_55
         .word   FN_65
         .word   FN_75
         .word   FN_85
         .word   FN_95
         .word   FN_A5
         .word   FN_B5
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
