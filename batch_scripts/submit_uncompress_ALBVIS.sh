#!/usr/bin/env bash
#SBATCH --qos=nf
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --job-name=ecosg_uncompress_albvis
#SBATCH --mem-per-cpu=16000
#SBATCH -t 12:00:00
set -e

dataset='ALBVIS_SNOWFREE'
exe=uncompress_file_multitype.x
outdir=$SCRATCH/proj_landuse/climate/ECOCLIMAP-SG_uncompress_multitype/$dataset

mkdir -p $outdir
for ff in /hpcperm/hlam/data/climate/ECOCLIMAP-SG/$dataset/*.dir; do
  echo "Working on $ff"
  time $exe $ff $outdir/$(basename $ff)
done
