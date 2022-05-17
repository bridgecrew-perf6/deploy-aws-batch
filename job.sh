#!/bin/bash

set -e

#source /home/${USER}/.bashrc
#source activate hypermapper

sspath=$SUITESPARSE_PATH
#out=experiments

#mkdir -p "$out"

date
echo "Args: $@"
env
echo "jobId: $AWS_BATCH_JOB_ID"

matrix="$1"
echo "$matrix"
./bin/taco-taco_dse --count 0 --matrix_name "$matrix" --op SpMM
./bin/taco-taco_dse --count 1 --matrix_name "$matrix" --op SpMM
./bin/taco-taco_dse --count 2 --matrix_name "$matrix" --op SpMM
./bin/taco-taco_dse --count 3 --matrix_name "$matrix" --op SpMM
./bin/taco-taco_dse --count 4 --matrix_name "$matrix" --op SpMM
./bin/taco-taco_dse --count 5 --matrix_name "$matrix" --op SpMM
./bin/taco-taco_dse --count 6 --matrix_name "$matrix" --op SpMM
./bin/taco-taco_dse --count 7 --matrix_name "$matrix" --op SpMM
./bin/taco-taco_dse --count 8 --matrix_name "$matrix" --op SpMM
./bin/taco-taco_dse --count 9 --matrix_name "$matrix" --op SpMM

./bin/taco-taco_dse --count 0 --matrix_name "$matrix" --method random_sampling --op SpMM
./bin/taco-taco_dse --count 1 --matrix_name "$matrix" --method random_sampling --op SpMM
./bin/taco-taco_dse --count 2 --matrix_name "$matrix" --method random_sampling --op SpMM
./bin/taco-taco_dse --count 3 --matrix_name "$matrix" --method random_sampling --op SpMM
./bin/taco-taco_dse --count 4 --matrix_name "$matrix" --method random_sampling --op SpMM
./bin/taco-taco_dse --count 5 --matrix_name "$matrix" --method random_sampling --op SpMM
./bin/taco-taco_dse --count 6 --matrix_name "$matrix" --method random_sampling --op SpMM
./bin/taco-taco_dse --count 7 --matrix_name "$matrix" --method random_sampling --op SpMM
./bin/taco-taco_dse --count 8 --matrix_name "$matrix" --method random_sampling --op SpMM
./bin/taco-taco_dse --count 9 --matrix_name "$matrix" --method random_sampling --op SpMM

./bin/taco-taco_dse --count 0 --matrix_name "$matrix" --method opentuner --op SpMM
./bin/taco-taco_dse --count 1 --matrix_name "$matrix" --method opentuner --op SpMM
./bin/taco-taco_dse --count 2 --matrix_name "$matrix" --method opentuner --op SpMM
./bin/taco-taco_dse --count 3 --matrix_name "$matrix" --method opentuner --op SpMM
./bin/taco-taco_dse --count 4 --matrix_name "$matrix" --method opentuner --op SpMM
./bin/taco-taco_dse --count 5 --matrix_name "$matrix" --method opentuner --op SpMM
./bin/taco-taco_dse --count 6 --matrix_name "$matrix" --method opentuner --op SpMM
./bin/taco-taco_dse --count 7 --matrix_name "$matrix" --method opentuner --op SpMM
./bin/taco-taco_dse --count 8 --matrix_name "$matrix" --method opentuner --op SpMM
./bin/taco-taco_dse --count 9 --matrix_name "$matrix" --method opentuner --op SpMM

date
