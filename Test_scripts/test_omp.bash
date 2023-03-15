# chmod +x esegui_omp.bash
#!/bin/bash

icpc -qopenmp progetto_omp.cpp

for n in  1 2 4 8 16 32 64 128 256;
do
    export OMP_NUM_THREADS=$n
    echo $n threads
    echo "$n threads" >> Result.txt
    { time ./a.out img.data; } 2>&1 | tee -a Result.txt
done
