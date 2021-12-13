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

; lib16.asm: 16-bit 8086 BIOS Assembly library for CebolaOS.
; This is used in the bootloader in 16-bit real mode.

[bits 16]

a16_print_str:
    ; Function that prints 0 terminated string.
    ; String address is stored in register bx.
    pusha ; Backup registers.
    mov ah, 0x0e ; teletype output.
    .start:
    mov al, [bx] ; Prepare the value stored at bx for printing.
    cmp al, 0 ; Check for the zero termination of string.
    je .end
    int 0x10 ; Interrupt. This will cause the print to occur on the screen.
    inc bx
    jmp .start ; Jump to the start of the loop.
    .end: ; Local label. End of loop.
    popa ; Restore registers.
    ret ; Return to after the call.

a16_newline_cursor:
    ; Function to move the cursor to the start of the next line.
    ; Only works on the first page, page 0.
    pusha ; Backup registers.
    mov ah, 0x03 ; Get the current cursor location.
    mov bh, 0 ; Page 0.
    ; Interrupt. In this case returns the row into dh and the column into dl.
    ; Writes to ch and cl too.
    int 0x10
    inc dh; Increment row number.
    mov ah, 2 ; Move cursor.
    mov bh, 0 ; Page 0.
    mov dl, 0 ; Column 0.
    int 0x10
    popa ; Restore registers.
    ret ; Return to after the call.
