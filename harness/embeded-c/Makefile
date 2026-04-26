SRC := $(shell git ls-files '*.c' '*.h' '*.cpp')

.PHONY: format format-check lint check build

define run_if_sources
	if [ -n "$(SRC)" ]; then $(1); else echo "No C/C++ source files found."; fi
endef

format:
	@$(call run_if_sources,clang-format -i $(SRC))

format-check:
	@$(call run_if_sources,clang-format --dry-run --Werror $(SRC))

lint:
	@$(call run_if_sources,cppcheck --enable=all --inconclusive --std=c11 --error-exitcode=1 $(SRC))

check: format-check lint

build:
	@if [ -d build ]; then cmake --build build; else echo "build directory missing. Configure the project before building."; exit 1; fi
