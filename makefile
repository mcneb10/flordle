# makefile for flordle

.PHONY: all
all: 
	nasm -f bin -o flordle.img main.asm
	truncate -s 1474560 flordle.img

run:
	qemu-system-x86_64 -fda flordle.img
