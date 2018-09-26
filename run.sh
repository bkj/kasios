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
# Run SGM

python kasios-sgm.py

python kasios-sgm.py | tee results/kasios.jl
cat results/kasios.jl  | sort -n > tmp && mv tmp results/kasios.jl