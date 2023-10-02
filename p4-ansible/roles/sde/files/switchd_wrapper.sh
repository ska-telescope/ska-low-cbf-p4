#!/bin/bash

MODULE_PATH=${SDE_PATH}${SDE_VERSION}/${INSTALL_SUFFIX}/lib/modules
KERNEL_MODULE_KDRV="bf_kdrv"
KERNEL_MODULE_FPGA="bf_fpga"
LOG_DIR="/var/log/ska"
LOG_FILE="${LOG_DIR}/switchd_wrapper.log"

sudo insmod ${MODULE_PATH}/${KERNEL_MODULE_FPGA}.ko intr_mode="none"
sudo insmod ${MODULE_PATH}/${KERNEL_MODULE_KDRV}.ko intr_mode="msi"

# ensure the kernel modules are loaded
for MOD in ${KERNEL_MODULE_KDRV} ${KERNEL_MODULE_FPGA}
do
    MODULE_INSTALLED=$(lsmod |grep ${MOD})
    if [ -z "${MODULE_INSTALLED}" ]
    then
        >&2 echo "$(date +%Y-%m-%d_%H:%M:%S) kernel module ${MOD} not loaded" >> tee ${LOG_FILE}
        # wa are going to be restarted - give it a short break
        sleep 10
        exit -1
    fi

done

/usr/local/bin/run_switchd_background.sh -p tna_codif --server-listen-local-only --background > ${LOG_FILE} 2>&1 &
