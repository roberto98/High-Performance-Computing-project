#include <stdio.h>
#include <time.h>
#include <mpi.h>
#ifdef _OMP
    #include <omp.h>
#endif
 
#define PI25DT 3.141592653589793238462643
#define INTERVALS 100000000000

int main(int argc, char **argv)
{
    long int i, intervals = INTERVALS;
    double x, dx, f, sum, pi;

    int rank, size;
    MPI_Init(&argc, &argv); // Initialize MPI
    MPI_Comm_rank(MPI_COMM_WORLD, &rank); // Rank of the processes
    MPI_Comm_size(MPI_COMM_WORLD, &size); // Number of processes

    //printf( "I am %d with processes: %d\n", rank, size );

    double start_time, end_time;
    start_time = MPI_Wtime();

    sum = 0.0;
    dx = 1.0 / (double) intervals; // Width of the intervals to compute the sum

    // Divide the work among the processes
    long int intervals_per_process = intervals / size;
    long int start = rank * intervals_per_process + 1;
    long int end = start + intervals_per_process - 1;
    
    #ifdef _OMP
        #pragma omp parallel for private(x, f) reduction(+:sum)
    #endif
    // Perform only the iterations assigned to the current process
    for (i = start; i <= end; i++) {
        x = dx * ((double) (i - 0.5)); // Center of each rectangle
        f = 4.0 / (1.0 + x*x); // Area of each rectangle
        sum = sum + f;  
    }

    // Sum the partial results from all processes
    double global_sum;
    MPI_Reduce(&sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);


    // The process with rank 0 calculate the final result
    if (rank == 0) {
        pi = dx * global_sum;

        end_time = MPI_Wtime();
        double elapsed_time = end_time - start_time;

        printf("Computed PI %.24f\n", pi);
        printf("The true PI %.24f\n", PI25DT);
        printf("Elapsed time (s) = %.2lf\n\n", elapsed_time);
    }

    MPI_Finalize();
    return 0;
}