SRC := $(shell git ls-files '*.c' '*.h' '*.cpp')

format:
	clang-format -i $(SRC)

format-check:
	clang-format --dry-run --Werror $(SRC)

lint:
	cppcheck --enable=all --inconclusive --std=c11 --error-exitcode=1 src

check: format-check lint

build:
	~/.pico-sdk/ninja/v1.12.1/ninja -C build