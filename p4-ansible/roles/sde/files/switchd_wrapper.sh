#!/bin/bash

KERNEL_MODULE="bf_kdrv"
LOG_DIR="/var/log/ska"
LOG_FILE="${LOG_DIR}/switchd_wrapper.log"

MODULE_INSTALLED=$(lsmod |grep ${KERNEL_MODULE})
if [ -z "${MODULE_INSTALLED}" ]
then
    >&2 echo "$(date +%Y-%m-%d_%H:%M:%S) kernel module ${KERNEL_MODULE} not loaded" >> tee ${LOG_FILE}
    # wa are going to be restarted - give it a short break
    sleep 10
    exit -1
fi
/usr/local/bin/run_switchd_background.sh -p tna_codif --server-listen-local-only --background > ${LOG_FILE} 2>&1 &
