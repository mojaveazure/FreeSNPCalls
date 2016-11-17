#!/bin/bash

#   This script calls SNPs on individual samples
#   or a group of samples using freebayes.
#   Piping among programs borrows directly from:
#   https://github.com/ekg/freebayes/blob/master/examples/pipeline.sh

set -e
set -o pipefail

#    Load modules used in this script
#    The first three are from our local ~/shared/Software rather than MSI
module load bamtools
module load ogap
module load bamleftalign
module load freebayes
module load samtools


#   What are the dependencies for Adapter_Trimming?
declare -a SNP_Calling_Dependencies=(parallel freebayes)

#   Need to add the upstream realignment along these lines!
#   See lines 10 - 15 of https://github.com/ekg/freebayes/blob/master/examples/pipeline.sh
#   Don't forget to honor Beau with some time statements
#   bamtools merge -in /panfs/roc/groups/9/morrellp/shared/Projects/WBDC_inversions/sequence_handling/WBDC_125bp/SAM_Processing/SAMtools/Finished/WBDC_007_finished.bam -in /panfs/roc/groups/9/morrellp/shared/Projects/WBDC_inversions/sequence_handling/WBDC_125bp/SAM_Processing/SAMtools/Finished/WBDC_012_finished.bam -region chr2H:652030648-652032705 | ogap -f /panfs/roc/groups/9/morrellp/shared/References/Reference_Sequences/Barley/Morex/barley_RefSeq_v1.0/150831_barley_pseudomolecules.fasta | samtools view -h - | less

#   A function to do the SNP Calling
#   By adding all the items below we broke the function definition!
function SNP_Calling() {
    local sample="$1"

#    local out="$2"
    local ref="$2"

    #    create directories for output
    mkdir -p "${OUT_DIR}"  


time bamtools merge -region "${REGION}" \
    $(for file in $(cat $sample); do echo " -in "$file; done) \
        #    ogap is a re-aligner, need to define options used
    |    time ogap -z -R 25 -C 20 -Q 20 -S 0 -f "${ref}" \
    |    time bamleftalign -f "${ref}" \
    |    time samtools calmd -EAru - "${ref}" 2>/dev/null \
    |    time freebayes \

    --fasta-reference "${ref}" \
    #    list of BAM files
    --bam-list "${sample}" \
    #    Region is portion of the genome run in an individual analysis
    #    Is taken from the Config file, will be included in VCF file name
    --region "${REGION}" \
    #    pairwise nucleotide diversity (pi/bp), 0.008 for wild barley, for example
    #    value set in config file
    --theta "${THETA}"\
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
    --no-mnps \
    #    ignore complex events, composites of other classes of variants
    --no-complex \
    #    specify VCF output
    --vcf "${OUT_DIR}/${PROJECT}_${REGION}_${YMD}".vcf
}


#   Export the function
export -f SNP_Calling