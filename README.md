vim Micheltest.slurm
g++ -O3 -march=native -std=c++17 withMichelFitAndStoreResultsinRootfileMODULE2.cpp \$(root-config --cflags) -o Micheltest \ $(root-config --libs | sed 's/-lROOTNTupleUtil//g') \
   -pthread
   Submit with sbatch Micheltest.slurm
Monitor with squeue and tail -f michel_output.txt
