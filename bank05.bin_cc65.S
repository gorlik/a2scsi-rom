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
BLKSIZE_H2 =     $c822      ; copy of byte1 of block size
PART_START =     $c824      ; partition start (3 bytes) seems to be in reverse endian (?)
UNK_c827 =       $c827      ; 3-byte unknown in reverse endian as the above
SDAT_BASE =      $c831      ;start of SDAT table (extends to $C8A7)
CUR_DEV_ID =     $c8c6      ;current DEV ID being scanned
TEMP_PTR_c8ca =  $c8ca      ; TEMP_BUF_PTR?
UNK_c8cc =       $c8cc      ;unknown
UNK_c8cf =       $c8cf      ; $00 if failed to read Partition Map. $ff if PM detected
PTR_c8d7 =       $c8d7      ; temp pointer storage (?)
PTR_c8df =       $c8df      ;unknown
BLK_c8e1 =       $c8e1      ;unknown
BOOT_SEQ =       $c8e3      ;$55 if in boot process
IS_IIgs  =       $c8f3      ;0x01 if IIgs
UNK_c8f4 =       $c8f4      ;unknown
BLKSIZE_H =      $c92f      ;byte1 of block size - reverse endian
BLKSIZE_L =      $c930      ;byte0 of block size - reverse endian
DIBTAB_BASE =    $c931      ;start of DIBTAB (extends to $C9ED)
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
         lda     IS_IIgs
         beq     @DISABLE_NATIVE_end ;branch if not IIgs
         sec
         xce                ;disable native mode
@DISABLE_NATIVE_end:
         rts

CALL_FN_8C:
         lda     #$8c       ;CALL_FN_8C - detect IIgs
CALL_FN_X5:
         ldx     #$05
         jsr     BANKSWITCH ;CALL_FN_X5
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
         lda     TEMP_PTR_c8ca
         sta     BUF_PTR_L
         lda     $c8cb
         sta     BUF_PTR_H
         rts

SAVE_BUF_PTR_c8ca:
         lda     BUF_PTR_L
         sta     TEMP_PTR_c8ca
         lda     BUF_PTR_H
         sta     $c8cb
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
         sta     PTR_c8d7+1 ;SAVE BUF_PTR to PTR_c8d7
         lda     PD_PAR_BLK_LO
         sta     BLK_c8e1
         lda     PD_PAR_BLK_HI
         sta     BLK_c8e1+1 ;SAVE BLK number to BLK_c8e1
         lda     #$56
         jsr     CALL_FN_X5 ;CALL_FN_56 - WAIT TEST_UNIT_READY
         lda     #$37
         jsr     CALL_FN_X5 ;CALL_FN_37
         lda     UNK_c8cf
         bne     @LCCDD
         lda     #$57
         jsr     CALL_FN_X5 ;CALL_FN_57 - return first empty SDAT entry in TMP_PTR0
         lda     TMP_PTR0
         sta     BUF_PTR_L
         lda     TMP_PTR0+1
         sta     BUF_PTR_H  ;BUF_PTR=TMP_PTR0
         lda     #$86
         ldx     #$00
         sta     (BUF_PTR_L,x) ;write SDAT signature
         inc     BUF_PTR_L
         lda     BUF_PTR_L
         sta     TMP_PTR_L
         lda     BUF_PTR_H
         sta     TMP_PTR_H
         lda     #$00
         sta     TMP_PTR_VH
         sta     TMP_PTR_XH ;TMP_PTR=++BUF_PTR;
         ldy     #$02
         lda     TMP_PTR_L
         sta     (TMP_PTR_L),y
         iny
         lda     TMP_PTR_H
         sta     (TMP_PTR_L),y
         ldy     SAVE_Y
         jsr     SAVE_BUF_PTR_c8ca
         lda     #$c3
         jsr     CALL_FN_X5 ;CALL_FN_C3 - READ CAPACITY
         jsr     CLR_PART_START
         jsr     RESTORE_BUF_PTR_c8ca
         ldx     #$02
         ldy     #$0b
@LCCC8:  lda     PART_START,x
         sta     (BUF_PTR_L),y
         dey
         dex
         bpl     @LCCC8     ;copy PART_START to SDAT
         lda     SEL_TARGET
         ldy     #$0c
         sta     (BUF_PTR_L),y ;copy SEL_TARGET to SDAT
         iny
         lda     #$0c
         sta     (BUF_PTR_L),y ;set device TIMOEUT in SDAT
@LCCDD:  jsr     RESTORE_BUF_PTR_c8df
         ldy     SAVE_Y
         lda     PTR_c8d7
         sta     BUF_PTR_L
         lda     PTR_c8d7+1
         sta     BUF_PTR_H  ;RESTORE BUF_PTR from c8d7
         lda     BLK_c8e1
         sta     PD_PAR_BLK_LO
         lda     BLK_c8e1+1
         sta     PD_PAR_BLK_HI ;RESTORE PD_PAR_BLK from BLK_c8e1
         ldy     SAVE_Y
         rts

FN_05:   lda     #$0c       ;init card
         sta     TIMEOUT
         lda     #$15
         sta     REG_IO_BANK_SEL,y ;switch to RAM bank 1
         lda     #$60
         sta     $c800      ;put RTS to additional BANK 01 entry points
         sta     $c803      ;put rts in Patch1Call entry point
         sta     $c806      ;put RTS to additional BANK 01 entry points
         lda     #$05
         sta     REG_IO_BANK_SEL,y ;back to RAM bank 0
         lda     #$05
         sta     UNK_c8cc
         lda     INIT_FLAG  ;check if already initialized
         cmp     #$77
         beq     init_done  ;branch if already init
         jsr     Zero_tables ;Fill SDAT and DIBTAB with zeros
FN_A5:   jsr     CALL_FN_8C ;detect IIgs
         lda     #$00
         sta     UNK_c8f4
         sta     DEV_IDX
         lda     #$06       ;scan the bus starting with dev 6
         sta     CUR_DEV_ID
@FN_05_next_device:
         jsr     ID_TO_SEL_TARGET ;convert ID to bus ID (1<<id)
         lda     #$00
         sta     RET_CODE
         lda     #$46
         jsr     CALL_FN_X5 ;CALL_FN_46 - clear SCSI BUS and TEST_UNIT READY
         lda     RET_CODE
         bne     @inc_dev_id ;branch if no device found
         jsr     FN_95
@inc_dev_id:
         dec     CUR_DEV_ID
         lda     CUR_DEV_ID
         bpl     @FN_05_next_device ;loop through all the IDs
         lda     UNK_c8f4
         beq     LCD64
         lda     #$77
         sta     INIT_FLAG
RET_00:  lda     #$00
         sta     RET_CODE
         sta     REG_IO_5380_RST,y
init_done:
         rts

LCD64:   lda     BOOT_SEQ
         cmp     #$55
         beq     RET_00     ;branch if in boot sequence
         lda     #$27
         jsr     CALL_FN_60_RET ;ERROR_IOERROR - bug should this be a jmp?
ID_TO_SEL_TARGET:
         ldx     CUR_DEV_ID
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
         sta     DIBTAB_BASE,x
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
@dev_idx_loop:
         dex
         bmi     @dev_idx_match
         clc
         adc     #$11
         jmp     @dev_idx_loop

@dev_idx_match:
         sta     TMP_PTR0   ;A contains the SDAT offset
         lda     #$c8
         sta     TMP_PTR0+1 ;TMP_PTR0 points to SDAT entry
         ldy     #$07
         lda     (TMP_PTR0),y ;get bytes per block byte 1
         sta     BLKSIZE_H
         sta     BLKSIZE_H2 ;seems never used
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

FN_15:   lda     IS_IIgs
         cmp     #$01
         bne     @not_2gs
         lda     CYAREG
         sta     SAVE_CYAREG
@not_2gs:
         jsr     FN_35      ;load info from SDAT[DEV_IDX] entry
         jsr     CALL_FN_1C ;CALL_FN_1C - add partition start to BLK number
         jsr     SET_BUFPTR_CA00
         lda     #$6a
         jsr     CALL_FN_X5 ;CALL_FN_6A - copy info from DIBTAB[DEV_IDX] to $ca00
         rts

FN_45:   ldx     $00        ;next boot device or error if last
         bne     BOOT_ERROR
         ldx     $01
         cpx     ACTV_PERIP_SLOT
         bne     BOOT_ERROR
         lda     #$80
         bne     JSR_BANKSWITCH ;CALL_FN_80 - Next boot device

BOOT_ERROR:
         lda     #$22
JSR_BANKSWITCH:
         jsr     BANKSWITCH ;CALL_FN_22 - FN_4F - print "SCSI BOOT ERROR" and run basic
FN_25:   jsr     PD_UNIT_TO_IDX
FN_75:   jsr     SDAT_LOOKUP ;TMP_PTR0=&SDAT[DEV_IDX]
FN_85:   jsr     GET_UNK_c827_FROM_PTR0_2 ;UNK_c827=BLK_COUNT from SDAT entry pointed by TMP_PTR0
         lda     IS_IIgs
         cmp     #$01
         bne     @not_2gs
         lda     CYAREG
         sta     SAVE_CYAREG
@not_2gs:
         ldy     SAVE_Y
         rts

SDAT_LOOKUP:
         jsr     COPY_PD_UNIT
         lda     #$31
         sta     TMP_PTR0
         lda     #$c8
         sta     TMP_PTR0+1 ;TMP_PTR0=SDAT_BASE
         lda     #$01
         sta     TCOUNT_B0  ;TCOUNT_B0=0
         ldx     #$06       ;for(x=6;x>=0;x--) unclear why it count backwards as calling ADJUST will reverse again
         ldy     #$00       ;unclear why it count backwards
@SDAT_loop:
         lda     (TMP_PTR0),y ;search for device at the DEV_IDX position in SDAT ????
         cmp     #$86
         bne     @SDAT_next_entry ;branch if SDAT entry is invalid
         lda     DEV_IDX
         cmp     TCOUNT_B0
         beq     ADJUST_DEV_IDX_X_REV_RET ;branch if TCOUNT_B0==DEV_IDX
         inc     TCOUNT_B0  ;TCOUNT++
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
         bne     ADJUST_DEV_IDX_X_REV_RET ;no idea why device 5 is selected

@LCE6B:  lda     PD_UNIT    ;check if prodos unit is $20 or $a0
         cmp     #$20
         bne     @LCE74
         beq     @LCE78

@LCE74:  cmp     #$a0
         bne     ERROR_NODRIVE_DUP
@LCE78:  lda     SAVE_Y     ;Prodos unit is either $20 or $A0
         cmp     #$d0       ;is the card in slot 5 ?
         bne     ERROR_NODRIVE_DUP
         lda     DEV_IDX    ;DEV_IDX-=2
         sec
         sbc     #$02
         sta     DEV_IDX
         bmi     ERROR_NODRIVE_DUP ;branch if DEV_IDX<0
         bpl     SDAT_LOOKUP

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

ADJUST_DEV_IDX_X_REV_RET:
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

GET_UNK_c827_FROM_PTR0_2:
         ldx     #$02       ;copy 3 bytes from *(TMP_PTR0+2) to $c827
         ldy     #$04       ;PTR0 likely points to a SDAT entry
@cpy_loop_3b:
         lda     (TMP_PTR0),y ;so it copies the BLK count in regular endian
         sta     UNK_c827,x ;however UNK_c827 is often used in reverse endian
         dey
         dex
         bpl     @cpy_loop_3b
         rts

PD_UNIT_TO_IDX:
         jsr     COPY_PD_UNIT ;convert the prodos UNIT # and store it to DEV_IDX 1..4
         lda     PD_UNIT    ;will fail if called from a smartport path
         clc
         sbc     #$80
         bcs     @LCEEE
         ldx     #$01
@LCED5:  stx     DEV_IDX
         lda     SAVE_Y
         cmp     #$d0
         bne     @rts
         lda     PD_UNIT
         and     #$7f
         cmp     #$20
         bne     @rts
         inx
         inx
         stx     DEV_IDX
@rts:    rts

@LCEEE:  ldx     #$02
         bne     @LCED5

COPY_PD_UNIT:
         lda     CALL_TYPE  ;should not be called from smartport path
         cmp     #$01
         bne     @not_pd_call
         lda     PD_PAR_UNIT
         sta     PD_UNIT
@not_pd_call:
         rts

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

FN_B5:   lda     CALL_TYPE  ;DMA read
         and     #$40
         beq     CALL_FN_81 ;branch if not ext call - DMA Read IIe
         lda     #$3c
         bne     CALL_FN_X5_NEAR ;CALL_FN_3C - DMA Read IIgs

CALL_FN_81:
         lda     #$81       ;CALL_FN_81 - DMA Read
CALL_FN_X5_NEAR:
         jmp     CALL_FN_X5

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
