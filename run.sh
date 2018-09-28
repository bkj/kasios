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
# Run SGM (w/ various backends)

NUM_NODES=5000
NUM_SEEDS=32

python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend scipy.classic.jv
python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend scipy.sparse.jv
python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend scipy.fused.jv

# python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend auction_classic
python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend scipy.sparse.auction
python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend scipy.fused.auction

python main.py --num-nodes $NUM_NODES --num-seeds $NUM_SEEDS --backend torch.classic.jv