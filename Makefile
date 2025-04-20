all: floppy.img 
CFLAGS = -m32 -c -ffreestanding -fno-pie -nostdlib -fno-stack-protector -mgeneral-regs-only

C_SOURCES := $(shell find kernel -name '*.c')
OBJ_FILES := $(patsubst kernel/%.c, build/o/%.o, $(C_SOURCES))

build/bootloader.bin: bootloader/bootloader.asm
	nasm -f bin $< -o $@

build/o/%.o: kernel/%.c 
	@mkdir -p $(dir $@)
	gcc $(CFLAGS) $< -o $@ 

build/kernel_linked: $(OBJ_FILES)
	ld -m elf_i386 -e kmain -T linker/linker.ld $(OBJ_FILES) -o $@

build/kernel.bin: build/kernel_linked
	objcopy -O binary build/kernel_linked build/kernel.bin

build/metadata.bin: build/kernel_linked
	python3 linker/metadata.py $< $@

floppy.img: build/kernel.bin build/metadata.bin build/bootloader.bin
	cat build/bootloader.bin build/metadata.bin build/kernel.bin > floppy.img
	@size=$$(stat -c%s $@); \
	pad=$$((512 - size % 512)); \
	if [ $$pad -ne 512 ]; then dd if=/dev/zero bs=1 count=$$pad >> $@; fi

clean:
	rm -f build/*.bin build/*.o build/kernel_linked floppy.img
	
