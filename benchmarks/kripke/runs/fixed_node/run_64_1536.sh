#!/bin/bash

blr_data_dir=/p/lscratchf/rountree/ipmi_dat

traceprefix="rank"
nnodes=2
nranks=32
nranks_per_socket=8
nranks_per_sampling_thread=`echo "${nranks_per_socket} * 2" | bc`
appname=kripke
appdir=/g/g92/marathe1/libmsr/benchmarks/kripke/runs
problem_name="kripke"
problem_desc=""
tracefilepath="/g/g92/marathe1/traces/kripke_traces/${nnodes}/${nranks}"
whitelistpath="/g/g92/marathe1/libmsr/msr-safe/whitelists"

srun_options="--cpu_bind=rank --ntasks-per-socket=${nranks_per_socket} --sockets-per-node=2"

#ipmi_dir=/g/g92/marathe1/traces/hypre_new_ij/${problem_name}_openmp/${nranks}/s${solverid}/
#ipmi_dir=${tracefilepath}/s${solverid}/
cd ${appdir}

dramlim=0
inputdata=" --groups 16 --zones 92,92,92 --procs 4,4,2 --niter 20 " 
#for nestiter in DGZ DZG GDZ;
for methoditer in sweep; #bj;
do
    for nestiter in DGZ DZG GDZ GZD ZDG ZGD;
    do
        for layoutiter in 0; #1; # 0==Blocked, 1==Scattered
        do
            for dsetiter in 8 16 32;
            do
                for gsetiter in 4 8 16;
                do
                    for zsetiter in 4 8 16;
                    do
                        for pkglim in `seq 50 10 100`;
                        do
                            for ompiter in 1;
                            do
                                retval2=`(wc -l ${tracefilepath}/n${nestiter}/l${layoutiter}d${dsetiter}g${gsetiter}m${methoditer}P${pkglim}D${dramlim}t${ompiter}/rank_0 2> /dev/null) | cut -d " " -f 1`
                                if [ \( "$retval2" == "" \) -o \( "$retval2" == "0" \) -o \( "$retval2" == "1" \) ];
                                then
                                    curr_trace="${tracefilepath}/n${nestiter}/l${layoutiter}d${dsetiter}g${gsetiter}m${methoditer}P${pkglim}D${dramlim}t${ompiter}"
                                    mkdir -p ${curr_trace}
                                    chmod 766 ${curr_trace} -R
                                    local_input=" --nest ${nestiter} --layout ${layoutiter} --dset ${dsetiter} --gset ${gsetiter} --zset 1,1,1 --pmethod ${methoditer}"

                                    OMP_NUM_THREADS=${ompiter} \
                                    PKG_POWERLIMIT=${pkglim} DRAM_POWERLIMIT=${dramlim} \
                                    KMP_AFFINITY=compact PROCESS_PER_SAMPLER=${nranks_per_sampling_thread} \
                                    ENABLE_SAMPLING=1 SAMPLING_INTERVAL=100 \
                                    TRACEFILE_PATH=${curr_trace} \
                                    TRACE_PREFIX="rank" \
                                    ENABLE_PHASE_FILE=0 \
                                    ENABLE_PHASE_ID=0 \
                                    ENABLE_MPI_DATA=0 \
                                    ENABLE_MSR_DATA=1 \
                                    ENABLE_POWER_DATA=1 \
                                    ENABLE_OPENMP_DATA=0 \
                                    srun -N ${nnodes} -n ${nranks} \
                                    -m block \
                                    --cpu_bind=rank \
                                    --ntasks-per-socket=${nranks_per_socket} \
                                    --sockets-per-node=2 \
                                    --msr-safe \
                                    ${appdir}/${appname} ${inputdata} ${local_input}
                                else 
                                    echo "Exists"
                                fi
                            done
                        done
                    done
                done
            done
        done
    done            
done

cd -
