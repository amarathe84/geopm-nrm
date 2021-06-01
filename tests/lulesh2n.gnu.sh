#!/bin/bash


numnodes=2
numtasks=27

trace_dump=/g/g92/marathe1/lscratchh/GEOPM-TOSS-Catalyst-tests/gnu
geoscripts=/usr/WS2/marathe1/GEOPM-TOSS-Test/scripts
geobenchmarks=/g/g92/marathe1/myworkspace/GEOPM-TOSS-Test/benchmarks.gnu

export OMPI_MCA_btl_openib_allow_ib=1;
export OMPI_MCA_btl_openib_warn_default_gid_prefix=0
export OMPI_MCA_mpi_warn_on_fork=0;
export OMPI_MCA_pml=ob1;
export OMPI_MCA_btl=openib;

source geopm-env.gnu.sh

probsize=64
niters=10
input=" -s ${probsize} -i ${niters} -b 0 -r 100 -c 10 -p"

# geopm_mode="process"
geopm_mode="pthread"
# geopm_mode="application"

tracepath=${trace_dump}/CoMD/${numnodes}.${numtasks}.1.180.1.balanced
mkdir -p ${tracepath}
(OMP_NUM_THREADS=1 geopmlaunch srun \
        --geopm-ctl=process \
        --geopm-policy=${geoscripts}/test_balanced_policy.json \
        --geopm-agent=power_balancer \
        --geopm-report=${tracepath}/report \
        --geopm-trace=${tracepath}/trace \
        -N ${numnodes} -n ${numtasks} -m block -- \
       ${geobenchmarks}/lulesh/lulesh2.0.geo $input 2>& 1) >& ${tracepath}/output

# geopm_mode="process"
geopm_mode="pthread"

tracepath=${trace_dump}/lulesh/${geopm_mode}/${numnodes}.${numtasks}.1.180.1.governed
mkdir -p ${tracepath}
(OMP_PLACES="cores" OMP_NUM_THREADS=2 geopmlaunch ompi \
        --geopm-ctl=${geopm_mode} \
        --geopm-policy=${geoscripts}/test_governed_policy.json \
        --geopm-agent=power_governor \
        --geopm-report=${tracepath}/report \
        --geopm-trace=${tracepath}/trace \
        -H catalyst321,catalyst322 -n ${numtasks} -npernode 15 -- \
        ${geobenchmarks}/lulesh/lulesh2.0.geo $input 2>& 1) >& ${tracepath}/output



#        -N ${numnodes} -n ${numtasks} -- \
