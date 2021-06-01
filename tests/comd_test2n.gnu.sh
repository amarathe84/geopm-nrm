#!/bin/bash

numnodes=2
numtasks=44

trace_dump=/g/g92/marathe1/lscratchh/GEOPM-TOSS-Catalyst-tests/gnu
geoscripts=/usr/WS2/marathe1/GEOPM-TOSS-Test/scripts
geobenchmarks=/g/g92/marathe1/myworkspace/GEOPM-TOSS-Test/benchmarks.gnu

export OMPI_MCA_btl_openib_allow_ib=1;
export OMPI_MCA_btl_openib_warn_default_gid_prefix=0
export OMPI_MCA_mpi_warn_on_fork=0;
export OMPI_MCA_pml=ob1;
export OMPI_MCA_btl=openib;

source geopm-env.gnu.sh

# 2 nodes, 44 CoMD tasks 

comd_input="--xproc=11 --yproc=2 --zproc=2 --nx=100 --ny=100 --nz=100 -n 10 -N 100"
# comd_input="--xproc=4 --yproc=4 --zproc=3 --nx=100 --ny=100 --nz=100 -n 10 -N 100"

# geopm_mode="process"
geopm_mode="pthread"
# geopm_mode="application"

tracepath=${trace_dump}/CoMD/${geopm_mode}/${numnodes}.${numtasks}.1.180.1.balanced
mkdir -p ${tracepath} 
(OMP_PLACES="cores" OMP_NUM_THREADS=1 geopmlaunch ompi \
        --geopm-ctl=${geopm_mode} \
        --geopm-policy=${geoscripts}/test_balanced_policy.json \
        --geopm-agent=power_balancer \
        --geopm-report=${tracepath}/report \
        --geopm-trace=${tracepath}/trace \
        -H catalyst321,catalyst322 -n ${numtasks} -npernode 22 -- \
        ${geobenchmarks}/CoMD/bin/comd.geo $comd_input 2>& 1) >& ${tracepath}/output

tracepath=${trace_dump}/CoMD/${geopm_mode}/${numnodes}.${numtasks}.1.180.1.governed
mkdir -p ${tracepath}
(OMP_PLACES="cores" OMP_NUM_THREADS=2 geopmlaunch ompi \
        --geopm-ctl=${geopm_mode} \
        --geopm-policy=${geoscripts}/test_governed_policy.json \
        --geopm-agent=power_governor \
        --geopm-report=${tracepath}/report \
        --geopm-trace=${tracepath}/trace \
        -H catalyst321,catalyst322 -n ${numtasks} -npernode 22 -- \
        ${geobenchmarks}/CoMD/bin/comd.geo $comd_input 2>& 1) >& ${tracepath}/output
