
all: os.bin

boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

kernel.o: kernel.c
	gcc -m32 -ffreestanding -fno-stack-protector -fno-pie -c kernel.c -o kernel.o

kernel.bin: kernel.o
	ld -m elf_i386 -T linker.ld -o kernel.elf kernel.o
	objcopy -O binary kernel.elf kernel.bin

os.bin: boot.bin kernel.bin
	cat boot.bin kernel.bin > os.bin
	truncate -s 1440K os.bin

run: os.bin
	qemu-system-x86_64 -fda os.bin

clean:
	rm -f *.o *.bin *.elf