

time_benchmark: utilities/time_benchmark.sh
	echo "#! " /bin/sh > time_benchmark
	cat utilities/time_benchmark.sh >> time_benchmark
	chmod ugo+x time_benchmark

clean:
	rm time_benchmark