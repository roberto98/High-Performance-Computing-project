#chmod +x esegui_mpi+omp.bash
#!/bin/bash
echo "########## RESOLUTION 1000" >> mpi_omp_result.txt
mpiicpc -qopenmp progetto_mpi+omp.cpp
for num_procs in 1 2 4 8 16 32 64 128 256 512; do
  for num_threads in 1 2 4 8 16 32 64 128 256; do
        export OMP_NUM_THREADS=$num_threads
        if [[ $num_procs -le 8 ]]
        then
            perhost=1
        else
            perhost=$((num_procs/8))
        fi

        echo "Processes: $num_procs / perhost: $perhost / Threads: $num_threads"
        echo "Processes: $num_procs / perhost: $perhost / Threads: $num_threads">>mpi_omp_result.txt
        echo "" >>mpi_omp_result.txt        

        { time mpirun -hostfile ~/mpi_hosts.txt -perhost $perhost -np $num_procs ./a.out im.data; } 2>&1 | tee -a mpi_omp_result.txt

  done
done


