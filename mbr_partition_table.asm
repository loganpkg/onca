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

; mbr_partition_table.asm: Master Boot Record partition table for CebolaOS.

;
;       Partition Entry
;      +--------+
;      |Status  | 1 byte
;  1st |HHHHHHHH| Head: 1 byte
;      |CCSSSSSS| Sector: Lower 6 bits
;      |CCCCCCCC| Cylinder: Upper 2 bits from above then 8 bits
;      |Part Typ| 1 byte
; Last |HHHHHHHH|
;      |CCSSSSSS|
;      |CCCCCCCC+-----------------------+
;      |LBA First Sector in Partition   | 4 bytes
;      |Number of sectors in Partition  | 4 bytes
;      +--------+-----------------------+
;

[bits 16]

; Pad to the start of the partiton table which has the address 0x01be.
; $ is the current address. $$ is the first address of this section.
; So, $ - $$ is the number of bytes used thus far.
; This lets us know how many zeros to pad.
; times repeats (or multiplies so to speak) the command.
times 0x01be - ($ - $$) db 0

; Partition Entry number 1:
db 0x80 ; Bootable.
; First sector in the partition:
db 0    ; Head.
; Sector. Sector index starts at 1 not 0. The MBR itself is sector 1,
; so the first sector in the first partition is sector 2.
db 2
db 0 ; Cylinder.
; Partition type: Precision Architecture (PA) - Reduced Instruction Set
; Computer (RISC) bootloader for Linux.
db 0xf0
; Last sector in the partition. The default values when too large are:
db 0xfe ; Head: 254. Note this is not 255.
db 0xff ; Two high 1 bits from Cylinder with a Sector of 63.
db 0xff ; With the two high bits from above, this make a Cylinder of 1023.
; Logical Block Addressing (LBA) formula:
; LBA = (C * H_per_C + H) * S_per_T + (S - 1)
; C = Cylinder, H = Head, S = Sector, T = Track.
; So for the first sector in the partition, C = 0, H = 0, S = 2, so LBA = 1.
dd 1 ; Four bytes.
; Disk size in sectors = Num_C * H_per_C * S_per_T.
; H_per_C = 16, S_per_T = 63.
; The minus one is to account for the MBR.
dd (20 * 16 * 63 - 1) ; Four bytes.

; Zero the unused partition enties with 16 bytes.
; Partition Entry number 2:
times 16 db 0

; Partition Entry number 3:
times 16 db 0

; Partition Entry number 4:
times 16 db 0
