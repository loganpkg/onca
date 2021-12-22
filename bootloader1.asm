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

; bootloader1.asm: Stage 1 bootloader for CebolaOS.
;                  This primarily loads the stage 2 bootloader.

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

mov bx, STAGE1_BL_STR
call a16_print_str

mov bx, WELCOME_STR
call a16_print_str

mov bx, COPYRIGHT_STR
call a16_print_str

mov bx, LICENSE_STR
call a16_print_str

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

; Load stage 2 bootloader file, which is the 5 sectors commencing from the
; 2nd sector on disk.
mov ah, 0x42 ; Extended read.
mov dl, [drive_index]
; Fill in the Disk Address Packet (DAP).
mov byte[DAP], 0x10 ; Size of DAP (16 bytes).
mov byte[DAP + 1], 0 ; Unused.
mov byte[DAP + 2], 5 ; Number of sectors to read.
mov word[DAP + 4], 0x7e00 ; Memory buffer address offset.
mov word[DAP + 6], 0 ; Memory buffer address segment.
; LBA of 1 (second sector) using an 8 byte value.
; Due to little-endian, set the lower dword to 1.
mov dword[DAP + 8], 1
mov dword[DAP + 0xc], 0
mov si, DAP ; Pass the address of the DAP as a parameter.
int 0x13
jc read_error ; The read failed.

mov bx, READ_LOADER_OK_STR
call a16_print_str

; Set again in case dl has been used.
mov dl, [drive_index]
jmp 0x7e00 ; Jump to where the loader file was read into memory.

read_error:
no_int_13h_support:

mov bx, BL1_ERR_STR
call a16_print_str

stop:
    hlt
    jmp stop ; Jump forever.

%include "lib16_1.asm" ; Include 16-bit library 1.

; Note that the strings are NULL (zero) terminated.
; Backticks allow escape sequences to be interpreted by nasm.
; \r moves the cursor to the start of the current line.
; \n moves the cursor directly down one line.
; Hence, both are needed to make a newline.
STAGE1_BL_STR:
    db `In stage 1 bootloader\r\n\0`

WELCOME_STR:
    db `Welcome to CebolaOS\r\n\0`

COPYRIGHT_STR:
    db `Copyright (c) 2021 Logan Ryan McLintock\r\n\0`

LICENSE_STR:
    db `Released under the ISC license\r\n\0`

INT_13H_SUPPORT_STR:
    db `INT 13h extension functions OK\r\n\0`

READ_LOADER_OK_STR:
    db `Read of stage 2 bootloader OK\r\n\0`

BL1_ERR_STR:
    db `Stage 1 bootloader ERROR\r\n\0`

drive_index:
    db 0

; Disk Address Packet (DAP) used for extended read function.
DAP:
    times 16 db 0

%include "mbr_partition_table.asm"

; Do not need to pad to make 512 bytes anymore, as will be 512 bytes in total once
; the two bytes are added for the magic number (due to the location of the
; partition table).

; Set the boot magic number. Note that with little-endian this will be 55 aa.
dw 0xaa55
