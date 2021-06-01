#!/bin/bash

salloc -w catalyst314,catalyst315 -N 2 -t 23:59:59 --msr-safe -ppbatch bash -x run_2_32_kripke.sh 2>&1 &>> ~/traces/kripke_traces/log_2_32 &
salloc -w catalyst316,catalyst317,catalyst318,catalyst319 -N 4 -t 23:59:59 --msr-safe -ppbatch bash -x run_4_32_kripke.sh 2>&1 &>> ~/traces/kripke_traces/log_4_32 &
salloc -w catalyst167,catalyst168,catalyst169,catalyst170,catalyst171,catalyst172,catalyst173,catalyst174 -N 8 -t 23:59:59 --msr-safe -ppbatch bash -x run_8_32_kripke.sh 2>&1 &>> ~/traces/kripke_traces/log_8_32 &
salloc -w catalyst1,catalyst2,catalyst3,catalyst4,catalyst5,catalyst6,catalyst7,catalyst8,catalyst9,catalyst10,catalyst11,catalyst12,catalyst13,catalyst14,catalyst15,catalyst16 -N 16 -t 23:59:59 -ppbatch --msr-safe bash -x run_16_32_kripke.sh 2>&1 &>> ~/traces/kripke_traces/log_16_32 &
salloc -w catalyst260,catalyst261,catalyst262,catalyst263,catalyst264,catalyst265,catalyst266,catalyst267,catalyst268,catalyst269,catalyst270,catalyst271,catalyst272,catalyst273,catalyst274,catalyst275,catalyst276,catalyst277,catalyst278,catalyst279,catalyst280,catalyst281,catalyst282,catalyst283,catalyst284,catalyst285,catalyst286,catalyst287,catalyst288,catalyst289,catalyst290,catalyst291 -N 32 -t 23:59:59 --msr-safe -ppbatch bash -x run_32_32_kripke.sh 2>&1 &>> ~/traces/kripke_traces/log_32_32 &
