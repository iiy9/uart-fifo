# make            run every testbench in tb/
# make tb_fifo    run one testbench
# make mutate     inject faults, every one must be caught
# A testbench must print FAIL on error; make then stops.
IVERILOG ?= iverilog
VVP      ?= vvp
RTL      := $(wildcard rtl/*.v)
TBS      := $(basename $(notdir $(wildcard tb/tb_*.v)))

.PHONY: mutate all clean $(TBS)
all: $(TBS)

$(TBS): %: tb/%.v $(RTL)
	@mkdir -p build
	$(IVERILOG) -g2012 -Wall -Wno-timescale -s $@ -o build/$@.vvp $(RTL) $<
	@$(VVP) -n build/$@.vvp > build/$@.log; st=$$?; cat build/$@.log; \
	  if [ $$st -ne 0 ] || grep -q FAIL build/$@.log || ! grep -q PASS build/$@.log; then echo "$@: FAILED"; exit 1; fi

mutate: all
	python3 mutate.py

clean:
	rm -rf build
