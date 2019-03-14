all: tetris.img tetrisfat.img

run: clean all
	qemu-system-i386 -drive file=tetrisfat.img,index=0,media=disk,format=raw

tetris.bin: tetris.asm
		nasm -f bin tetris.asm -o tetris.bin
boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

tetrisfat.img: clean boot.bin tetris.bin
	mkfs -t msdos -C tetrisfat.img 1440
	#dd if=/dev/zero of=tetrisfat.img bs=1024 count=512
	dd if=boot.bin of=tetrisfat.img conv=notrunc
	dd if=tetris.bin of=tetrisfat.img bs=512 seek=1 conv=notrunc

.PHONY : clean
clean:
		rm *.bin *.img


