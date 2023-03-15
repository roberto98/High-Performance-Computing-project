#include <iostream>
#include <fstream>
#include <complex>
#include <mpi.h>

// Ranges of the set
#define MIN_X -2
#define MAX_X 1
#define MIN_Y -1
#define MAX_Y 1

// Image ratio
#define RATIO_X (MAX_X - MIN_X)
#define RATIO_Y (MAX_Y - MIN_Y)

// Image size
#define RESOLUTION 1000
#define WIDTH (RATIO_X * RESOLUTION)
#define HEIGHT (RATIO_Y * RESOLUTION)

#define STEP ((double)RATIO_X / WIDTH)

#define DEGREE 2        // Degree of the polynomial
#define ITERATIONS 1000 // Maximum number of iterations
using namespace std;

int main(int argc, char **argv)
{
    int err, size;
    int root = 0;
    int *image;
    int *buf_recv;
    double start_time, end_time;
    err = MPI_Init(NULL, NULL);

    int rank, world_size;
    err = MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    err = MPI_Comm_size(MPI_COMM_WORLD, &world_size);   
    
    size = HEIGHT * WIDTH;        
         
    if(rank==root){
        //cout<<"L'immagine ha dimensione "<<HEIGHT<<" x "<<WIDTH<<", totale:"<<size<<endl;
        image = new int[size]; //receive buffer to gather result
    }

    int chunk_size = size / world_size;     
    int pos_start = rank * chunk_size;      
    int pos_end = pos_start + chunk_size - 1; 

    int pos_start_last = (world_size - 1) * chunk_size;  
    int chunk_size_last = size - pos_start_last;
                         
    if(rank == world_size - 1 && pos_end < size - 1){  
        pos_end = size - 1;                    
        chunk_size = chunk_size_last;     
    }

    int* buf_send = new int[chunk_size];
    int j=0;

    start_time = MPI_Wtime();

    for (int pos = pos_start; pos <= pos_end; pos++)
    {
        buf_send[j] = 0;
        const int row = pos / WIDTH;
        const int col = pos % WIDTH;
        const complex<double> c(col * STEP + MIN_X, row * STEP + MIN_Y);

        // z = z^2 + c
        complex<double> z(0, 0);
        for (int i = 1; i <= ITERATIONS; i++)
        {
            z = pow(z, 2) + c;
            if (abs(z) >= 2) // If it is convergent
            {
                buf_send[j] = i;
                break;
            }
        }
        j++;
    }
    
    int* counts;
    int* displacements;
    if(rank == root){
        counts = new int[world_size];
        displacements = new int[world_size];

        for(int i = 0; i < world_size - 1; i++){
            counts[i] = chunk_size;
            displacements[i] = i * chunk_size;
        }

        counts[world_size - 1] = chunk_size_last;
        displacements[world_size - 1] = pos_start_last;
    }

    err = MPI_Gatherv(buf_send,
     chunk_size,
     MPI_INT,
     image,  //receive buffer
     counts,
     displacements,
     MPI_INT,
     root,
     MPI_COMM_WORLD);
    
    end_time = MPI_Wtime();

    // Write the result to a file if you are root
    ofstream matrix_out;
    if(rank==root)
    {
        if (argc < 2)
        {
            cout << "Please specify the output file as a parameter." << endl;
            return -1;
        }
        
        matrix_out.open(argv[1], ios::trunc);
        if (!matrix_out.is_open())
        {
            cout << "Unable to open file." << endl;
            return -2;
        }

        for (int row = 0; row < HEIGHT; row++)
        {
            for (int col = 0; col < WIDTH; col++)
            {
                matrix_out << image[row * WIDTH + col];

                if (col < WIDTH - 1)
                    matrix_out << ',';
            }
            if (row < HEIGHT - 1)
                matrix_out << endl;
        }
        matrix_out.close();
        delete[] image; // It's here for coding style, but useless
        printf("Processes: %d\n", world_size);
        printf("Elapsed time (s) = %.2lf\n", end_time - start_time);

    }

    MPI_Finalize();
    return 0;
}