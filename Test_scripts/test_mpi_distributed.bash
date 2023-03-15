#chmod +x esegui_mpi_distr.bash
#!/bin/bash
echo "########## RESOLUTION 1000" >> mpi_hosts_results_finale.txt
mpiicpc progetto_mpi.cpp
for num_procs in 1 2 4 8 16 32 64 128 256; do
    if [[ $num_procs -le 8 ]]
    then
        perhost=1
    else
        perhost=$((num_procs/8))
    fi

    echo "Processes: $num_procs / perhost: $perhost"
    echo "Processes: $num_procs / perhost: $perhost">>mpi_hosts_results_finale.txt
    echo "" >>mpi_hosts_results_finale.txt        

    { time mpirun -hostfile ~/mpi_hosts.txt -perhost $perhost -np $num_procs ./a.out im.data; } 2>&1 | tee -a mpi_hosts_results_finale.txt

done

