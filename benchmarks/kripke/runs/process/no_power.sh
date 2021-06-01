
nnodes=64
appname=kripke
problem_name="kripke"
problem_desc=""
common_inputdata=" --groups 64 --zones 192,144,96 --quad 64 "

echo "nodes, nesting, dset, gset, omp, power, usertime" > aggregate.csv

dramlim=0
#for pkglim in `seq 95 -5 55`;
for nranks in 1536 768 512 384 256 128 64;
do
    source ../golden_runs/run_${nnodes}_${nranks}_common.sh
    for pkglim in 0 55 95; #`seq 95 -5 55`;
    do
        if [ "${pkglim}" == "0" ]; 
        then
            power_type="no_power"
        else
            power_type="power"
        fi

        for nestiter in ${nestlist};
        do
#           echo "Nesting1=${nestiter}"
            for layoutiter in 0; #0 1; # 0==Blocked, 1==Scattered
            do
                for dsetiter in 8 16 32 64;
                do
                    for gsetiter in 1 2 4 8 16 32 64;
                    do
                        for methoditer in sweep; # bj;
                        do
                            for ompiter in ${omplist};
                            do
                                if [ "$pkglim" == "0" ]; then
                                    appdir=/g/g92/marathe1/libmsr/benchmarks/kripke_mod/build_golden/
                                    tracefilepath="/g/g92/marathe1/traces/kripke_traces/golden_runs/${nnodes}/${nranks}"
                                    curr_trace="${tracefilepath}/${power_type}/n${nestiter}/l${layoutiter}d${dsetiter}g${gsetiter}m${methoditer}P${pkglim}D${dramlim}t${ompiter}"
    
                                    retval2=`(wc -l ${tracefilepath}/${power_type}/n${nestiter}/l${layoutiter}d${dsetiter}g${gsetiter}m${methoditer}P${pkglim}D${dramlim}t${ompiter}/output 2> /dev/null) | cut -d " " -f 1`
                                    if [ \( "$retval2" == "" \) -o \( "$retval2" == "0" \) -o \( "$retval2" == "1" \) ];
                                    then
                                        echo "Doesn't exist"
                                    else
                                        usertime=`cat \
                                            ${tracefilepath}/${power_type}/n${nestiter}/l${layoutiter}d${dsetiter}g${gsetiter}m${methoditer}P${pkglim}D${dramlim}t${ompiter}/output \
                                            | grep elapsed | cut -d " " -f 3 | cut -d "e" -f 1 | awk -F: '{ print ($1 * 60) + $2 }' `
                                        echo "${nranks}, ${nestiter}, ${dsetiter}, ${gsetiter}, ${ompiter}, ${pkglim}, ${usertime}" >> aggregate.csv
                                    fi
                                fi
                            done
                        done
                    done
                done
            done
        done
    done
done
