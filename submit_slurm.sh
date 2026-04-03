#!/bin/bash
#SBATCH -J G4d2o_7M
#SBATCH -p shortjobs
#SBATCH -t 12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=32G
#SBATCH --output=G4d2o_%j.out
#SBATCH --error=G4d2o_%j.err

cd /home/manoja450/G4WithoutLeadSheilding/G4d2o

export LD_LIBRARY_PATH=""
export ROOTSYS="/usr"
export LD_LIBRARY_PATH="/usr/lib64:${LD_LIBRARY_PATH}"
export G4INSTALL="/home/manoja450/geant4-install"
source ${G4INSTALL}/bin/geant4.sh
export LD_LIBRARY_PATH="${G4INSTALL}/lib64:${LD_LIBRARY_PATH}"
export CRYHOME="/home/manoja450/cry_v1.7"
export LD_LIBRARY_PATH="${CRYHOME}/lib:${LD_LIBRARY_PATH}"

export G4NEUTRONHPDATA="/home/manoja450/geant4-data/G4NDL4.7"
export G4LEDATA="/home/manoja450/geant4-data/G4EMLOW8.2"
export G4LEVELGAMMADATA="/home/manoja450/geant4-data/PhotonEvaporation5.7"
export G4RADIOACTIVEDATA="/home/manoja450/geant4-data/RadioactiveDecay5.6"
export G4PARTICLEXSDATA="/home/manoja450/geant4-data/G4PARTICLEXS4.0"
export G4PIIDATA="/home/manoja450/geant4-data/G4PII1.3"
export G4REALSURFACEDATA="/home/manoja450/geant4-data/RealSurface2.2"
export G4SAIDXSDATA="/home/manoja450/geant4-data/G4SAIDDATA2.0"
export G4ABLADATA="/home/manoja450/geant4-data/G4ABLA3.3"
export G4INCLDATA="/home/manoja450/geant4-data/G4INCL1.2"

echo "Starting simulation at $(date)"
echo "beamOn.dat configuration:"
head -5 beamOn.dat

./build/G4d2o << EOF
/run/beamOn
exit
EOF

echo "Simulation finished at $(date)"
grep "Number of events processed" output.log 2>/dev/null || echo "Check output above"
ls -lh data/Sim_D2ODetector001.root 2>/dev/null || find . -name "*.root"
