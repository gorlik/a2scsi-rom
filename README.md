# a2scsi-rom
Commented disassembly of the Apple II SCSI card ROM (341-0437-A rev.c).

6502bench sourcegen from faddensoft has been used and dis65 files are provided.

The included makefile will reassemble the complete rom to use in an EPROM programmer or with MAME.

## useful info
The rom contains sixteen 1KB banks that are mapped at $cc00.
Bank 0 contains boot code that is also shadowed at $cn00. The boot code is used by the Apple IIgs
SCSI Driver to identify the card (the apple driver contains a copy of this section and performs
a full compare upon load). Any changes to this section will make the driver fail to load.

All banks contain the same code fragment at $cfcc to support banks switching.

The ram on the card is also banked (eight 1KB banks) but it seems the on board firmware only uses bank 0.
Bank 1 is used for the Patch1Call and two additional unidentified calls.

ROM Bank 0 and Bank 8 are identical except the last 4 bytes.


## Potential Bugs
TIMEOUT byte order seem to be used inconsistenly in differet banks.
Bank14 TIMEOUT decrement seems buggy.

The Apple TRM defines apple device type $06 as direct access tape drive (???). 
This is inconsistent with the SCSI documentation as SCSI type $01 (sequential access) and all direct 
access removable devices (SCSI type $00) that are not CD_ROMs end up as type $06.
From the disassemby Apple type $06 is sequential access or removable direct access (the block device flag
can be used to identify direct access (block dev ) vs. sequential (char dev)), but excludes devices
of SCSI type $07 (Optical memory).

## TRM Errata
In Appendix B the TRM incorrectly documents some of the BANKSWITCH calls. For some calls the nibbles have been swapped.
```
DataXin is FN_01 ($10 in TRM)
DoStatus is FN_30 ($03 in TRM)
LongData is likely FN_29 ($92 in TRM)
```
In the text description 1 should be subtracted to the ROM bank numbers to get to the correct location. 

The TRM documents SmartPort Control code $17 (ReceiveDiag) which is disabled in the command interpreter even if the code seems to be there.
