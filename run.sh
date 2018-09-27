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
NUM_SEEDS=32

python main.py --backend scipy --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS
# 6000/32:  32s / 0.0
# 10000/32: 64s / 0.0
python main.py --backend scipy_fused --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS
# 6000/32:  16s / 0.0
# 10000/32: 38s / 0.0
python main.py --backend auction --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS
# 6000/32:  18s / 0.0
# 10000/32: 81s / 0.0
python main.py --backend auction_fused --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS
# 6000/32:  13s / 0.0
# 10000/32: 39s / 0.0

# !! I think `csr_lap_auction` has fairly large overhead