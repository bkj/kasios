#!/usr/bin/env python

"""
    sgm.py
"""

import warnings
warnings.filterwarnings("ignore", module="matplotlib")
warnings.filterwarnings("ignore", module="scipy.sparse")

import sys
import json
import argparse
import numpy as np
import pandas as pd
from time import time

from scipy import sparse
import itertools
from concurrent.futures import ProcessPoolExecutor

sys.path.append('/home/bjohnson/projects/sgm')
from backends import (
    JVClassicSGM,
    JVSparseSGM,
    JVFusedSGM,
    AuctionClassicSGM,
    AuctionSparseSGM,
    AuctionFusedSGM
)

_backends = {
    "jv_classic"      : JVClassicSGM,
    "jv_sparse"       : JVSparseSGM,
    "jv_fused"        : JVFusedSGM,
    "auction_classic" : AuctionClassicSGM,
    "auction_sparse"  : AuctionSparseSGM,
    "auction_fused"   : AuctionFusedSGM
}

# --
# CLI

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--inpath', type=str, default='./data/calls.npy')
    parser.add_argument('--backend', type=str, default='scipy', choices=_backends.keys())
    parser.add_argument('--num-nodes', type=int, default=1000)
    parser.add_argument('--num-seeds', type=int, default=10)
    parser.add_argument('--seed', type=int, default=123)
    return parser.parse_args()

# --
# Helpers

def make_problem(X, rw, num_nodes, num_seeds, shuffle_A=False, seed=None):
    if seed is not None:
        rng = np.random.RandomState(seed=seed)
    else:
        rng = np.random
    
    node_sel = np.sort(rw[:num_nodes])
    
    A = X[node_sel][:,node_sel].copy()
    
    # This means that seeds are picked randomly
    if shuffle_A:
        perm = rng.permutation(num_nodes)
        A = A[perm][:,perm]
    
    B = A.copy()
    
    perm = np.arange(num_nodes)
    perm[num_seeds:] = rng.permutation(perm[num_seeds:])
    B = B[perm][:,perm]
    
    P = sparse.eye(num_nodes).tocsr()
    P[num_seeds:, num_seeds:] = 0
    P.eliminate_zeros()
    
    return A, B, P

# --
# IO

print('main.py: loading', file=sys.stderr)
args = parse_args()
SGMClass = _backends[args.backend]
np.random.seed(args.seed)

edges = np.load(args.inpath)
X = sparse.csr_matrix((np.ones(edges.shape[0]), (edges[:,0], edges[:,1])))
X = ((X + X.T) > 0).astype('float64')
X.eliminate_zeros()

rw = open('./data/calls.rw').read().splitlines()
rw = np.array([int(xx) for xx in rw])

print('main.py: make_problem', file=sys.stderr)
A, B, P = make_problem(
    X=X, 
    rw=rw, 
    num_nodes=args.num_nodes, 
    num_seeds=args.num_seeds,
    shuffle_A=True,
    seed=args.seed + 111,
)

print('main.py: SGMClass.run()', file=sys.stderr)
start_time = time() 
sgm = SGMClass()
P_out = sgm.run(
    A=A,
    P=P,
    B=B,
    num_iters=20,
    tolerance=1
)
sgm_time = time() - start_time

B_perm = P_out.dot(B).dot(P_out.T)

print(json.dumps({
    "backend"    : str(args.backend),
    "num_nodes"  : int(args.num_nodes),
    "num_seeds"  : int(args.num_seeds),
    "sgm_time"   : float(sgm_time),
    "dist_orig"  : float((A.toarray() != B.toarray()).sum()),
    "dist_perm"  : float((A.toarray() != B_perm.toarray()).sum()),
    # "times" : {
    #     "lap"   : sgm.lap_times,
    #     "grad"  : sgm.grad_times,
    #     "check" : sgm.check_times,
    # }
}))