<!--
Copyright (c) 2021 Logan Ryan McLintock

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-->
CebolaOS
========

CebolaOS is an operating system, named so due to the layers of
software that an operating system has. Special thanks to my wife Juliana
for coming up with the name.

Special thanks to the x-BIT Development Udemy course and Nick Blundell's book (listed below).
I highly recommend these excellent resources.

References
----------

* x-BIT Development, 2021, Write Your Own Operating System From Scratch - Step by Step,
  Build your own 64-bit operating system - for the x86 architecture, Udemy,
  https://www.udemy.com/course/writing-your-own-operating-system-from-scratch

* Nick Blundell, 2010, Writing a Simple Operating System - from Scratch,
  School of Computer Science, University of Birmingham, UK.

* The list of all interrupts that are currently supported by the 8086 assembler
  emulator, http://www.ablmcc.edu.hk/~scy/CIT/8086_bios_and_dos_interrupts.htm

* Intel 8086, Wikipedia, https://en.wikipedia.org/wiki/Intel_8086

* Master boot record, Wikipedia,
  https://en.wikipedia.org/wiki/Master_boot_record

* Partition type, Wikipedia,
  https://en.wikipedia.org/wiki/Partition_type

* PA-RISC, Wikipedia, https://en.wikipedia.org/wiki/PA-RISC

* Logical block addressing, Wikipedia,
  https://en.wikipedia.org/wiki/Logical_block_addressing

* INT 13H, Wikipedia, https://en.wikipedia.org/wiki/INT_13H#


BIOS settings
-------------

Different computers have slightly different BIOS configuration options.
You want to turn off secure boot (if you computer has this), enable
legacy boot, and disable UEFI boot. Give the boot preference to the
USB stick that you are booting from, which may appear as a "hard disk".

```
Press F10 to enter BIOS.
Security -> Secure Boot Configuration -> Legacy support -> enable.
Storage -> Boot Order -> Legacy Boot Sources -> F5 enable.
Disable UEFI.
F10 -> Save.
```

Building the bootloader
-----------------------
```
$ nasm bootloader.asm -f bin -o bootloader.bin
```

Physcially booting
------------------
```
$ dmesg
$ doas dd if=bootloader.bin of=/dev/rsd4c
```

Vitually booting
----------------
```
$ qemu-system-x86_64 -nographic bootloader.bin
^a x
```
