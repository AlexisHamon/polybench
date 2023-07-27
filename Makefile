all: time_benchmark unit_test all_unit_tests unit_charge all_unit_charges

define make-sh =
	echo "#! " /bin/bash > $@
	cat $< >> $@
	chmod ugo+x $@
endef

unit_test: unit_test.sh
	$(make-sh)

time_benchmark: utilities/time_benchmark.sh
	$(make-sh)

all_unit_tests: all_unit_tests.sh
	$(make-sh)

unit_charge: unit_charge.sh
	$(make-sh)

all_unit_charges: all_unit_charges.sh
	$(make-sh)

clean:
	rm -f time_benchmark unit_test all_unit_tests
	rm -f tmp/*