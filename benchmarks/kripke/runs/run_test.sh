#!/bin/bash

blr_data_dir=/p/lscratchf/rountree/ipmi_dat

solverid=$1

traceprefix="rank"
nnodes=2
nranks=4
nranks_per_socket=1
appname=kripke
appdir=/g/g92/marathe1/libmsr/benchmarks/kripke/build/bin
problem_name="kripke"
problem_desc=""
tracefilepath="/g/g92/marathe1/traces/kripke_traces/${problem_name}_openmp/${nranks}"
whitelistpath="/g/g92/marathe1/libmsr/msr-safe/whitelists"

srun_options="--cpu_bind=rank --ntasks-per-socket=${nranks_per_socket} --sockets-per-node=2"

#ipmi_dir=/g/g92/marathe1/traces/hypre_new_ij/${problem_name}_openmp/${nranks}/s${solverid}/
#ipmi_dir=${tracefilepath}/s${solverid}/
cd ${appdir}

#dramlim=0.0

##for solveriter in 0 1 4 7;
#for solveriter in ${solverid};
#do
#    inputdata=" -n 256 256 256 -P 2 2 2 -intertype 6 -tol 1e-8 -CF 0 -solver ${solveriter} -agg_nl 1 -${problem_name}" 
#    #for smootheriter in 3 4 6 8 13 14 16;
#    for smootheriter in 3 4 13 16;
#    do
#        for coarseniter in "hmis" "pmis";
#    #    for coarseniter in "cgc"; # "cljp"; #"hmis" "pmis";
#        do
#            for pmxiter in `seq 2 4 10`;
#            do
#                for nsiter in 4; #`seq 1 1 4`;
#                do
#                    for muiter in 1 2;
#                    do
#                        for pkglim in `seq 50 10 100`;
#                        do
#                            for ompiter in 1 2 3 4 5 6 7 8 9 10 11 12;
#                            do
    #                        for dramlim in `seq 40 5 60`;
    #                        do
#                                retval2=`(wc -l ${tracefilepath}/s${solveriter}/m${smootheriter}c${coarsening_name}p${pmxiter}n${nsiter}m${muiter}P${pkglim}D${dramlim}t${ompiter}/rank_0 2> /dev/null) | cut -d " " -f 1`
#                                if [ -s "${tracefilepath}/s${solveriter}/m${smootheriter}c${coarsening_name}p${pmxiter}n${nsiter}m${muiter}P${pkglim}D${dramlim}t${ompiter}/rank_0" ]; 
#                                if [ \( "$retval2" == "" \) -o \( "$retval2" == "0" \) -o \( "$retval2" == "1" \) ];
#                                then
                                    curr_trace="/g/g92/marathe1/traces/kripke_traces/test"
                                    mkdir -p ${curr_trace}
                                    chmod 766 ${curr_trace} -R
                                    local_input=" --groups 64 --zones 16,16,16 --nest DGZ --layout 0 --procs 2,2,1 --dset 8 --gset 64 --zset 1,1,1 --niter 20 --pmethod sweep"
                                    ompiter=12
                                    pkglim=100
                                    dramlim=0


                                    OMP_NUM_THREADS=${ompiter} \
                                    PKG_POWERLIMIT=${pkglim} DRAM_POWERLIMIT=${dramlim} \
                                    KMP_AFFINITY=compact PROCESS_PER_SAMPLER=2 \
                                    ENABLE_SAMPLING=1 SAMPLING_INTERVAL=100 \
                                    TRACEFILE_PATH=${curr_trace} \
                                    TRACE_PREFIX="rank" \
                                    ENABLE_PHASE_FILE=1 \
                                    ENABLE_PHASE_ID=1 \
                                    ENABLE_MPI_DATA=0 \
                                    ENABLE_MSR_DATA=0 \
                                    ENABLE_POWER_DATA=1 \
                                    ENABLE_OPENMP_DATA=0 \
                                    srun -N ${nnodes} -n ${nranks} \
                                    -m block \
                                    --cpu_bind=rank \
                                    --ntasks-per-socket=${nranks_per_socket} \
                                    --sockets-per-node=2 \
                                    --msr-safe \
                                    ./${appname} ${local_input}
#                                 else 
#                                     echo "Exists"
#                                 fi
#                             done
#                         done
#                     done
#                 done
#             done
#         done
#     done            
# done

cd -
