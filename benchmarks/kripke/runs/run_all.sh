#!/bin/bash

for rankiter in 4 8 16 32;
do
    for nestiter in DGZ DZG GDZ GZD ZDG ZGD; 
    do
        salloc -N 2 -p pbatch -t 10:00:00 --msr-safe bash -x ./run_2_${rankiter}_kripke.sh ${nestiter} &
    done
done

wait
