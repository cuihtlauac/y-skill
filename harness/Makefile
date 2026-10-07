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
##              one wrong value per skill, each graded on its own, so a dead
##              gate for one skill cannot hide behind the others' failures.
broken:
	@printf 'g-rec 4 -2\ns-rec 6 130\nq-rec 5 40\nz-rec 5 23\ncollatz 27 110\nword-rev stressed stressed\nski-eval add(2)(3) 6\nski-eval mul(6)(9) 42\n' > $(H)broken.txt
	@rc=0; \
	while IFS= read -r line; do \
		printf '%s\n' "$$line" > $(H)broken-case.txt; \
		if sh $(H)grade.sh $(H)broken-case.txt >/dev/null 2>&1; then \
			echo "UNEXPECTED: harness passed a broken variant: $$line"; rc=1; \
		fi; \
	done < $(H)broken.txt; \
	rm -f $(H)broken.txt $(H)broken-case.txt; \
	if [ "$$rc" = 0 ]; then \
		echo "OK: harness rejected every broken variant, each graded alone"; \
	else \
		exit 1; \
	fi

clean:
	@rm -f $(H)broken.txt $(H)broken-case.txt
