all: tetris.img 

run: all
	qemu-system-i386 -drive file=tetris.img,index=0,media=disk,format=raw


bootloader.bin: bootloader.asm
		nasm -f bin bootloader.asm -o bootloader.bin
tetris.bin: tetris.asm
		nasm -f bin tetris.asm -o tetris.bin

tetris.img: bootloader.bin tetris.bin
		dd if=/dev/zero of=tetris.img bs=1024 count=512
		dd if=bootloader.bin of=tetris.img conv=notrunc
		dd if=tetris.bin of=tetris.img bs=512 seek=1 conv=notrunc


.PHONY : clean
clean:
		rm bootloader.bin tetris.bin tetris.img


