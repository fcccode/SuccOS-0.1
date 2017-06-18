
## SuccOS
SuccOS is a minimal 16 bit, real mode `DOS` like operating system written in pure [NASM](http://www.nasm.us/index.php) assemby!
Please know that his is in early devolopment so many things must be done!


## Bootloader
  <img src="prog/bios.png?raw=true " width="600"/>

## Kernel
  <img src="prog/kernel.png?raw=true " width="600"/>
  
## Commands

- `help` -- Show commands.
- `dir`  -- Display root directory.
- `version` -- Display the OS version.
- `cls` -- Clear the screen.
- `reg` -- Show all register contents.
- `echo` -- Print out a string.
- `shutdown`  -- Shutdown the computer.
- `reboot`    -- Restart the comptuer.

## Current TODO list

- Entire gui system
- Loading files 
- Reading files
- Writing files
- Executing files
- Search for files `WIP`

## Building

**Programs used:**
- [NASM](http://www.nasm.us/index.php) -- `Best assembler ever :)`
- [dd](http://uranus.chrysocome.net/linux/rawwrite/dd-old.htm) -- `Coppy bootloader into disk image`
- [imdisk](http://www.ltr-data.se/opencode.html/) -- `Create virtural floppy disk images`
- [QEMU](http://www.qemu.org/) -- `Virtural image emulator (can use virtural box insted)`
- [RadASM](http://www.softpedia.com/get/Programming/File-Editors/RadASM.shtml) -- `Great assemby editor!`

