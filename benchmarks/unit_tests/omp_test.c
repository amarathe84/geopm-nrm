/* Test application for GEOPM Caliper service.
 * The application tests the following GEOPM annotations and mappings:
 * (GEOPM) geopm_prof_region   -- (Caliper) first occurrence of 
 *                              phase start, loop begin, function start
 * (GEOPM) geopm_prof_enter    -- (Caliper) phase start, loop begin, 
 *                              function start
 * (GEOPM) geopm_prof_exit     -- (Caliper) phase end, loop end, 
 *                              function end
 * (GEOPM) geopm_prof_progress -- (Caliper) end of iteration#xxx attribute
 * (GEOPM) geopm_prof_epoch    -- (Caliper) iteration#mainloop end
 * (GEOPM) geopm_tprof_create  -- (Caliper) update to xxx.loopcount
 * (GEOPM) geopm_tprof_destroy -- (Caliper) loop end
 * (GEOPM) geopm_tprof_increment -- (Caliper) end of iteration#xxx attribute
 *
 * The application builds five binaries: 
 *  main.orig:          original application (without OpenMP),
 *  main.geo:           with GEOPM markup,
 *  main.geo.omp:       with GEOPM markup and OpenMP computation phase,
 *  main.caligeo:       with Caliper markup, and
 *  main.caligeo.omp:   with Caliper markup and OpenMP computation phase
 *  
 */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <mpi.h>
#include <stdint.h>
#include <time.h>

#ifdef _GEOPM_
#include <geopm.h>
#endif

#include <omp.h>
#include <unistd.h>

#define N 1000
uint64_t func_send_recv_rid;

void do_send_recv(int rank, char *buff_ptr, char **lbuff, long buffsize, int proto, long u_sleep_time) {
    int tag=1;
    MPI_Request req;
    MPI_Status stat;
    int liter;

    for(liter = 0; liter < u_sleep_time * 10; liter++) {
        if(rank%2 != 0) {
            if(proto==1) {
                MPI_Send(buff_ptr, buffsize, MPI_CHAR, rank-1, tag, MPI_COMM_WORLD);
            } else {
                memcpy(*lbuff, buff_ptr, buffsize);
                MPI_Isend(*lbuff, buffsize, MPI_CHAR, rank-1, tag, MPI_COMM_WORLD, &req);
            }
        }
        else {
            usleep(u_sleep_time);
            MPI_Recv(buff_ptr, buffsize, MPI_CHAR, rank+1, tag, MPI_COMM_WORLD, &stat);
        }
    }
}

void do_compute_p1(long liter, long biter, uint64_t comp_rid, char *buff_ptr, long buffsize, long u_sleep_time) {
    for(liter = 0; liter < u_sleep_time * 100; liter++) {
        for(biter = 0; biter < buffsize; biter++) {
            buff_ptr[biter] += (u_sleep_time + liter) * biter;
        }
#ifdef _GEOPM_
        geopm_prof_progress(comp_rid, liter);
#endif
    }
}

static int do_compute_p2(uint64_t comp_rid, double A[][N], double B[][N], double C[][N])
{
//    int count = num_stream;
//    const size_t block = sizeof(double);
    int err = 0;
    // Mark the loop
    int i, j, m;

    #pragma omp parallel for private(m,j)
//    #pragma omp for
    for(i=0;i<N;i++) {
        int num_thread = 1;
        num_thread = omp_get_max_threads();
#ifdef _GEOPM_        
        err = geopm_tprof_init(num_thread);
#endif
        for(j=0;j<N;j++) {
            C[i][j]=0; // set initial value of resulting matrix C = 0
            for(m=0;m<N;m++) {
                C[i][j]=A[i][m]*B[m][j]+C[i][j];
            }
        }
#ifdef _GEOPM_        
        geopm_tprof_post();
#endif        
//        printf("I got %d threads\n", num_thread);
//        printf("C: %f \n",C[i][j]);
    }


//    #pragma omp parallel for
//    for (int i = 0; i < count; ++i) {
//        int num_thread = 1;
//        num_thread = omp_get_num_threads();
//#ifdef _GEOPM_        
//        err = geopm_tprof_init(num_thread);
//#endif
//        size_t j;
//        for (j = 0; j < block; ++j) {
//            a[i * block + j] = b[i * block + j] + scalar * c[i * block + j];
//            a[i * block + j] = b[i * block + j] + scalar * c[i * block + j];
//        }
//#ifdef _GEOPM_        
//        geopm_tprof_post();
//#endif        
//    }
    return err;
}

int main(int argc, char *argv[]) {
    
    int numtasks, source=0, dest, tag=1, i,j;
    int provided;

    int val = 1;
    int iter;
    char *buff_ptr, *local_buff;
    long buffsize=20000;
    int total_iter=150;
    int proto=1;
    long u_sleep_time=1;

    double t1, t2;
    MPI_Status stat;
    MPI_Request req;

    int rank;
    MPI_Init( &argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &numtasks);

    buff_ptr   = (char *) new char[buffsize];
    local_buff = (char *) new char[buffsize];

    double w1 = MPI_Wtime();
    long liter, biter;

    uint64_t comm_rid;
    uint64_t comp_rid;
#ifdef _GEOPM_
    geopm_prof_region("comm-phase", GEOPM_REGION_HINT_COMPUTE, &comm_rid);
    geopm_prof_region("comp-phase", GEOPM_REGION_HINT_COMPUTE, &comp_rid);
#endif
    double a[N][N], b[N][N], c[N][N]; // declaring matrices of NxN size

    /* FILLING MATRICES WITH RANDOM NUMBERS */
    srand ( time(NULL) );
    for(i=0;i<N;i++) {
        for(j=0;j<N;j++) {
            a[i][j]= (rand()%10);
            b[i][j]= (rand()%10);
            c[i][j]= 0;
        }
    }

//    //size_t num_stream = 0.2 * 500000000;
//    size_t num_stream = 0.2 * 5000000;
//    double *a = NULL;
//    double *b = NULL;
//    double *c = NULL;
//
//    size_t cline_size = 64;
//    size_t mem_size = sizeof(double) * num_stream;
//    int err = posix_memalign((void **)&a, cline_size, mem_size);
//    if (!err) {
//        err = posix_memalign((void **)&b, cline_size, mem_size);
//    }
//    if (!err) {
//        err = posix_memalign((void **)&c, cline_size, mem_size);
//    }
//    if (!err) {
//        int i;
//  #pragma omp parallel for
//        for (i = 0; i < num_stream; i++) {
//            a[i] = 0.0;
//            b[i] = 1.0;
//            c[i] = 2.0;
//        }
//    }

    for(proto = 1; proto < 2; proto++) {
        for(iter = 0;iter<total_iter;iter++) {
#ifdef _GEOPM_            
//            geopm_prof_enter(comm_rid);
//            do_send_recv(rank, buff_ptr, &local_buff, buffsize, proto, u_sleep_time);
//            geopm_prof_exit(comm_rid);
#endif

//#ifdef _GEOPM_
//            geopm_prof_enter(comp_rid);
//#endif
            do_compute_p2(comp_rid, a,b,c);
//#ifdef _GEOPM_            
//            geopm_prof_exit(comp_rid);
//#endif
#ifdef _GEOPM_            
            geopm_prof_epoch();
#endif            
            MPI_Barrier(MPI_COMM_WORLD);
        }
    }
//
//    printf("calling Finalize\n");
    MPI_Finalize();
    return 0;
}

