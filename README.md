# UEFI-app
This is how to make a program that runs directly on UEFI.

==> This was done on Ubuntu 20
->  download qemu (virtual machine), gcc (c compiler), ovmf(enalbes UEFI in QEMU), gnu-efi (c libraries and dependancies for efi development)
sudo apt-get install gcc
sudo apt-get install qemu
sudo apt-get install virt-manager libvirt-daemon ovmf

->  Create efimain.c This is the efi application
#include <efi.h>
#include <efilib.h>

EFI_STATUS
EFIAPI
efi_main (EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
  InitializeLib(ImageHandle, SystemTable);
  Print(L"Hello, world!\n");
  return EFI_SUCCESS;
}

-> Build efimain.c paying special attention to the paths of the efi libraries you downloaded
-> Also makes efi disk image (dd command)
#!/bin/bash
# UEFI compile, build and run script
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

-> Create patitions on disk and prepare disk.
gdisk /home/divan/prog/os/uefi.img

gdisk output and user commans below...........
GPT fdisk (gdisk) version 0.8.10

Partition table scan:
  MBR: not present
  BSD: not present
  APM: not present
  GPT: not present

Creating new GPT entries.

Command (? for help): o <====
This option deletes all partitions and creates a new protective MBR.
Proceed? (Y/N): y

Command (? for help): n <====
Partition number (1-128, default 1): 1 <====
First sector (34-93716, default = 2048) or {+-}size{KMGTP}: 2048 <====
Last sector (2048-93716, default = 93716) or {+-}size{KMGTP}: 93716 <====
Current type is 'Linux filesystem'
Hex code or GUID (L to show codes, Enter = 8300): ef00 <===
Changed type of partition to 'EFI System'

Command (? for help): w <====

Final checks complete. About to write GPT data. THIS WILL OVERWRITE EXISTING
PARTITIONS!!

Do you want to proceed? (Y/N): y <====
OK; writing new GUID partition table (GPT) to uefi.img.
Warning: The kernel is still using the old partition table.
The new table will be used at the next reboot.
The operation has completed successfully.

-> Mount image and copy UEFI app to image. Note that loop0 might already be in use, in that case just specify another. I used "sudo losetup -l" to check for an unused one and used 17
sudo losetup --offset 1048576 --sizelimit 46934528 /dev/loop17 /home/divan/prog/os/uefi.img
sudo mkdosfs -F 32 /dev/loop17
sudo mount /dev/loop17 /mnt
sudo cp /home/divan/prog/os/efimain.efi /mnt/
sudo umount /mnt
sudo losetup -d /dev/loop0

-> Launch qemu with UEFI and use disk image we made
sudo qemu-system-x86_64 -cpu qemu64 -bios /usr/share/ovmf/OVMF.fd -drive file="/home/divan/prog/os/uefi.img",if=ide

-> Inside machine. Wait for boot. Mine took a few minutes. I thought it was broken but the errors recieved seem to not be a problem.
FS0:
ls
efimain.efi
