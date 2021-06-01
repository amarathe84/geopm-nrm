#!/bin/bash


numnodes=2
numtasks=44

trace_dump=/g/g92/marathe1/lscratchh/GEOPM-TOSS-Catalyst-tests/intel
geoscripts=/usr/WS2/marathe1/GEOPM-TOSS-Test/scripts
geobenchmarks=/g/g92/marathe1/myworkspace/GEOPM-TOSS-Test/benchmarks.intel

# Turn off OpenMPI warnings
export OMPI_MCA_btl_openib_allow_ib=1;
export OMPI_MCA_btl_openib_warn_default_gid_prefix=0
export OMPI_MCA_mpi_warn_on_fork=0;
source geopm-env.intel.sh

# 16 nodes, 384 total, 368 CoMD tasks
#comd_input=" --xproc=4 --yproc=4 --zproc=23 --nx=40 --ny=40 --nz=80 -n 200 -N 4000"
#actual_tasks=`expr ${numtasks} - ${numnodes}`
#comd_input=`cat comd_input.${numtasks}`

comd_input="--xproc=11 --yproc=2 --zproc=2 --nx=100 --ny=100 --nz=100 -n 10 -N 100"

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

geopm_mode="pthread"

tracepath=${trace_dump}/CoMD/${geopm_mode}/${numnodes}.${numtasks}.1.180.1.governed
mkdir -p ${tracepath}
(OMP_NUM_THREADS=1 geopmlaunch srun \
        --geopm-ctl=${geopm_mode} \
        --geopm-policy=${geoscripts}/test_governed_policy.json \
        --geopm-agent=power_governor \
        --geopm-report=${tracepath}/report \
        --geopm-trace=${tracepath}/trace \
        -N ${numnodes} -n ${numtasks} -m block -- \
        ${geobenchmarks}/CoMD/bin/comd.geo $comd_input 2>& 1) >& ${tracepath}/output
