#!/bin/bash
set err=0
source tutorial_env.sh

export PATH=$GEOPM_BINDIR:$PATH
export PYTHONPATH=$GEOPMPY_PKGDIR:$PYTHONPATH
export LD_LIBRARY_PATH=$GEOPM_LIBDIR:$LD_LIBRARY_PATH

# OMP_NUM_THREADS=7 geopmlaunch srun \
#             -N 2 \
#             -n 8 \
#             --geopm-ctl=process \
#             --geopm-agent=power_governor \
#             --geopm-report=t3_data/tutorial_3_governed_report \
#             --geopm-trace=t3_data/tutorial_3_governed_trace \
#             --geopm-policy=tutorial_governed_policy.json \
#             -- ./tutorial_3 \
# && \
OMP_DYNAMIC=false OMP_NUM_THREADS=34 geopmlaunch srun \
            -N 2 \
            -n 2 \
            --geopm-ctl=process \
            --geopm-agent=power_balancer \
            --geopm-report=traces/omp_test_report \
            --geopm-trace=traces/omp_test_trace \
            --geopm-policy=tutorial_balanced_policy.json \
            -m block -l \
            -- ./main.geo.omp \
#&& \
#OMP_NUM_THREADS=7 geopmlaunch srun \
#            -N 2 \
#            -n 8 \
#            --geopm-preload \
#            --geopm-ctl=process \
#            --geopm-report=t3_data/tutorial_3_monitor_report \
#            --geopm-trace=t3_data/tutorial_3_monitor_trace \
#            -- ./tutorial_3
err=$?

exit $err
