#!/bin/bash

for nodeiter in 1 2 4 8 16;
do
    for nestiter in 1 2;
    do
        salloc -N ${nodeiter} -p pbatch -t 7:00:00 --msr-safe bash -x ./run_${nodeiter}_16_kripke.${nestiter}.sh &
    done
done

wait
