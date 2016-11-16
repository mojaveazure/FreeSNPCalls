#!/bin/bash

#   This script calls SNPs on individual samples
#   or a group of samples using freebayes.

set -e
set -o pipefail

#   What are the dependencies for Adapter_Trimming?
declare -a SNP_Calling_Dependencies=(parallel freebayes)

# A function to do the SNP Calling
function SNP_Calling() {
    local sample="$1"
    local out="$2"
    local ref="$3"
    local samplename=$(basename ${sample} .bam)
    freebayes -f "${ref}" "${sample}" > "${out}"/"${samplename}".vcf
    #    pairwise nucleotide diversity (pi/bp), 0.008 for wild barley, for example
    #    value set in config file
    --theta $theta\
    #     ploidy of either 1 or 2 for highly inbred samples of barley 
    --ploidy 1\
    #     includes reference allele in analysis as if another sample
    --use-reference-allele\
    #     exlude alignment with mapping quality < Q, phred-scaled mapping quality score
    --min-mapping-quality 30\
    #     exclude allele from analysis if phred quality < Q for individual nucleotide sites
    --min-base-quality 30\
    #     minimum number of observations of alternate allele per individual
    --min-alternate-count 3\
    #     minimum observations of alternate allele in total population
    #--min-alternate-total 3\
    #     fraction of alternate reads in an individual
    --min-alternate-fraction 0.3\
    #    don't assume Hardy Weinberg genotype frequencies; use for inbred samples!/qq
    --hwe-priors-off \
    #    next two lines break adjacent variants (SNPs) into individual SNPs
    -- no-mnps \
    #    ignore complex events, composites of other classes of variants
    --no-complex \
    #    specify VCF output
    --vcf "${out}"/"${samplename}".vcf
}

#   Export the function
export -f SNP_Calling