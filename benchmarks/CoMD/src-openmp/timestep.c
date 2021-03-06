/// \file
/// Leapfrog time integrator

#include "timestep.h"

#include <omp.h>

#include "CoMDTypes.h"
#include "linkCells.h"
#include "parallel.h"
#include "performanceTimers.h"
#ifdef _GEOPM_
#include <geopm.h>
#endif

static void advanceVelocity(SimFlat* s, int nBoxes, real_t dt);
static void advancePosition(SimFlat* s, int nBoxes, real_t dt);

#ifdef _GEOPM_
extern uint64_t advanceVelocity_rid;
extern uint64_t advancePosition_rid;
extern uint64_t redistributeAtoms_rid;
extern uint64_t computeForce_rid;
extern uint64_t advanceVelocity_rid;
extern uint64_t kineticEnergy_rid;
#endif

/// Advance the simulation time to t+dt using a leap frog method
/// (equivalent to velocity verlet).
///
/// Forces must be computed before calling the integrator the first time.
///
///  - Advance velocities half time step using forces
///  - Advance positions full time step using velocities
///  - Update link cells and exchange remote particles
///  - Compute forces
///  - Update velocities half time step using forces
///
/// This leaves positions, velocities, and forces at t+dt, with the
/// forces ready to perform the half step velocity update at the top of
/// the next call.
///
/// After nSteps the kinetic energy is computed for diagnostic output.
double timestep(SimFlat* s, int nSteps, real_t dt)
{
   int err;
   for (int ii=0; ii<nSteps; ++ii)
   {
      startTimer(velocityTimer);
#ifdef _GEOPM_
      err = geopm_prof_enter(advanceVelocity_rid);
#endif
      advanceVelocity(s, s->boxes->nLocalBoxes, 0.5*dt); 
#ifdef _GEOPM_
      err = geopm_prof_exit(advanceVelocity_rid);
#endif
      stopTimer(velocityTimer);

      startTimer(positionTimer);
#ifdef _GEOPM_
      err = geopm_prof_enter(advancePosition_rid);
#endif
      advancePosition(s, s->boxes->nLocalBoxes, dt);
#ifdef _GEOPM_
      err = geopm_prof_exit(advancePosition_rid);
#endif
      stopTimer(positionTimer);

      startTimer(redistributeTimer);
#ifdef _GEOPM_
      err = geopm_prof_enter(redistributeAtoms_rid);
#endif
      redistributeAtoms(s);
#ifdef _GEOPM_
      err = geopm_prof_exit(redistributeAtoms_rid);
#endif
      stopTimer(redistributeTimer);

      startTimer(computeForceTimer);
#ifdef _GEOPM_
      err = geopm_prof_enter(computeForce_rid);
#endif
      computeForce(s);
#ifdef _GEOPM_
      err = geopm_prof_exit(computeForce_rid);
#endif
      stopTimer(computeForceTimer);

      startTimer(velocityTimer);
#ifdef _GEOPM_
      err = geopm_prof_enter(advanceVelocity_rid);
#endif
      advanceVelocity(s, s->boxes->nLocalBoxes, 0.5*dt); 
#ifdef _GEOPM_
      err = geopm_prof_exit(advanceVelocity_rid);
#endif
      stopTimer(velocityTimer);
   }

#ifdef _GEOPM_
   err = geopm_prof_enter(kineticEnergy_rid);
#endif
   kineticEnergy(s);
#ifdef _GEOPM_
   err = geopm_prof_exit(kineticEnergy_rid);
#endif

   return s->ePotential;
}

void computeForce(SimFlat* s)
{
   s->pot->force(s);
}


void advanceVelocity(SimFlat* s, int nBoxes, real_t dt)
{
   #pragma omp parallel for
   for (int iBox=0; iBox<nBoxes; iBox++)
   {
      for (int iOff=MAXATOMS*iBox,ii=0; ii<s->boxes->nAtoms[iBox]; ii++,iOff++)
      {
         s->atoms->p[iOff][0] += dt*s->atoms->f[iOff][0];
         s->atoms->p[iOff][1] += dt*s->atoms->f[iOff][1];
         s->atoms->p[iOff][2] += dt*s->atoms->f[iOff][2];
      }
   }
}

void advancePosition(SimFlat* s, int nBoxes, real_t dt)
{
   #pragma omp parallel for
   for (int iBox=0; iBox<nBoxes; iBox++)
   {
      for (int iOff=MAXATOMS*iBox,ii=0; ii<s->boxes->nAtoms[iBox]; ii++,iOff++)
      {
         int iSpecies = s->atoms->iSpecies[iOff];
         real_t invMass = 1.0/s->species[iSpecies].mass;
         s->atoms->r[iOff][0] += dt*s->atoms->p[iOff][0]*invMass;
         s->atoms->r[iOff][1] += dt*s->atoms->p[iOff][1]*invMass;
         s->atoms->r[iOff][2] += dt*s->atoms->p[iOff][2]*invMass;
      }
   }
}

/// Calculates total kinetic and potential energy across all tasks.  The
/// local potential energy is a by-product of the force routine.
void kineticEnergy(SimFlat* s)
{
   real_t eLocal[2];
   real_t kenergy = 0.0;
   eLocal[0] = s->ePotential;
   eLocal[1] = 0;
   #pragma omp parallel for reduction(+:kenergy)
   for (int iBox=0; iBox<s->boxes->nLocalBoxes; iBox++)
   {
      for (int iOff=MAXATOMS*iBox,ii=0; ii<s->boxes->nAtoms[iBox]; ii++,iOff++)
      {
         int iSpecies = s->atoms->iSpecies[iOff];
         real_t invMass = 0.5/s->species[iSpecies].mass;
         kenergy += ( s->atoms->p[iOff][0] * s->atoms->p[iOff][0] +
         s->atoms->p[iOff][1] * s->atoms->p[iOff][1] +
         s->atoms->p[iOff][2] * s->atoms->p[iOff][2] )*invMass;
      }
   }

   eLocal[1] = kenergy;

   real_t eSum[2];
   startTimer(commReduceTimer);
   addRealParallel(eLocal, eSum, 2);
   stopTimer(commReduceTimer);

   s->ePotential = eSum[0];
   s->eKinetic = eSum[1];
}

/// \details
/// This function provides one-stop shopping for the sequence of events
/// that must occur for a proper exchange of halo atoms after the atom
/// positions have been updated by the integrator.
///
/// - updateLinkCells: Since atoms have moved, some may be in the wrong
///   link cells.
/// - haloExchange (atom version): Sends atom data to remote tasks. 
/// - sort: Sort the atoms.
///
/// \see updateLinkCells
/// \see initAtomHaloExchange
/// \see sortAtomsInCell
void redistributeAtoms(SimFlat* sim)
{
   updateLinkCells(sim->boxes, sim->atoms);

   startTimer(atomHaloTimer);
   haloExchange(sim->atomExchange, sim);
   stopTimer(atomHaloTimer);

   #pragma omp parallel for
   for (int ii=0; ii<sim->boxes->nTotalBoxes; ++ii)
      sortAtomsInCell(sim->atoms, sim->boxes, ii);
}
