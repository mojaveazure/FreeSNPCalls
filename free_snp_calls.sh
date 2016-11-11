#!/bin/bash

set -o pipefail

function Usage() {
    echo -e "\
Usage:  `basename $0` <Caller> Config \n\
Where:  <Caller> is one of: \n\
            1 | SNP_Calling \n\
            More to come later... \n\
And:    Config is the full file path to the configuration file
" >&2
    exit 1
}

export -f Usage

#   Where is 'FreeSNPCalls' located?
FREE_SNP_CALLS=`pwd -P`

#   Where do we output the standard error and standard output files?
ERROR="${FREE_SNP_CALLS}"/ErrorFiles
mkdir -p "${ERROR}"

#   If we have less than two arguments
if [[ "$#" -lt 1 ]]; then Usage; fi # Display the usage message and exit

CALLER="$1" # What routine are we running?
CONFIG="$2" # Where is our config file?

#   If the specified config exists
if [[ -f "${CONFIG}" ]]
then
    source "${CONFIG}" # Source it, providing parameters and software
    bash "${CONFIG}" > /dev/null 2> /dev/null # Load any modules
    source "${FREE_SNP_CALLS}"/HelperScripts/utils.sh # And the utils script
else # If it doesn't
    echo "Please specify a valid config file." >&2 # Print error message
    exit 1 # Exit with non-zero exit status
fi

#   Run FreeSNPCalls
case "${CALLER}" in
    1|SNP_Calling)
        echo "$(basename $0): Calling SNPs using freebayes..." >&2
        source "${FREE_SNP_CALLS}"/Callers/SNP_Calling.sh
        checkDependencies SNP_Calling_Dependencies[@] # Check to see if dependencies are installed
        if [[ "$?" -ne 0 ]]; then exit 1; fi # If we're missing a dependency, exit out with error
        checkSamples "${RAW_SAMPLES}" # Check to see if samples and sample list exists
        if [[ "$?" -ne 0 ]]; then exit 1; fi # If we're missing a sample or our list, exit out with error
        #   Run SNP_Calling
        declare -a SAMPLE_PATHS=($(cat ${SNP_CALLING_SAMPLE_LIST}))
        ARRAY_LIMIT=$[${#SAMPLE_PATHS[@]} - 1]
        echo "Max array index is ${ARRAY_LIMIT}...">&2
        echo -e "#!/bin/bash\n\
        #PBS -l mem=16gb,nodes=1:ppn=8,walltime=48:00:00\n\
        #PBS -e ${ERROR}\n\
        #PBS -o ${ERROR}\n\
        #PBS -m abe\n\
        #PBS -M ${EMAIL}\n\
        set -e\n\
        set -o pipefail\n\
        source /panfs/roc/groups/9/morrellp/wyant008/soy_downsampling/freebayes_SNPs/snp_function.sh\n\
        declare -a SAMPLE_PATHS=($(cat ${SAMPLE_LIST}))\n\
        SNP_calling \${SAMPLE_PATHS[\${PBS_ARRAYID}]} ${OUT_DIR} ${REFERENCE}" > ${PROJECT}_SNP_Calling
        qsub -t 0-"${ARRAY_LIMIT}" "${PROJECT}"_SNP_Calling
        ;;
    * )
        Usage
        ;;
esac
