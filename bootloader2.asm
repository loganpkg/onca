;
; Copyright (c) 2021, 2022 Logan Ryan McLintock
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

; bootloader2.asm -- Stage 2 bootloader for CebolaOS.
;                    This is loaded by the stage 1 bootloader.
;                    This boots the kernel and enters 32-bit protected mode.

; 16-bit 8086 BIOS Assembly in real mode.
[bits 16]

; Set the origin. This is the address where the stage 2 bootloader is read into
; memory.
[org 0x7e00]

; Backup drive index.
mov [drive_index], dl

mov bx, IN_LOADER_STR
call a16_print_str

; Check for CPUID capability. If can flip bit 21 of EFLAGS, then has
; CPUID support. Push EFLAGS to the stack, change it, then pop it back.
; Push flags as a double word (4 bytes) to the stack.
pushfd
; Can use 32-bit registers in real mode (16-bit). This will pop 4 bytes.
; If you run
; $ nasm -f bin -o test.bin test.asm
; $ hexdump -C test.bin
; on this line, you will see
; 66 58
; The opcode 66 is the precision-size override prefix. This lets the operation
; run in 32-bits even when in 16-bit real mode.
pop eax
; Likewise, if you run nasm and hexdump on this line, you will see
; 66 35 00 00 20 00
; This means
; 66 -> precision-size override prefix
; 35 -> xor eax
; 00 00 20 00 -> little-endian. In big-endian this is 0x00200000 which in
; binary is
; 00000000001000000000000000000000
;           ^                    ^
;           |                    |
;           21                   0
mov ebx, eax ; Backup original value.
xor eax, 1 << 21 ; Flip bit 21 (big endian).
push eax ; Push modified value onto the stack.
popfd ; Set EFLAGS from the stack.
pushfd ; Push EFLAGS back to the stack.
pop eax
cmp ebx, eax ; Compare new EFLAGS to old EFLAGS.
; If there is no change (equal), then no CPUID support.
je no_cpuid_support ; Jump if equal.

mov bx, CPUID_SUPPORT_STR
call a16_print_str

; Print CPU Manufacturer Id.
mov eax, 0 ; Leaf 0.
cpuid
; ebx, edx, ecx has the Manufacturer Id.
; Store the Manufacturer Id in a string.
; Do not need to specify dword as it is understood from the register size.
mov [man_id], ebx
mov [man_id + 4], edx
mov [man_id + 8], ecx

mov bx, MAN_ID_STR
call a16_print_str

mov bx, man_id
call a16_print_str

mov bx, NEWLINE_STR
call a16_print_str

; Determine the highest extended leaf of cpuid. Will be returned in eax.
mov eax, 0x80000000 ; Leaf to determine the highest extended leaf.
cpuid ; Highest extended leaf is stored in eax.
cmp eax, 0x80000001 ; Test if the extended leaf 0x80000001 has been implemented.
jb no_ext_leaf

; Get the processor's extended feature bits (returned into edx and ecx,
; but do not need ecx).
mov eax, 0x80000001
cpuid
; Test for Long Mode (bit 29)
; This is a bitwise AND operation. The zero flag (ZF) is set to 1 if zero.
test edx, 1 << 29
jz no_long_mode ; Jump if zero.

mov bx, LONG_MODE_STR
call a16_print_str

; Test for Gigabyte pages. The value in edx should be OK to reuse.
test edx, 1 << 26
jz no_GiB_pages

mov bx, GiB_PAGES_STR
call a16_print_str

; Load kernel file into memory address 0x10000, which is the 100 sectors
; commencing from the 7th sector on disk.
mov ah, 0x42 ; Extended read.
mov dl, [drive_index]
; Fill in the Disk Address Packet (DAP).
mov byte[DAP], 0x10 ; Size of DAP (16 bytes).
mov byte[DAP + 1], 0 ; Unused.
mov byte[DAP + 2], 100 ; Number of sectors to read.
; Physical address = 0x10000 = 0x1000 * 16 + 0
mov word[DAP + 4], 0 ; Memory buffer address offset.
mov word[DAP + 6], 0x1000 ; Memory buffer address segment.
; LBA of 6 (7th sector) using an 8 byte value.
; Due to little-endian, set the lower dword.
mov dword[DAP + 8], 6
mov dword[DAP + 0xc], 0
mov si, DAP ; Pass the address of the DAP as a parameter.
int 0x13
jc read_error ; The read failed.

mov bx, READ_KERNEL_OK_STR
call a16_print_str

; Store memory map.
; S -> 0x53
; M -> 0x4d
; A -> 0x41
; P -> 0x50

; First block.
mov eax, 0xe820 ; Function code -- Query address map.
xor ebx, ebx ; Set to zero. Do not change between calls.
mov di, [mem_map]
mov ecx, 20 ; Buffer size. Do not need the extended attributes.
mov edx, 0x534d4150 ; "SMAP" in big-endian.
int 0x15 ; Interrupt.
; Carry flag set means there was an error. There should be at least one entry,
; so this would indicate no support for this function.
jc address_map_error
cmp eax, 0x534d4150 ; "SMAP" should be returned into eax.
jne address_map_error ; Jump if not equal.
add di, 20 ; Advance memory buffer.

subsequent_block:
    mov eax, 0xe820 ; Reset -- Function code -- Query address map.
    ; ebx -- Do not change this continuation value between calls.
    mov ecx, 20 ; Reset -- Buffer size. Do not need the extended attributes.
    mov edx, 0x534d4150 ; Reset -- "SMAP" in big-endian.
    int 0x15 ; Interrupt.
    jc address_map_error ; Carry flag set means there was an error.
    cmp eax, 0x534d4150 ; "SMAP" should be returned into eax.
    jne address_map_error ; Jump if not equal.
    add di, 20 ; Advance memory buffer.
    test ebx, ebx
    jnz subsequent_block ; Jump if not zero, as the list continues.
    ; Zero indicates the end of the list.

; Store end of memory map.
mov [end_mem_map], di

mov bx, MEM_MAP_OK_STR
call a16_print_str

mov bx, MEM_MAP_ADDRESS_STR
call a16_print_str

mov bx, mem_map
mov cx, 2 ; Size.
call a16_print_hex
mov bx, NEWLINE_STR
call a16_print_str

mov bx, MEM_MAP_TABLE_STR
call a16_print_str

; Print memory map.
mov bx, [mem_map]
mov ax, [end_mem_map]
.top_print_loop:
    ; bx is already set to the start of the memory to be printed.
    mov cx, 8 ; Size.
    call a16_print_hex

    push bx
    mov bx, DELIM_STR
    call a16_print_str
    pop bx

    add bx, 8 ; Address to start of memmory.
    mov cx, 8 ; Size.
    call a16_print_hex

    push bx
    mov bx, DELIM_STR
    call a16_print_str
    pop bx

    add bx, 8 ; Address to start of memmory.
    mov cx, 4 ; Size.
    call a16_print_hex
    ; Prepare for next loop.
    add bx, 4

    push bx
    mov bx, NEWLINE_STR
    call a16_print_str
    pop bx

    cmp bx, ax
    jne .top_print_loop
    ; If equal then at the address immediately after the end of the mem map.

; Check if address line 20 is enabled.
; Write a random value to address 0x7c00 (the address where the stage 1
; bootloader was copied to, as this is no longer being used).
xor ax, ax ; Zero.
mov ds, ax ; Zero data segment register.
; Copy random value. Need to specify the size of the memory (a word = 2 bytes).
mov word[ds:0x7c00], 0x4e14 ; Random value decimal 19988.
; The address 0x7c00 with the bit index 20 set is address 0x107c00.
; 1 << 20 + 0x7c00 = 0x107c00.
; To create this address using the 16 bit (2 byte) register values, a non-zero
; segment register value must be used. To make the address big, use the maximum
; segment value of 0xffff. Then the required offset will be
; 0x107c00 - 0xffff * 0x10 = 0x7c10
; And to check
; 0xffff * 0x10 + 0x7c10 = 0x107c00
; Use the extra segment for the big address (as ds is already being used).
mov ax, 0xffff
mov es, ax
; See if this big address contains the random number
cmp word[es:0x7c10], 0x4e14
; Jump if not equal. This means that the big address did not upper bound
; truncate, and A20 works fine.
jne .a20_ok
; Else, they are equal. This could be a coincidence. Try another random number.
; (The value stored at the real big address will not change).
mov word[ds:0x7c00], 0xba30 ; Copy random value decimal 47664.
; Compare the value stored at the big address against the random number.
cmp word[es:0x7c10], 0xba30
; If equal, the big address was upper bound truncated to be the small address,
; and A20 is disabled.
je a20_disabled

.a20_ok:
; Clear es register again.
xor ax, ax
mov es, ax
mov bx, A20_OK_STR
call a16_print_str

cli ; Clear interrupt flag.
lgdt [gdt32pm_ptr] ; Load the global descriptor table.
lidt [idt32pm_ptr] ; Load the interrupt descriptor table.

mov eax, cr0 ; Copy Control Register 0 (cr0).
; Set the lowest bit to 1 which will enable protected mode when applied.
or al, 1
; Apply modified copy back to control register 0 to enable protected mode.
mov cr0, eax

; Perform a far jump to clear the prefetch input queue (the fetching of opcodes
; from memory before they are needed). This also sets the Code Segment (CS)
; register to the code segment descriptor in the global descriptor table
; (the second entry at an index of 8 bytes).
jmp 8:pm_entry

[bits 32]
pm_entry:
; Index into the data segment descriptor of the global descriptor table.
mov ax, 16 ; 3rd entry in GDT at byte 16.
; Set these registers to the data segment descriptor index
; (they cannot be set directly).
mov ds, ax ; Data segment register.
mov ss, ax ; Stack segment register.
mov es, ax ; Extra segment register.
; Set the Extended Stack Pointer (esp) to where the MBR is loaded into memory,
; as the stack grows downwards and the stack is below the MBR.
mov esp, 0x7c00

; Update status in printed message on the screen (see bootloader 1).
mov byte[0xb8002], 'O'
mov byte[0xb8004], 'K'

stop2:
    hlt
    jmp stop2 ; Jump forever.

; Global Descriptor Table (GDT) for entering 32-bit protected mode.
; https://wiki.osdev.org/Global_Descriptor_Table
; https://en.wikipedia.org/wiki/Global_Descriptor_Table

gdt32pm: ; Global descriptor table for 32-bit protected mode.
; The first segment descriptor must be all zero.
dq 0 ; 8 bytes.

; Segment descriptor: Used for the code segment
; ---------------------------------------------

dw 0xffff ; Segment limit (first 2 bytes): Choose the maximum value.

; Base address (first 3 bytes): Set to zero.
dw 0 ; Two bytes.
db 0 ; One byte.

; Access byte:
;  1 = Present bit: Set to one to indicate that this is a valid segment.
; 00 = Descriptor privilege level field (2 bits): Set to zero (to mean ring zero).
;  1 = Descriptor type (1 bit): Set to 1 meaning it is a code or data segment.
;  1 = Executable bit: Set to 1 to make a code segment (executable).
;  0 = Conforming bit (for code): Set to 0 (non-conforming).
;  1 = Readable bit (for code): Set to 1 so that read access is allowed.
;  0 = Accessed bit: Set to zero.
db 10011010b

; Flags
; 1 = Granularity flag (1 bit): Set to 1 for 4 KiB blocks.
;     Segment limit (20 bits) is multipled by this to give the address space.
;     Address space = (0xfffff + 1) * 4 * 2^10
;                   = 0x100000 * 0x1000
;                   = 0x100000000
;                   = 4294967296
;                   = 4 * 2^30
;                   = 4 GiB
; 1 = Size flag (1 bit): Set to one 1 meaning 32-bits.
; 0 = Long-mode code flag (1 bit): Set to 0 meaning not in long-mode yet.
; 0 = Reserved bit (1 bit).

; Segment limit (continued... upper 4 bits to make a total of 20 bits).
; Set to the maximum, which is 1111 in binary.
; Putting the flags and the upper part of the segment limit together gives:
db 11001111b

; Base address (continued.... upper byte)
db 0 ; Set to 0. All pieces of the base address are 0, making 0 overall.

; Segment descriptor: Used for the data segment
; ---------------------------------------------
; This is almost the same as the code segment.
dw 0xffff
dw 0
db 0

; Access byte:
;  1
; 00
;  1
;  0 = Executable bit: Set to 0 to make a data segment (non-executable).
;  0 = Direction bit (for data): Set to 0 to make the segment grow upwards.
;  1 = Writable bit (for data): Set to 1 so that write access is allowed.
;  0
db 10010010b
db 11001111b
db 0

gdt32pm_size: equ $ - gdt32pm ; GDT size.

gdt32pm_ptr: ; In 32-bit mode 6 bytes is used.
; Since little-endian, the size component appears first.
dw gdt32pm_size ; 2 bytes.
dd gdt32pm ; 4 bytes.

idt32pm_ptr:
; Interrupt Descriptor Table (IDT). An empty table is used to disable interupts
; while entering 32-bit protected mode.
dw 0 ; Size.
dd 0 ; Pointer to table (there is no table in this case).


a20_disabled:
address_map_error:
read_error:
no_GiB_pages:
no_long_mode:
no_ext_leaf:
no_cpuid_support:

mov bx, BL2_ERR_STR
call a16_print_str

stop:
    hlt
    jmp stop ; Jump forever.

IN_LOADER_STR:
    db `In stage 2 bootloader OK\r\n\0`

CPUID_SUPPORT_STR:
    db `CPUID support OK\r\n\0`

MAN_ID_STR:
    db `CPU Manufacturer Id: \0`

LONG_MODE_STR:
    db `Long mode support OK\r\n\0`

GiB_PAGES_STR:
    db `GiB pages support OK\r\n\0`

BL2_ERR_STR:
    db `Stage 2 bootloader ERROR\r\n\0`

READ_KERNEL_OK_STR:
    db `Read kernel OK\r\n\0`

MEM_MAP_OK_STR:
    db `Memory map read OK\r\n\0`

MEM_MAP_ADDRESS_STR:
    db `Memory map address: \0`

MEM_MAP_TABLE_STR:
    db `Address^Size^Type\r\n\0`

A20_OK_STR:
    db `Address line 20 OK\r\n\0`

DELIM_STR:
    db `^\0`

NEWLINE_STR:
    db `\r\n\0`

drive_index:
    db 0

man_id:
    times 13 db 0 ; Add one for the zero termination of the string.

; Disk Address Packet (DAP) used for extended read function.
DAP:
    times 16 db 0

; Stores the address to the start of where the memory map will be saved.
mem_map:
    dw 0x9000
; Stored the address immediately after then end of the memory map.
end_mem_map:
    dw 0

%include "lib16_1.asm" ; Include 16-bit library 1.
%include "lib16_2.asm" ; Include 16-bit library 2.
