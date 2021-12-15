;
; Copyright (c) 2021 Logan Ryan McLintock
;
; Permission to use, copy, modify, and distribute this software for any
; purpose with or without fee is hereby granted, provided that the above
; copyright notice and this permission notice appear in all copies.
;
; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
; ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
; OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
;

; bootloader2.asm: Stage 2 bootloader for CebolaOS.
;                  This is loaded by the stage 1 bootloader.
;                  This boots the kernel.

; 16-bit 8086 BIOS Assembly in real mode.
[bits 16]

; Set the origin. This is the address where the stage 2 bootloader is read into
; memory.
[org 0x7e00]

mov bx, IN_LOADER_STR
call a16_print_str
call a16_newline_cursor

; Check for CPUID capability. If can flip bit 21 of EFLAGS, then has
; CPUID support.
; Push flags as a double word (4 bytes) to the stack.
pushfd
; Can use 32-bit registers in real mode (16-bit). This will pop 4 bytes.
; If you run:
; $ nasm -f bin -o test.bin test.asm
; $ hexdump -C test.bin
; on this line, you will see:
; 66 58
; The opcode 66 is the precision-size override prefix. This lets the operation
; run in 32-bits even when in 16-bit real mode.
pop eax
; Likewise, if you run nasm and hexdump on this line, you will see:
; 66 35 00 00 20 00
; This means:
; 66 -> precision-size override prefix
; 35 -> xor eax
; 00 00 20 00 -> little-endian. In big-endian this is 0x00200000 which in
; binary is:
; 00000000001000000000000000000000
;           ^                    ^
;           |                    |
;           21                   0
xor eax, 1 << 21 ; Flip bit 21 (big endian).


stop:
    hlt
    jmp stop ; Jump forever.

IN_LOADER_STR:
    db "In stage 2 bootloader OK", 0

%include "lib16.asm" ; Include the 16-bit library.
