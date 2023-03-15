/*
Per compilare:
nvcc progetto_cuda.cu
time ./a.out img.data
*/

#include <iostream>
#include <fstream>
#include <complex>
#include <cmath>

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

/*
// PSEUDOCODICE PRESO DA WIKIPEDIA
__global__ void mandelbrotKernel(int *image, double step, double minX, double minY, int width, int height, int iterations)
{
    int pos = blockIdx.x * blockDim.x + threadIdx.x;

    if (pos < width * height)
    {       
        image[pos] = 0;

        const int row = pos / width;
        const int col = pos % width;

        double x0 = col * step + minX; 
        double y0 = row * step + minY;

        double x = 0.0;
        double y = 0.0;
        int iteration = 1;
        while (x * x + y * y <= 4 && iteration < iterations)
        {
            double xtemp = x * x - y * y + x0;
            y = 2 * x * y + y0;
            x = xtemp;
            iteration++;
        }

        if(iteration != ITERATIONS)
            image[pos] = iteration;
    }
}
*/

__global__ void mandelbrotKernel(int *image, double step, double minX, double minY, int width, int height, int iterations)
{
    int pos = blockIdx.x * blockDim.x + threadIdx.x;

    if (pos < width * height)
    {       
        image[pos] = 0;
        const int row = pos / width;
        const int col = pos % width;
        double c_real = col * STEP + MIN_X;
        double c_imm = row * STEP + MIN_Y;
        double z_real = 0;
        double z_imm = 0;
        double z_square_real;
        double z_square_imm;

        for(int i=1; i<=ITERATIONS; i++)
        {
            z_square_real = z_real*z_real - z_imm*z_imm;
            z_square_imm = 2 * z_real * z_imm;
            z_real = z_square_real + c_real;
            z_imm = z_square_imm + c_imm;
            if( z_real*z_real + z_imm*z_imm >= 4){
                image[pos] = i;
                break;
            }
        }
    }
}


int main(int argc, char **argv)
{
    int *const image = new int[HEIGHT * WIDTH];
    printf("L'immagine ha dimensione %d\n", HEIGHT * WIDTH);

    // ----------------------- ALLOCATION --------------------- //
    int *d_image;
    cudaMalloc(&d_image, sizeof(int) * WIDTH * HEIGHT); // Allocate memory for the result on the device
    //cudaMemcpy(d_image, image, sizeof(int) * WIDTH * HEIGHT, cudaMemcpyHostToDevice); // Copy data from host to device

    // ---------------------- CREATE TIMER ------------------ //
    cudaEvent_t start_time, stop_time;
    cudaEventCreate(&start_time);
    cudaEventCreate(&stop_time);

    // --------------------- THREADS & BLOCKS ----------------- //
    dim3 threadsPerBlock(1024);
    dim3 numBlocks((WIDTH * HEIGHT + threadsPerBlock.x-1) / threadsPerBlock.x); 

    printf("threadsPerBlock.x: %u \n", threadsPerBlock.x);
    printf("numBlocks.x: %u \n", numBlocks.x);

    cudaEventRecord(start_time);
    mandelbrotKernel<<<numBlocks, threadsPerBlock>>>(d_image, STEP, MIN_X, MIN_Y, WIDTH, HEIGHT, ITERATIONS);
    cudaDeviceSynchronize(); // Wait for the kernel to finish
    cudaMemcpy(image, d_image, sizeof(int) * WIDTH * HEIGHT, cudaMemcpyDeviceToHost); // Copy data from device to the host
    
    // ---------------------- STOP TIMER ------------------ //
    cudaEventRecord(stop_time);
    cudaEventSynchronize(stop_time);

    float elapsed_ref = 0;
    cudaEventElapsedTime(&elapsed_ref, start_time, stop_time);
    printf("Time elapsed: %f milliseconds\n", elapsed_ref) ;

    // ---------------------- FRATTALE ------------------ //
    ofstream matrix_out; // Write the result to a file
 
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

    delete[] image;
    cudaFree(d_image);
    return 0;
}