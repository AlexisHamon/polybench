all: time_benchmark unit_test all_unit_tests unit_charge all_unit_charges

unit_test: unit_test.sh
	echo "#! " /bin/bash > $@
	cat $< >> $@
	chmod ugo+x $@

time_benchmark: utilities/time_benchmark.sh
	echo "#! " /bin/sh > $@
	cat $< >> $@
	chmod ugo+x $@

all_unit_tests: all_unit_tests.sh
	echo "#! " /bin/sh > $@
	cat $< >> $@
	chmod ugo+x $@

unit_charge: unit_charge.sh
	echo "#! " /bin/bash > $@
	cat $< >> $@
	chmod ugo+x $@

all_unit_charges: all_unit_charges.sh
	echo "#! " /bin/sh > $@
	cat $< >> $@
	chmod ugo+x $@

clean:
	rm -f time_benchmark unit_test all_unit_tests
	rm tmp/*