all: floppy.img 

build/bootloader.bin: bootloader.asm
	nasm -f bin $< -o $@

build/kernel.o: kernel.c
	gcc -m32 -c -ffreestanding -fno-pie -nostdlib -fno-stack-protector $< -o $@ 

build/kernel_linked: build/kernel.o
	ld -m elf_i386 -e kmain -T linker/linker.ld $< -o $@

build/kernel.bin: build/kernel_linked
	objcopy -O binary build/kernel_linked build/kernel.bin

floppy.img: build/kernel.bin build/bootloader.bin
	cat build/bootloader.bin build/kernel.bin > floppy.img

clean:
	rm build/kernel.o build/kernel_linked
	
