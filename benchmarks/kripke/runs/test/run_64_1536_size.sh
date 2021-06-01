#!/bin/bash

blr_data_dir=/p/lscratchf/rountree/ipmi_dat

traceprefix="rank"
nnodes=64
nranks=1536
nranks_per_socket=12
appname=kripke
appdir=/g/g92/marathe1/libmsr/benchmarks/kripke/runs
problem_name="kripke"
problem_desc=""
tracefilepath="/g/g92/marathe1/traces/kripke_traces/test/${nnodes}/${nranks}"
whitelistpath="/g/g92/marathe1/libmsr/msr-safe/whitelists"

#ipmi_dir=/g/g92/marathe1/traces/hypre_new_ij/${problem_name}_openmp/${nranks}/s${solverid}/
#ipmi_dir=${tracefilepath}/s${solverid}/
cd ${appdir}

dramlim=0
inputdata=" --groups 512 --zones 92,92,92 --quad 512 --procs 16,6,16 --niter 2 " 
#for nestiter in DGZ DZG GDZ;
#for nestiter in DGZ; #DZG GDZ GZD ZDG ZGD;
#for nestiter in DGZ DZG GDZ GZD ZDG ZGD;
####   for nestiter in DGZ; # ZDG ZGD;
####   do
####   #    nestiter=$1
####       for layoutiter in 0; #1; # 0==Blocked, 1==Scattered
####       do
####           for dsetiter in 8 16 32; #16 32;
####   #        for dsetiter in 16;
####           do
####               for gsetiter in 4 8 16; #16 32 64;
####   #            for gsetiter in 16 32;
####               do
####                   methoditer="sweep"
####   #                methoditer="bj"
####   #                for methoditer in sweep bj;
####   #                do
####                       for pkglim in 110; #110; #`seq 50 10 100`;
####                       do
####                           for ompiter in 12; #4 6 12;
####                           do
                            nestiter="ZGD"
                            layoutiter=0
                            dsetiter=32   # Has to be multiple of 8 and --quad has to be a multiple of this
                            gsetiter=64   # has to  be a factor of --groups
                            methoditer="sweep"
                            pkglim=50
                            ompiter=1
                            
                            retval2=`(wc -l ${tracefilepath}/n${nestiter}/l${layoutiter}d${dsetiter}g${gsetiter}m${methoditer}P${pkglim}D${dramlim}t${ompiter}/rank_0 2> /dev/null) | cut -d " " -f 1`
####                               if [ \( "$retval2" == "" \) -o \( "$retval2" == "0" \) -o \( "$retval2" == "1" \) ];
####                               then
                                curr_trace="${tracefilepath}/n${nestiter}/l${layoutiter}d${dsetiter}g${gsetiter}m${methoditer}P${pkglim}D${dramlim}t${ompiter}"
                                mkdir -p ${curr_trace}
                                chmod 766 ${curr_trace} -R
                                local_input=" --nest ${nestiter} --layout ${layoutiter} --dset ${dsetiter} --gset ${gsetiter} --zset 1,1,1 --pmethod ${methoditer}"

                                OMP_NUM_THREADS=${ompiter} \
                                PKG_POWERLIMIT=${pkglim} DRAM_POWERLIMIT=${dramlim} \
                                KMP_AFFINITY=compact PROCESS_PER_SAMPLER=24 \
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
####                               else 
####                                   echo "Exists"
####                               fi
####                           done
####                       done
####   #                done
####               done
####           done
####       done            
####   done

cd -
