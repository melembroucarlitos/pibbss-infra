#!/bin/bash

ENVFILE=/etc/environment.env

###########
## FUNCS ##
###########

extract_pod_id() {
    local env_string
    env_string=$(cat $ENVFILE | grep RUNPOD_POD_HOSTNAME=)

    if [ -z "$env_string" ]; then
        echo "RUNPOD_POD_HOSTNAME is not set" >&2
        return 1
    fi
    
    local extracted
    
    if [[ $env_string =~ RUNPOD_POD_HOSTNAME=([a-zA-Z0-9]+)- ]]; then
        extracted="${BASH_REMATCH[1]}"
    else
        echo "No match found." >&2
        return 1
    fi
    
    # local pod_ids
    # pod_ids=$(runpodctl get pods | awk 'NR > 1 {print $1}')
    
    # if echo "$pod_ids" | grep -qw "$extracted"; then
    #     echo "$extracted"
    # else
    #     echo "POD_ID was not found in the list of POD IDs" >&2
    #     return 1
    # fi
}

############
## CONSTS ##
############

readonly INITIAL_WAIT_TIME=300 # 5 minutes 60 * 5
readonly LOOP_FREQUENCY=0.1
readonly UPPER_BOUND_TIME_SINCE_LAST_GPU_ACTIVITY=120 # 2 minutes 60 * 2
readonly POD_ID=$(extract_pod_id)

# Check if POD_ID was set successfully
if [ $? -ne 0 ]; then
    echo -e "Failed to extract POD_ID\n"
    exit 1
fi


##########
## MAIN ##
##########

sleep $INITIAL_WAIT_TIME

time_since_last_gpu_activity=0
while true; do
    if awk "BEGIN { if ($time_since_last_gpu_activity > $UPPER_BOUND_TIME_SINCE_LAST_GPU_ACTIVITY) exit 0; else exit 1 }"; then
        echo -e "Idle Pod Detected - Automated pod stoppage will begin in 10s\n"
        sleep 5
        runpodctl stop pod $POD_ID
        exit 0
    fi

    # Check if gpu is currently being utilized
    current_gpu_utilization=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    if awk "BEGIN { if ($current_gpu_utilization > 0) exit 0; else exit 1}"; then
        time_since_last_gpu_activity=0
    else
        time_since_last_gpu_activity=$(awk "BEGIN {print $time_since_last_gpu_activity + $LOOP_FREQUENCY}")
    fi

    sleep $LOOP_FREQUENCY
done

