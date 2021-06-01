#!/bin/bash

for nodeiter in 2 4 8 16 32;
do
#    for nestiter in 1 2;
#    do
        nodelist=`head -n 2 /g/g92/marathe1/traces/kripke_traces/${nodeiter}/32/nDGZ/l0d8g8msweepP50D0t1/rank_* | grep -A 2 Timestamp.g | grep -v Timestamp.g | grep ^1 | sed 's/\t/;/g' | cut -d ";" -f 2 | sort -n | uniq | awk '{ print "catalyst" $1 }' | paste -sd","`

        salloc -N ${nodeiter} -w $nodelist -p pbatch -t 23:00:00 --msr-safe bash -x ./run_${nodeiter}_32_kripke.sh &
#    done
done

wait
