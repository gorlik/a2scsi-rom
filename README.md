# a2scsi-rom
Commented disassembly of the Apple II SCSI card ROM (341-0437-A rev.c)
6502bench sourcegen from faddensoft has been used and dis65 files are provided.

The include makefile will reasemble the complete rom to use in an EPROM programmer or with MAME.

# useful info
The rom contains 16 1KB banks that is mapped at $cc00.
Bank 0 contains boot code that is also shadowed at $cn00.
All banks contain the same code fragment at $cfcc to support banks switching.

The ram on the card is also banked (8 1KB banks) but it seems the on board firmware only uses bank 0.
Bank 1 is used for the Patch1Call and two additional unidentified calls.

ROM Bank 0 and Bank 8 are identical except the last 4 bytes. It seems that they must be identical for the ROM to function.
I was not able to figure out why, yet.

TIMEOUT byte order seem to be used inconsistenly in differet banks.
Bank14 TIMEOUT decrement seems buggy.

