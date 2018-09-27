#!/bin/bash

# run.sh

# --
# Get data

PROJECT_ROOT=$(pwd)
mkdir -p data/orig
cd data/orig
wget http://vacommunity.org/tiki-download_file.php?fileId=577
mv tiki-download_file.php?fileId=577 tiki.zip
unzip tiki.zip && rm tiki.zip
cd $PROJECT_ROOT

# --
# Random walk sampling

mkdir -p data

python rw-sample.py --inpath data/orig/calls.csv > data/calls.rw

# --
# Run SGM (grid)

python kasios-sgm.py

python kasios-sgm.py | tee results/kasios.jl
cat results/kasios.jl  | sort -n > tmp && mv tmp results/kasios.jl

# --
# Run SGM (backends)

NUM_NODES=15000
NUM_SEEDS=128

python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend jv_classic
# python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend jv_sparse
# python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend jv_fused

# python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend auction_classic
# python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend auction_sparse
python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend auction_fused

