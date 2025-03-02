ARCH := $(shell musl-gcc -dumpmachine | cut -d- -f1)
TARGET := $(ARCH)-unknown-linux-musl

RUSTFLAGS := --remap-path-prefix ${HOME}/.rustup=~/.rustup --remap-path-prefix ${HOME}/.cargo=~/.cargo --remap-path-prefix $(shell pwd)=.

ifeq ($(ARCH),aarch64)
RUSTFLAGS += -C link-arg=-lgcc
endif

.PHONY: docker-build

all: docker-build

docker-build:
	# run docker and copy file from it
	docker build -t sunwalker-box .
	docker run --rm sunwalker-box cat /build/sunwalker_box > sunwalker_box


sunwalker_box: $(ARCH)-sunwalker_box
	cp $^ $@
$(ARCH)-sunwalker_box: target/$(TARGET)/release/sunwalker_box
	cp $^ $@
target/$(TARGET)/release/sunwalker_box: target/seccomp_filter target/exec_wrapper target/sunwalker.ko
	RUSTFLAGS="$(RUSTFLAGS)" cargo +nightly build --target=$(TARGET) -Z build-std=std,panic_abort --release --config target.$(ARCH)-unknown-linux-musl.linker=\"$(ARCH)-linux-gnu-gcc\"

target/seccomp_filter: target/$(ARCH)/seccomp_filter
	cp $^ $@
target/x86_64/seccomp_filter: src/linux/x86_64/seccomp_filter.asm
	mkdir -p target/x86_64 && seccomp-tools asm $^ -o $@ -f raw
target/aarch64/seccomp_filter: src/linux/aarch64/seccomp_filter.asm
	mkdir -p target/aarch64 && seccomp-tools asm $^ -o $@ -f raw

target/exec_wrapper: target/$(ARCH)/exec_wrapper.o
	$(ARCH)-linux-gnu-gcc $^ -o $@ -static -nostartfiles -n -s
target/x86_64/exec_wrapper.o: src/linux/x86_64/exec_wrapper.asm
	mkdir -p target/x86_64 && nasm $^ -o $@ -f elf64
target/aarch64/exec_wrapper.o: src/linux/aarch64/exec_wrapper.asm
	mkdir -p target/aarch64 && aarch64-linux-gnu-as $^ -o $@

target/sunwalker.ko: kmodule/$(ARCH)/sunwalker.ko
	cp $^ $@
kmodule/x86_64/sunwalker.ko:
	touch $@
kmodule/aarch64/sunwalker.ko: kmodule/aarch64/sunwalker.c
	$(MAKE) -C kmodule/aarch64


test:
	cd sandbox_tests && ./test.py $(ARCH)

clean:
	rm -r target sunwalker_box *-sunwalker_box kmodule/*/Module.symvers kmodule/*/modules.order kmodule/*/sunwalker.ko kmodule/*/sunwalker.mod* kmodule/*/sunwalker.o || true
