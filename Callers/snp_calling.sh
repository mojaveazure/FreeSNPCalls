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
}

#   Export the function
export -f SNP_Calling