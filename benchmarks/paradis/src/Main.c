/***************************************************************************
 *
 *  Function    : Main
 *  Description : main routine for ParaDiS simulation
 *
 **************************************************************************/
#include <stdio.h>
#include <time.h>
#include "Home.h"
#include "Init.h"
#include <geopm.h>


#ifdef PARALLEL
#include "mpi.h"
#endif

#ifdef FPES_ON
#include <fpcontrol.h>
#endif


uint64_t paradisinit_rid, nodeforce_rid, rebalance_rid, migrate_rid, recyclegn_rid, sortnative_rid, commsend_rid, cellcharge_rid, stepint_rid, resetglide_rid, getdensity_rid, deltaplasticstrain_rid, inittopology_rid, splitmultinodes_rid, crossslip_rid, handlecollisions_rid, commsendremesh_rid, fixremesh_rid, applydeltastress_rid, rebalance_rid, sortnative_rid; 
main (int argc, char *argv[])
{
        int     cycleEnd, memSize, initialDLBCycles;
        time_t  tp;
        Home_t  *home;
        Param_t *param;
        uint64_t main_rid;
/*
 *      On some systems, the getrusage() call made by Meminfo() to get
 *      the memory resident set size does not work properly.  In those
 *      cases, the function will try to return the current heap size 
 *      instead.  This initial call allows meminfo() to get a copy of
 *      the original heap pointer so subsequent calls can calculate the
 *      heap size by taking the diference of the original and current
 *      heap pointers.
 */
        Meminfo(&memSize);

/*
 *      on linux systems (e.g. MCR) if built to have floating point exceptions
 *      turned on, invoke macro to do so
 */
   
#ifdef FPES_ON
        unmask_std_fpes();
#endif
 
        ParadisInit(argc, argv, &home);
        int err = geopm_prof_region("nodeforce", GEOPM_REGION_HINT_COMPUTE, &nodeforce_rid);
        err = geopm_prof_region("rebalance", GEOPM_REGION_HINT_COMPUTE, &rebalance_rid);
        err = geopm_prof_region("migrate", GEOPM_REGION_HINT_COMPUTE, &migrate_rid);
        err = geopm_prof_region("recyclegn", GEOPM_REGION_HINT_COMPUTE, &recyclegn_rid);
        err = geopm_prof_region("sortnative", GEOPM_REGION_HINT_COMPUTE, &sortnative_rid);
        err = geopm_prof_region("commsend", GEOPM_REGION_HINT_COMPUTE, &commsend_rid);
        err = geopm_prof_region("cellcharge", GEOPM_REGION_HINT_COMPUTE, &cellcharge_rid);
        err = geopm_prof_region("stepint", GEOPM_REGION_HINT_COMPUTE, &stepint_rid);
        err = geopm_prof_region("resetglide", GEOPM_REGION_HINT_COMPUTE, &resetglide_rid);
        err = geopm_prof_region("getdensity", GEOPM_REGION_HINT_COMPUTE, &getdensity_rid);
        err = geopm_prof_region("deltaplasticstrain", GEOPM_REGION_HINT_COMPUTE, &deltaplasticstrain_rid);
        err = geopm_prof_region("inittopology", GEOPM_REGION_HINT_COMPUTE, &inittopology_rid);
        err = geopm_prof_region("splitmultinodes", GEOPM_REGION_HINT_COMPUTE, &splitmultinodes_rid);
        err = geopm_prof_region("crossslip", GEOPM_REGION_HINT_COMPUTE, &crossslip_rid);
        err = geopm_prof_region("handlecollisions", GEOPM_REGION_HINT_COMPUTE, &handlecollisions_rid);
        err = geopm_prof_region("commsendremesh", GEOPM_REGION_HINT_COMPUTE, &commsendremesh_rid);
        err = geopm_prof_region("fixremesh", GEOPM_REGION_HINT_COMPUTE, &fixremesh_rid);
        err = geopm_prof_region("applydeltastress", GEOPM_REGION_HINT_COMPUTE, &applydeltastress_rid);
        err = geopm_prof_region("rebalance", GEOPM_REGION_HINT_COMPUTE, &rebalance_rid);
        err = geopm_prof_region("sortnative", GEOPM_REGION_HINT_COMPUTE, &sortnative_rid);


  
        home->cycle      = home->param->cycleStart;

        param            = home->param;
        cycleEnd         = param->cycleStart + param->maxstep;
        initialDLBCycles = param->numDLBCycles;

/*
 *      Perform the needed number (if any) of load-balance-only
 *      steps before doing the main processing loop.  These steps
 *      perform only the minimal amount of stuff needed to
 *      estimate per-process load, move boundaries and migrate
 *      nodes among processsors to get a good initial balance.
 */
        TimerStart(home, INITIALIZE);

        if ((home->myDomain == 0) && (initialDLBCycles != 0)) {
            time(&tp);
            printf("  +++ Beginning %d load-balancing steps at %s",
                   initialDLBCycles, asctime(localtime(&tp)));
        }

        while (param->numDLBCycles > 0) {
            ParadisStep(home);
            home->cycle++;
            param->numDLBCycles--;
            err = geopm_prof_epoch();
            //MPI_Pcontrol(0);
        }

        if ((home->myDomain == 0) && (initialDLBCycles != 0)) {
            time(&tp);
            printf("  +++ Completed load-balancing steps at %s",
                   asctime(localtime(&tp)));
        }

        TimerStop(home, INITIALIZE);
        
/*
 *      Any time spent doing the initial DLB-only steps should
 *      just be attributed to initialization time, so be sure to
 *      reset the other timers before going into the main
 *      computational loop
 */
        TimerInitDLBReset(home);

/*
 *      The cycle number may have been incremented during the initial
 *      load-balance steps, so reset it to the proper starting
 *      value before entering the main processing loop.
 */
        home->cycle = home->param->cycleStart;

        while (home->cycle < cycleEnd) {
            ParadisStep(home);
            TimerClearAll(home);
            MPI_Pcontrol(0);
        }
        ParadisFinish(home);

        exit(0);
}
