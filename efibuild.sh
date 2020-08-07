#!/bin/bash
# My first script
gcc efimain.c                             \
      -c                                 \
      -fno-stack-protector               \
      -fpic                              \
      -fshort-wchar                      \
      -mno-red-zone                      \
      -I /usr/include/efi       \
      -I /usr/include/efi/x86_64 \
      -DEFI_FUNCTION_WRAPPER             \
      -o efimain.o

ld efimain.o                         \
     /usr/lib/crt0-efi-x86_64.o     \
     -nostdlib                      \
     -znocombreloc                  \
     -T /usr/lib/elf_x86_64_efi.lds \
     -shared                        \
     -Bsymbolic                     \
     -L /usr/lib               \
     -l:libgnuefi.a                 \
     -l:libefi.a                    \
     -o efimain.so

objcopy -j .text                \
          -j .sdata               \
          -j .data                \
          -j .dynamic             \
          -j .dynsym              \
          -j .rel                 \
          -j .rela                \
          -j .reloc               \
          --target=efi-app-x86_64 \
          efimain.so                 \
          efimain.efi

dd if=/dev/zero of=/home/divan/prog/os/uefi.img bs=512 count=93750
gdisk /home/divan/prog/os/uefi.img
o
n
w
y
losetup --offset 1048576 --sizelimit 46934528 /dev/loop0 /home/divan/prog/os/uefi.img
mkdosfs -F 32 /dev/loop0
mount /dev/loop0 /mnt
cp /home/divan/prog/os/efimain.efi /mnt/
umount /mnt
losetup -d /dev/loop0
