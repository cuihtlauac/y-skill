# Minimum test harness for the y-skill combinator.
# Run from the repo root:  make -C harness   (or: cd harness && make)
ROOT ?= ..
H    := $(dir $(lastword $(MAKEFILE_LIST)))

.PHONY: test structural grade broken clean

## test       : structural gate, then behavioural gate on the baseline
test: structural grade

## structural : kept sections verbatim across all child skills
structural:
	@sh $(H)structural.sh $(ROOT)

## grade      : exercised values vs the OCaml oracle (harness/results.txt)
grade:
	@sh $(H)grade.sh $(H)results.txt

## broken     : negative control — grading the injected faults MUST fail
##              one wrong value per recursion (incl. collatz) to prove each
##              skill's behavioural gate is live, not just g-rec's.
broken:
	@printf 'g-rec 4 -2\ns-rec 6 130\nq-rec 5 40\nz-rec 5 23\ncollatz 27 110\nword-rev stressed stressed\n' > $(H)broken.txt
	@if sh $(H)grade.sh $(H)broken.txt >/dev/null 2>&1; then \
		echo "UNEXPECTED: harness passed a broken variant"; rm -f $(H)broken.txt; exit 1; \
	else \
		echo "OK: harness rejected the broken variants (as it should)"; rm -f $(H)broken.txt; \
	fi

clean:
	@rm -f $(H)broken.txt
