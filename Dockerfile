FROM artefact.skao.int/ska-tango-images-pytango-builder:9.3.10 as buildenv
FROM artefact.skao.int/ska-tango-images-pytango-runtime:9.3.10

# create ipython profile to so that itango doesn't fail if ipython hasn't run yet
RUN ipython profile create
#RUN curl https://raw.githubusercontent.com/p4lang/p4app-switchML/main/dev_root/controller/ports.py --output /app/src/ska_low_cbf_net/ports.py
ENV SDE=/sde
ENV SDE_INSTALL=/sde/install
ENV LD_LIBRARY_PATH=$SDE_INSTALL/lib:$LD_LIBRARY_PATH
ENV PATH=$SDE_INSTALL/bin:$PATH
RUN pip install -e .
