#####
## COMMON
#####
PROJECT_NAME=taos

#####
## BUILD
#####
CROSS_COMPILER = riscv64-unknown-linux-gnu
RISCV_GCC     := $(CROSS_COMPILER)-gcc
RISCV_GXX     := $(CROSS_COMPILER)-g++
RISCV_OBJDUMP := $(CROSS_COMPILER)-objdump
RISCV_OBJCOPY := $(CROSS_COMPILER)-objcopy
RISCV_GDB     := $(CROSS_COMPILER)-gdb
RISCV_AR      := $(CROSS_COMPILER)-ar
RISCV_SIZE    := $(CROSS_COMPILER)-size

CFLAGS=-Wall -Wextra -pedantic -O0 -g -std=c++17
CFLAGS+=-static -ffreestanding -nostdlib -fno-rtti -fno-exceptions
CFLAGS+=-march=rv64gc -mabi=lp64
CFLAGS+=-Wl,-Map=$(PROJECT_NAME).map
INCLUDES=
LINKER_SCRIPT=-Tsrc/lds/virt.lds
TYPE=debug
RUST_TARGET=./target/riscv64gc-unknown-none-elf/$(TYPE)
LIBS=-L$(RUST_TARGET)
SOURCES_ASM=$(wildcard src/asm/*.S)
LIB=-l$(PROJECT_NAME) -lgcc
OUT=$(PROJECT_NAME).elf

#####
## QEMU
#####
QEMU=qemu-system-riscv64
MACH=virt
CPU=rv64
CPUS=4
MEM=128M
DRIVE=hdd.dsk
QEMU_DBG=-S -gdb tcp::5551

all:
	cargo build
	$(RISCV_GXX) $(CFLAGS) $(LINKER_SCRIPT) $(INCLUDES) -o $(OUT) $(SOURCES_ASM) $(LIBS) $(LIB)
	$(RISCV_OBJDUMP) -S --disassemble $(OUT) > $(PROJECT_NAME).list
	$(RISCV_SIZE) $(OUT)

run: all
	$(QEMU) -machine $(MACH) -cpu $(CPU) -smp $(CPUS) -m $(MEM) \
	-nographic -serial mon:stdio -bios none -kernel $(OUT) \
	-drive if=none,format=raw,file=$(DRIVE),id=foo -device virtio-blk-device,scsi=off,drive=foo

dbg: all
	# Debug with:
	# $(RISCV_GDB) -ex "set substitute-path /rustc/$$(rustc -Vv | grep commit-hash | cut -d' ' -f2) $$(rustc --print sysroot)/lib/rustlib/src/rust" -x debug.gdb $(OUT)
	$(QEMU) $(QEMU_DBG) -machine $(MACH) -cpu $(CPU) -smp $(CPUS) -m $(MEM) \
	-nographic -serial mon:stdio -bios none -kernel $(OUT) \
	-drive if=none,format=raw,file=$(DRIVE),id=foo -device virtio-blk-device,scsi=off,drive=foo
.PHONY: clean
clean:
	cargo clean
	rm -f $(OUT) $(PROJECT_NAME).map $(PROJECT_NAME).list

# To run this app on 32-bit RISC-V machine (RV32IMAC), use following:
# rustup target add riscv32imac-unknown-none-elf
# cargo build --target=riscv32imac-unknown-none-elf
# riscv64-unknown-linux-gnu-g++ -Wall -Wextra -pedantic -O0 -g -std=c++17 -static -ffreestanding -nostdlib -fno-rtti -fno-exceptions -march=rv32imac -mabi=ilp32 -Wl,-Map=taos.map -Tsrc/lds/virt.lds -o taos32.elf src/asm/boot.S src/asm/trap.S -L./target/riscv32imac-unknown-none-elf/debug -ltaos -lgcc
# qemu-system-riscv32 -machine virt -cpu rv32 -smp 4 -m 128M -nographic -serial mon:stdio -bios none -kernel taos32.elf -drive if=none,format=raw,file=hdd.dsk,id=foo -device virtio-blk-device,scsi=off,drive=foo
