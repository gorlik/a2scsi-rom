OUTPUT = rebuilt_rom.bin

BANKS = bank00.bin_cc65.bin bank01.bin_cc65.bin bank02.bin_cc65.bin bank03.bin_cc65.bin \
	bank04.bin_cc65.bin bank05.bin_cc65.bin bank06.bin_cc65.bin bank07.bin_cc65.bin \
	bank08.bin_cc65.bin bank09.bin_cc65.bin bank10.bin_cc65.bin bank11.bin_cc65.bin \
	bank12.bin_cc65.bin bank13.bin_cc65.bin bank14.bin_cc65.bin bank15.bin_cc65.bin \

rom: $(BANKS)
	cat $(BANKS) >$(OUTPUT)

diff: $(BANKS)
	@diff bank00.bin bank00.bin_cc65.bin
	@diff bank01.bin bank01.bin_cc65.bin
	@diff bank02.bin bank02.bin_cc65.bin
	@diff bank03.bin bank03.bin_cc65.bin
	@diff bank04.bin bank04.bin_cc65.bin
	@diff bank05.bin bank05.bin_cc65.bin
	@diff bank06.bin bank06.bin_cc65.bin
	@diff bank07.bin bank07.bin_cc65.bin
	@diff bank08.bin bank08.bin_cc65.bin
	@diff bank09.bin bank09.bin_cc65.bin
	@diff bank10.bin bank10.bin_cc65.bin
	@diff bank11.bin bank11.bin_cc65.bin
	@diff bank12.bin bank12.bin_cc65.bin
	@diff bank13.bin bank13.bin_cc65.bin
	@diff bank14.bin bank14.bin_cc65.bin
	@diff bank15.bin bank15.bin_cc65.bin

split: 341-0437-A.bin
	dd if=341-0437-A.bin of=bank00.bin bs=1k count=1 skip=0
	dd if=341-0437-A.bin of=bank01.bin bs=1k count=1 skip=1
	dd if=341-0437-A.bin of=bank02.bin bs=1k count=1 skip=2
	dd if=341-0437-A.bin of=bank03.bin bs=1k count=1 skip=3
	dd if=341-0437-A.bin of=bank04.bin bs=1k count=1 skip=4
	dd if=341-0437-A.bin of=bank05.bin bs=1k count=1 skip=5
	dd if=341-0437-A.bin of=bank06.bin bs=1k count=1 skip=6
	dd if=341-0437-A.bin of=bank07.bin bs=1k count=1 skip=7
	dd if=341-0437-A.bin of=bank08.bin bs=1k count=1 skip=8
	dd if=341-0437-A.bin of=bank09.bin bs=1k count=1 skip=9
	dd if=341-0437-A.bin of=bank10.bin bs=1k count=1 skip=10
	dd if=341-0437-A.bin of=bank11.bin bs=1k count=1 skip=11
	dd if=341-0437-A.bin of=bank12.bin bs=1k count=1 skip=12
	dd if=341-0437-A.bin of=bank13.bin bs=1k count=1 skip=13
	dd if=341-0437-A.bin of=bank14.bin bs=1k count=1 skip=14
	dd if=341-0437-A.bin of=bank15.bin bs=1k count=1 skip=15

clean:
	rm -f *.o *.bin_cc65.bin bank*.cfg $(OUTPUT)

%.bin: %.S
	cl65 -t none $< -o $*.bin -C linker.cfg
