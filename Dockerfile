FROM amd64/rust:latest as builder

RUN apt-get update
RUN apt-get install -y ruby-dev nasm

RUN gem install seccomp-tools

RUN rustup toolchain install nightly-x86_64-unknown-linux-gnu
RUN rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu

WORKDIR /build
ENV RUSTFLAGS="-C target-feature=+crt-static"

COPY /Cargo.toml /build/Cargo.toml
COPY /Cargo.lock /build/Cargo.lock
COPY /multiprocessing /build/multiprocessing
COPY /src /build/src

COPY Makefile /build/Makefile

RUN make sunwalker_box

RUN :