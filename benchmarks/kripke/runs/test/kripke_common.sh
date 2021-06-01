
nranks=$1

blr_data_dir=/p/lscratchf/rountree/ipmi_dat
traceprefix="rank"
nnodes=64
appname=kripke
appdir=/g/g92/marathe1/libmsr/benchmarks/kripke/runs
problem_name="kripke"
problem_desc=""
#common_inputdata=" --groups 512 --zones 92,92,92 --quad 512 "
common_inputdata=" --groups 256 --zones 92,92,92 --quad 256 "

source run_${nnodes}_${nranks}_common.sh
tracefilepath="/g/g92/marathe1/traces/kripke_traces/${nnodes}/${nranks}"
inputdata=`echo "${common_inputdata} ${rank_input} --niter 2"`

process_per_sampler=`echo "${nranks_per_socket} * 2" | bc`
whitelistpath="/g/g92/marathe1/libmsr/msr-safe/whitelists"
cd ${appdir}

dramlim=0
for nestiter in ${nestlist};
do
    echo "Nesting1=${nestiter}"
    for layoutiter in 0; #1; # 0==Blocked, 1==Scattered
    do
        for dsetiter in 8 16 32;
        do
            for gsetiter in 1 2 4 8;
            do
                for methoditer in sweep; # bj;
                do
                    for pkglim in `seq 50 10 100`;
                    do
                        for ompiter in ${omplist}; 
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
                                KMP_AFFINITY=compact PROCESS_PER_SAMPLER=${process_per_sampler} \
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
                                --sockets-per-node=${sockets_per_node} \
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
