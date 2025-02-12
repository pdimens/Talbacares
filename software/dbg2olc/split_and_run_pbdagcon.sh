#! /usr/bin/env bash

#USAGE: 
# split_and_run_pbdagcon.sh [BACKBONE_FASTA] [CONSENSUS_FASTA] [READS_FASTA] [OUTPUT_DIR][split_reads_by_backbone_version 1,2,3 - 3 by default] \n

backbone_fasta=$1
consensus_fasta=$2
reads_fasta=$3
split_dir=$4
THREADS=$5

mkdir -p $split_dir

SPLITREADS=$(realpath ../software/dbg2olc/split_reads_by_backbone_openclose.py)
python2 $SPLITREADS -b ${backbone_fasta} -o ${split_dir} -r ${reads_fasta} -c ${consensus_fasta} 

for file in $(find ${split_dir} -name "*.reads.fasta"); do
    chunk=`basename $file .reads.fasta`
    blasr --nproc 64 ${split_dir}/${chunk}.reads.fasta ${split_dir}/${chunk}.fasta --bestn 1 -m 5 --minMatch 19 --out ${split_dir}/${chunk}.mapped.m5 &> /dev/null
    pbdagcon ${split_dir}/${chunk}.mapped.m5 -j 1 -c 1 -m 200 > ${split_dir}/${chunk}.consensus.fasta
    rm ${split_dir}/${chunk}.mapped.m5 ${split_dir}/${chunk}.reads.fasta
    cat ${split_dir}/${chunk}.consensus.fasta >> ${split_dir}/final_assembly.fasta && rm ${split_dir}/${chunk}.consensus.fasta
done