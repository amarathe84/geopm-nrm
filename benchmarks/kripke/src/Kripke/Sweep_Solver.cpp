/*
 * NOTICE
 *
 * This work was produced at the Lawrence Livermore National Laboratory (LLNL)
 * under contract no. DE-AC-52-07NA27344 (Contract 44) between the U.S.
 * Department of Energy (DOE) and Lawrence Livermore National Security, LLC
 * (LLNS) for the operation of LLNL. The rights of the Federal Government are
 * reserved under Contract 44.
 *
 * DISCLAIMER
 *
 * This work was prepared as an account of work sponsored by an agency of the
 * United States Government. Neither the United States Government nor Lawrence
 * Livermore National Security, LLC nor any of their employees, makes any
 * warranty, express or implied, or assumes any liability or responsibility
 * for the accuracy, completeness, or usefulness of any information, apparatus,
 * product, or process disclosed, or represents that its use would not infringe
 * privately-owned rights. Reference herein to any specific commercial products,
 * process, or service by trade name, trademark, manufacturer or otherwise does
 * not necessarily constitute or imply its endorsement, recommendation, or
 * favoring by the United States Government or Lawrence Livermore National
 * Security, LLC. The views and opinions of authors expressed herein do not
 * necessarily state or reflect those of the United States Government or
 * Lawrence Livermore National Security, LLC, and shall not be used for
 * advertising or product endorsement purposes.
 *
 * NOTIFICATION OF COMMERCIAL USE
 *
 * Commercialization of this product is prohibited without notifying the
 * Department of Energy (DOE) or Lawrence Livermore National Security.
 */

#include <Kripke.h>
#include <Kripke/Subdomain.h>
#include <Kripke/SubTVec.h>
#include <Kripke/ParallelComm.h>
#include <Kripke/Grid.h>
#include <vector>
#include <stdio.h>
#ifdef _GEOPM_
#include <geopm.h>
#endif

/**
  Run solver iterations.
*/
int SweepSolver (Grid_Data *grid_data, bool block_jacobi)
{
  Kernel *kernel = grid_data->kernel;

  int mpi_rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &mpi_rank);

  grid_data->trace_offset = MPI_Wtime();
  if(grid_data->sweep_trace){
    // Get a "synchronized" time in case there is clock skew
    // this won't be perfect, but will eliminate large differences
    MPI_Bcast(&grid_data->trace_offset, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);
    grid_data->trace_offset = grid_data->trace_offset - MPI_Wtime();

    // Open a trace file based on our rank
    char fname[1024];
    snprintf(fname, 1024, "trace.%05d", mpi_rank);
    grid_data->trace_file = fopen(fname, "wb");
  }



  BLOCK_TIMER(grid_data->timing, Solve);

#ifdef _GEOPM_
  uint64_t ltimes_rid, scatter_rid, source_rid, lplus_rid, sweep_rid;

  int err = geopm_prof_region("ltimes", GEOPM_REGION_HINT_COMPUTE, &ltimes_rid);
  err = geopm_prof_region("scatter", GEOPM_REGION_HINT_UNKNOWN, &scatter_rid);
  err = geopm_prof_region("source", GEOPM_REGION_HINT_UNKNOWN, &source_rid);
  err = geopm_prof_region("lplus", GEOPM_REGION_HINT_UNKNOWN, &lplus_rid);
  err = geopm_prof_region("sweep", GEOPM_REGION_HINT_COMPUTE, &sweep_rid);
#endif

  // Loop over iterations
  double part_last = 0.0;
  for(int iter = 0;iter < grid_data->niter;++ iter){

    /*
     * Compute the RHS:  rhs = LPlus*S*L*psi + Q
     */

    // Discrete to Moments transformation (phi = L*psi)
    {
      BLOCK_TIMER(grid_data->timing, LTimes);
#ifdef _GEOPM_
      err = geopm_prof_enter(ltimes_rid);
#endif    
      kernel->LTimes(grid_data);
#ifdef _GEOPM_
      err = geopm_prof_exit(ltimes_rid);
#endif    
    }

    // Compute Scattering Source Term (psi_out = S*phi)
    {
      BLOCK_TIMER(grid_data->timing, Scattering);
#ifdef _GEOPM_
      err = geopm_prof_enter(scatter_rid);
#endif    
      kernel->scattering(grid_data);
#ifdef _GEOPM_
      err = geopm_prof_exit(scatter_rid);
#endif    
    }

    // Compute External Source Term (psi_out = psi_out + Q)
    {
      BLOCK_TIMER(grid_data->timing, Source);
#ifdef _GEOPM_
      err = geopm_prof_enter(source_rid);
#endif    
      kernel->source(grid_data);
#ifdef _GEOPM_
      err = geopm_prof_exit(source_rid);
#endif    
    }

    // Moments to Discrete transformation (rhs = LPlus*psi_out)
    {
      BLOCK_TIMER(grid_data->timing, LPlusTimes);
#ifdef _GEOPM_
      err = geopm_prof_enter(lplus_rid);
#endif    
      kernel->LPlusTimes(grid_data);
#ifdef _GEOPM_
      err = geopm_prof_exit(lplus_rid);
#endif    
    }

    /*
     * Sweep (psi = Hinv*rhs)
     */
    {
      BLOCK_TIMER(grid_data->timing, Sweep);

      if(true){
        // Create a list of all groups
        std::vector<int> sdom_list(grid_data->subdomains.size());
        for(int i = 0;i < grid_data->subdomains.size();++ i){
          sdom_list[i] = i;
        }

        // Sweep everything
#ifdef _GEOPM_
        err = geopm_prof_enter(sweep_rid);
#endif    
        SweepSubdomains(sdom_list, grid_data, block_jacobi);
#ifdef _GEOPM_
        err = geopm_prof_exit(sweep_rid);
#endif    
      }
      // This is the ARDRA version, doing each groupset sweep independently
      else{
        for(int group_set = 0;group_set < grid_data->num_group_sets;++ group_set){
          std::vector<int> sdom_list;
          // Add all subdomains for this groupset
          for(int s = 0;s < grid_data->subdomains.size();++ s){
            if(grid_data->subdomains[s].idx_group_set == group_set){
              sdom_list.push_back(s);
            }
          }

          // Sweep the groupset
#ifdef _GEOPM_
          err = geopm_prof_enter(sweep_rid);
#endif    
          SweepSubdomains(sdom_list, grid_data, block_jacobi);
#ifdef _GEOPM_
          err = geopm_prof_exit(sweep_rid);
#endif    
        }
      }
    }
   
    {
        BLOCK_TIMER(grid_data->timing, Edit);
        double part = grid_data->particleEdit();
        if(mpi_rank==0){
          printf("iter %d: particle count=%e, change=%e\n", iter, part, (part-part_last)/part);
        }
        part_last = part;
    }

#ifdef _GEOPM_
    int err = geopm_prof_epoch();
#endif    
     MPI_Pcontrol(1);
  }

  if(grid_data->trace_file){
    fclose(grid_data->trace_file);
  }

  return(0);
}



/**
  Perform full parallel sweep algorithm on subset of subdomains.
*/
void SweepSubdomains (std::vector<int> subdomain_list, Grid_Data *grid_data, bool block_jacobi)
{
  // Create a new sweep communicator object
  ParallelComm *comm = NULL;
  if(block_jacobi){
    comm = new BlockJacobiComm(grid_data);
  }
  else {
    comm = new SweepComm(grid_data);
  }

  // Add all subdomains in our list
  for(int i = 0;i < subdomain_list.size();++ i){
    int sdom_id = subdomain_list[i];
    comm->addSubdomain(sdom_id, grid_data->subdomains[sdom_id]);
  }

  // try and synch up tasks for better sweep performance?
  //
  // MPI_Barrier(MPI_COMM_WORLD);

  /* Loop until we have finished all of our work */
  while(comm->workRemaining()){

    // Get a list of subdomains that have met dependencies
    // DEBUG: Query MPI a few times between doing actual work
    // the idea is to trick MPI into actually sending messages
    for(int i = 0;i < KRIPKE_SWEEP_EXTRA_RECV;++ i){
      comm->readySubdomains();
    }
    // now do it for real
    std::vector<int> sdom_ready = comm->readySubdomains();
    int backlog = sdom_ready.size();

    // Run top of list
    if(backlog > 0){
      int sdom_id = sdom_ready[0];
      Subdomain &sdom = grid_data->subdomains[sdom_id];
      // Clear boundary conditions
      for(int dim = 0;dim < 3;++ dim){
        if(sdom.upwind[dim].subdomain_id == -1){
          sdom.plane_data[dim]->clear(0.0);
        }
      }

      double start_time, end_time;
      if(grid_data->trace_file){
        start_time = MPI_Wtime() + grid_data->trace_offset;
      }
      {
        BLOCK_TIMER(grid_data->timing, Sweep_Kernel);
        // Perform subdomain sweep
        grid_data->kernel->sweep(&sdom);
      }
      if(grid_data->trace_file){
        end_time = MPI_Wtime() + grid_data->trace_offset;
        fprintf(grid_data->trace_file, "sweep_kernel %lf %lf %d\n", start_time, end_time, sdom_id);
      }

      // Mark as complete (and do any communication)
      comm->markComplete(sdom_id);
    }
  }

  delete comm;
}


