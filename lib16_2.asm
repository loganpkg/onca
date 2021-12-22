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

; lib16_2.asm -- 16-bit 8086 BIOS Assembly library 2 for CebolaOS.
; This is used in stage 2 bootloader in 16-bit real mode.

[bits 16]

a16_print_hex:
    ; Function -- Prints a number in big-endian hexadecimal.
    ; Parameters
    ; bx -- Start of memory address.
    ; cx -- Size in bytes.
    ; Working variables
    ; al -- Character to print.
    ; dh -- Leading zero indicator.
    ; dl -- Byte read.
    pusha ; Backup registers.
    mov ah, 0x0e ; Teletype output.
    ; Print 0x prefix to emphasise that the output is big-endian.
    mov al, '0'
    int 0x10
    mov al, 'x'
    int 0x10
    mov dh, 1 ; Set leading zero indicator.
    ; Go to the last byte in the number.
    add bx, cx
    sub bx, 1
.top_of_loop:
    ; Read one byte.
    mov dl, [bx]
    test dl, dl ; AND without storing the result.
    jz .zero_byte
    mov dh, 0 ; Clear leading zero indicator.
.zero_byte:
    cmp cx, 1
    je .print ; Always print the least significant byte, even if zero.
    cmp dh, 1
    je .prepare_for_next ; Skip leading zeros.
.print:
    mov al, dl ; Get a copy of the read byte.
    ; Right shift the upper four bits into the lower four bits.
    shr al, 4
    ; Secondly, bitwise AND the lower 4 bits, eliminating the upper 4 bits.
    and al, 0x0f
    ; Add the ASCII value for the character zero, '0'
    add al, '0'
    ; See if hex value is in 0-9 range or a-f range.
    cmp al, '9'
    jbe .upper_0_to_9
    ; a-f range.
    ; 'a' is decimal 97. '9' is decimal 57. So, '10' would be 58 which
    ; corresponds to 'a', so need to add 97 - 58 = 39.
    add al, 39
.upper_0_to_9:
    int 0x10 ; Interrupt. This will cause the print to occur on the screen.
    ; Repeat for the lower half of the byte.
    mov al, dl ; Get a copy of the read byte.
    ; No need to shift.
    and al, 0x0f
    add al, '0'
    cmp al, '9'
    jbe .lower_0_to_9
    add al, 39
.lower_0_to_9:
    int 0x10
.prepare_for_next:
    dec bx
    dec cx ; Decrement the number of bytes (size).
    jnz .top_of_loop ; Jump if not zero to the top of the loop.
    popa ; Restore registers.
    ret ; Return to after the call.
