
#!/bin/bash
echo "########## RESOLUTION 1000" >> mpi_one_results_finale.txt
mpiicpc progetto_mpi.cpp
for num_procs in 1 2 4 8 16 32 64 128 256; do

    echo "Processes: $num_procs"
    echo "Processes: $num_procs">>mpi_one_results_finale.txt
    echo "" >>mpi_one_results_finale.txt        

    { time mpirun -np $num_procs ./a.out im.data; } 2>&1 | tee -a mpi_one_results_finale.txt

done

