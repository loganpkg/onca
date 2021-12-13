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

; bootloader.asm: Bootloader for CebolaOS.

; 16-bit 8086 BIOS Assembly in real mode.
[bits 16]

; Set the origin. This is the address where the boot sector is loaded into
; memory.
[org 0x7c00]

; Clear the general registers to zero.
; Do not clear dx as dl contains the disk index.
xor ax, ax
xor bx, bx
xor cx, cx

; Set segment registers to zero, except for the code segment.
; Note, you cannot xor them.
; Physical address = segment * 16 + offset.
mov ds, ax ; Data segment.
mov es, ax ; Extra segment.
mov ss, ax ; Stack segment.

; Set stack base pointer (bp) to where the MBR is loaded into RAM,
; as the stack grows downwards.
mov bp, 0x7c00
; Set stack pointer to start off at the stack base.
mov sp, bp

mov ah, 0 ; Set video mode.
mov al, 0x03 ; Text mode 80 by 25.
int 0x10

call a16_newline_cursor
call a16_newline_cursor
call a16_newline_cursor
call a16_newline_cursor

mov bx, WELCOME_STR
call a16_print_str
call a16_newline_cursor

mov bx, COPYRIGHT_STR
call a16_print_str
call a16_newline_cursor

mov bx, LICENSE_STR
call a16_print_str
call a16_newline_cursor

; Store drive index.
mov [drive_index], dl

; Check for INT 13h extension functions.
mov ah, 0x41
mov bx, 0x55aa
mov dl, [drive_index]
int 0x13
jc no_int_13h_support ; Jump if carry flag is set.
cmp bx, 0xaa55
jne no_int_13h_support ; Jump if not equal.

mov bx, INT_13H_SUPPORT_STR
call a16_print_str
call a16_newline_cursor

no_int_13h_support:
stop:
    hlt
    jmp stop ; Jump forever.

%include "lib16.asm" ; Include the 16-bit library.

; Note that the strings are NULL (zero) terminated.
WELCOME_STR:
    db "Welcome to CebolaOS", 0

COPYRIGHT_STR:
    db "Copyright (c) 2021 Logan Ryan McLintock", 0

LICENSE_STR:
    db "Released under the ISC license", 0

INT_13H_SUPPORT_STR:
    db "INT 13h extension functions OK", 0

drive_index:
    db 0

%include "mbr_partition_table.asm"

; Do not need to pad to make 512 bytes anymore, as will be 512 bytes in total once
; the two bytes are added for the magic number (due to the location of the
; partition table).

; Set the boot magic number. Note that with little-endian this will be 55 aa.
dw 0xaa55
