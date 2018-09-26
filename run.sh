#!/bin/bash

# run.sh

# --
# get data

PROJECT_ROOT=$(pwd)
mkdir -p data/orig
cd data/orig
wget http://vacommunity.org/tiki-download_file.php?fileId=577
mv tiki-download_file.php?fileId=577 tiki.zip
unzip tiki.zip && rm tiki.zip
cd $PROJECT_ROOT

# --
# sample

mkdir -p data

python rw-sample.py --inpath data/orig/calls.csv > data/calls.rw

# --
# run SGM

python kasios-sgm.py | tee kasios.jl
cat kasios.jl  | sort -n > tmp && mv tmp kasios.jl