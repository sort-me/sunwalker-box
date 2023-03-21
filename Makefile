docker-build:
	# run docker and copy file from it
	docker build -t sunwalker-box .
	docker run --rm sunwalker-box cat /build/sunwalker_box > sunwalker_box

sunwalker-box: target/seccomp_filter target/exec_wrapper
	cargo +nightly build --target=x86_64-unknown-linux-gnu -Z build-std=std,panic_abort --release
	cp target/x86_64-unknown-linux-gnu/release/sunwalker_box sunwalker_box

target/seccomp_filter: src/linux/seccomp_filter.asm
	mkdir -p target && seccomp-tools asm $^ -o $@ -f raw

target/exec_wrapper: target/exec_wrapper.o
	ld $^ -o $@ -static -n -s
target/exec_wrapper.o: src/linux/exec_wrapper.asm
	mkdir -p target && nasm $^ -o $@ -f elf64


test:
	cd sandbox_tests && ./test.py
