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

This operating system uses sloth version control and was written using the
spot text editor (included in the toucan C development environment).

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

* Bootloader, OSDev Wiki, https://wiki.osdev.org/Bootloader

* Setting Up Long Mode, OSDev Wiki, https://wiki.osdev.org/Setting_Up_Long_Mode

* FLAGS register, Wikipedia, https://en.wikipedia.org/wiki/FLAGS_register

* X86 Opcode and Instruction Reference Home,
  http://ref.x86asm.net/coder32.html#x66

* TEST (x86 instruction), Wikipedia,
  https://en.wikipedia.org/wiki/TEST_(x86_instruction)

* Detecting Memory (x86), OSDev Wiki,
  https://wiki.osdev.org/Detecting_Memory_(x86)

* ASCII, Wikipedia, https://en.wikipedia.org/wiki/ASCII

* Memory map, Wikipedia, https://en.wikipedia.org/wiki/Memory_map

* 15.1. INT 15H, E820H - Query System Address Map, ACPI Specification 6.4,
  https://uefi.org/specs/ACPI/6.4/15_System_Address_Map_Interfaces/int-15h-e820h---query-system-address-map.html

* A20 line, Wikipedia, https://en.wikipedia.org/wiki/A20_line

* x86 Registers, https://www.eecg.utoronto.ca/~amza/www.mindsec.com/files/x86regs.html

* Global Descriptor Table, Wikipedia, https://en.wikipedia.org/wiki/Global_Descriptor_Table

* Global Descriptor Table, OSDev Wiki, https://wiki.osdev.org/Global_Descriptor_Table

* LGDT/LIDT Load Global/Interrupt Descriptor Table Register,
  https://www.felixcloutier.com/x86/lgdt:lidt

* Protected Mode, OSDev Wiki, https://wiki.osdev.org/Protected_Mode

* Protected mode, Wikipedia, https://en.wikipedia.org/wiki/Protected_mode

* Prefetch input queue, Wikipedia,
  https://en.wikipedia.org/wiki/Prefetch_input_queue

* Clear Interrupt Flag (cli), IA-32 Assembly Language Reference Manual,
  https://docs.oracle.com/cd/E19455-01/806-3773/instructionset-15/index.html


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

Building
--------
```
$ make
```

Physically booting
------------------
```
$ dmesg
$ doas dd if=boot.img of=/dev/rsdXc
