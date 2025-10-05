#!/bin/bash
#SBATCH --job-name=michel_analysis
#SBATCH --output=michel_output_%A_%a.txt
#SBATCH --error=michel_error_%A_%a.txt
#SBATCH --time=24:00:00
#SBATCH --partition=longjobs
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --array=1-1000%100  # Adjust range and concurrency limit

# Load ROOT environment (if needed)
source /path/to/root/bin/thisroot.sh  # Replace with actual path to ROOT setup script

# Define base path
BASE_PATH="/data41/coherent/data/d2o/processedData"

# Log job details
echo "Running on node $(hostname)"
echo "Job ID: $SLURM_JOB_ID, Array Task ID: $SLURM_ARRAY_TASK_ID"
echo "Current working directory: $(pwd)"
echo "Starting job at: $(date)"

# Verify executables
if [ ! -f "./Micheltestwithdate" ]; then
    echo "Error: Micheltestwithdate executable not found in $(pwd)"
    exit 1
fi
if [ ! -f "./get_run_time" ]; then
    echo "Error: get_run_time executable not found in $(pwd)"
    exit 1
fi

# Calibration file
calib_file="${BASE_PATH}/run17951_processed_v5.root"
if [ ! -f "$calib_file" ]; then
    echo "Error: Calibration file $calib_file not found"
    exit 1
fi

# Convert date range to Unix timestamps (assuming CDT, UTC-5)
if [ -n "$START_DATE" ] && [ -n "$END_DATE" ]; then
    start_ts=$(date -d "$START_DATE -5 hours" +%s 2>/dev/null)
    end_ts=$(date -d "$END_DATE -5 hours" +%s 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$start_ts" ] || [ -z "$end_ts" ]; then
        echo "Error: Invalid START_DATE or END_DATE format (use YYYY-MM-DD)"
        exit 1
    fi
    echo "Selecting files with run start time between $START_DATE ($start_ts) and $END_DATE ($end_ts)"
else
    echo "No date range provided; using all available files"
fi

# Get all potential data files
data_files=($(find "$BASE_PATH" -type f -name 'run*_processed_v5.root' ! -name 'run17951_processed_v5.root' 2>/dev/null | sort))

# Check if files exist and task ID is valid
if [ ${#data_files[@]} -eq 0 ]; then
    echo "Error: No data files found in $BASE_PATH"
    exit 1
fi
if [ $SLURM_ARRAY_TASK_ID -gt ${#data_files[@]} ]; then
    echo "Array task ID $SLURM_ARRAY_TASK_ID exceeds number of files (${#data_files[@]})"
    exit 0
fi
file="${data_files[$((SLURM_ARRAY_TASK_ID - 1))]}"

# Check file's run start time if date range is specified
if [ -n "$start_ts" ] && [ -n "$end_ts" ]; then
    run_ts=$("./get_run_time" "$file" | grep "Run Start Time (Unix Timestamp)" | awk '{print $5}')
    if [ -z "$run_ts" ] || ! [[ "$run_ts" =~ ^[0-9]+$ ]]; then
        echo "Warning: Could not retrieve valid timestamp from $file, skipping"
        exit 0
    fi
    if [ "$run_ts" -lt "$start_ts" ] || [ "$run_ts" -ge "$end_ts" ]; then
        echo "File $file timestamp ($run_ts) outside range, skipping"
        exit 0
    fi
fi

# Run analysis
echo "Executing: ./Micheltestwithdate $calib_file $file"
./Micheltestwithdate "$calib_file" "$file"
exit_code=$?
if [ $exit_code -ne 0 ]; then
    echo "Error: Micheltestwithdate failed with exit code $exit_code"
    exit $exit_code
fi

# Verify output directory
output_dir=$(ls -td ./AnalysisOutput_* 2>/dev/null | head -n 1)
if [ -n "$output_dir" ] && [ -d "$output_dir" ]; then
    echo "Output saved in $(pwd)/$output_dir"
    ls -l "$output_dir/"
else
    echo "Warning: No AnalysisOutput_* directory found"
fi

echo "Job finished at: $(date)"
