#! /usr/bin/env bash

outdir=${SDE_INSTALL}/low_cbf.tofino

# Don't necessarily need P4 runtime files. If you do, you may want to consider
# --p4runtime-force-std-externs (forces use of standard extern messages,
# although i'm not altogether sure what this means). Target and arch are
# optional if compiling for tofino/tna.
bf-p4c --target=tofino --arch=tna \
    --p4runtime-files=${outdir}/low_cbf.p4info.pb.txt \
    -I. low_cbf.p4 -o ${outdir}

# Enables use of shorthand `-p` in tofino model and switchd launches
cp ${SDE_INSTALL}/low_cbf.tofino/low_cbf.conf \
    ${SDE_INSTALL}/share/p4/targets/tofino/
