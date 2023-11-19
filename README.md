# a2scsi-rom
Commented disassembly of the Apple II SCSI card ROM (341-0437-A rev.c)
6502bench sourcegen from faddensoft has been used and dis65 files are provided.

The include makefile will reassemble the complete rom to use in an EPROM programmer or with MAME.

## useful info
The rom contains 16 1KB banks that is mapped at $cc00.
Bank 0 contains boot code that is also shadowed at $cn00.
All banks contain the same code fragment at $cfcc to support banks switching.
Bank03 is missing a CLC before the RTS that ends the bankswitch code.

The ram on the card is also banked (8 1KB banks) but it seems the on board firmware only uses bank 0.
Bank 1 is used for the Patch1Call and two additional unidentified calls.

ROM Bank 0 and Bank 8 are identical except the last 4 bytes.

The Apple TRM defines apple device type $06 as direct access tape drive (???). 
This is inconsistent with the SCSI documentation as SCSI type $01 (sequential access) and all direct 
access removable devices (SCSI type $00) that are not CD_ROMs end up as type $06.
From the disassemby Apple type $06 is sequential access or removable direct access (the block device flag
can be used to identify direct access (block dev ) vs. sequential (char dev)), but excludes devices
of SCSI type $07 (Optical memory).

SCSI uses big endian for multi bytes quantities, both prodos and smartport use little endian.
The FW has a mix of both (i.e. SDAT is big endian, DIBTAB is little endian) making following code 
quite difficult and error prone. I don't exclude there are some bugs hiding in the block calculations.

TIMEOUT byte order seem to be used inconsistenly in differet banks.
Bank14 TIMEOUT decrement seems buggy.

DEV_IDX seems to start either at 0 or 1 depending on the code path.

## TRM Errata
In Appendix B the TRM incorrectly documents some of the BANKSWITCH calls. For some calls the nibbles have been swapped.
```
DataXin is FN_01 ($10 in TRM)
DoStatus is FN_30 ($03 in TRM)
LongData is likely FN_29 ($92 in TRM)
```
In the text description 1 should be subtracted to the ROM bank numbers to get to the 
correct location. 

The TRM documents SmartPort Control code $17 (ReceiveDiag) which is disabled in the 
command interpreter even if the code seems to be there.

## Possible bugs in the FW
In FN_07 there is a chain of JSR to $cc51 and $cc95.
This ends up to the following code fragment:
```
@rts:
	rts
LCC8B:
	lda #$00
	ldx #$06
	sta SCSI_CDB_CMD,x
	dex
	beq @rts
LCC95:
	jsr LCC8B
```
which will crash the machine due to a stack overflow.
FN_07 is called from FN_09 (Smartport read) and FN_19 (Smartport Write) when 
the targeted device is a character device. It's likely that character devices 
do not work at all.


Removable direct access devices are incorrectly assigned apple type $06 (Sequential access) 
instead of $07 (HDD) or $03 (Generic SCSI). The Apple HS SCSI card firmware assigns $07 to 
the same device.
