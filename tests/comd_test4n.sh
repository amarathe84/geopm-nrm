#!/bin/bash


numnodes=4
numtasks=88

trace_dump=/g/g92/marathe1/lscratchh/GEOPM-TOSS-Catalyst-tests/
geoscripts=/usr/WS2/marathe1/GEOPM-TOSS-Test/scripts
geobenchmarks=/g/g92/marathe1/myworkspace/GEOPM-TOSS-Test/benchmarks

source geopm-env.sh

# 16 nodes, 384 total, 368 CoMD tasks
#comd_input=" --xproc=4 --yproc=4 --zproc=23 --nx=40 --ny=40 --nz=80 -n 200 -N 4000"
#actual_tasks=`expr ${numtasks} - ${numnodes}`
comd_input=`cat comd_input.${numtasks}`

# tracepath=${trace_dump}/CoMD/${numnodes}.${numtasks}.1.180.1.balanced
# mkdir -p ${tracepath} 
# (OMP_NUM_THREADS=1 geopmlaunch srun \
#         --geopm-ctl=process \
#         --geopm-policy=${geoscripts}/test_balanced_policy.json \
#         --geopm-agent=power_balancer \
#         --geopm-report=${tracepath}/report \
#         --geopm-trace=${tracepath}/trace \
#         -N ${numnodes} -n ${numtasks} -m block -- \
#         ${geobenchmarks}/CoMD/bin/comd.geo $comd_input 2>& 1) >& ${tracepath}/output

tracepath=${trace_dump}/CoMD/${numnodes}.${numtasks}.1.180.1.governed
mkdir -p ${tracepath}
(OMP_NUM_THREADS=1 geopmlaunch srun \
        --geopm-ctl=process \
        --geopm-policy=${geoscripts}/test_governed_policy.json \
        --geopm-agent=power_governor \
        --geopm-report=${tracepath}/report \
        --geopm-trace=${tracepath}/trace \
        -N ${numnodes} -n ${numtasks} -m block -- \
        ${geobenchmarks}/CoMD/bin/comd.geo $comd_input 2>& 1) >& ${tracepath}/output
