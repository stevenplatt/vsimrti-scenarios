FROM debian:jessie

LABEL \
    description="Docker image containing the VSimRTI adapted ns-3 federate" \
    version="17.0" \
    maintainer="vsimrti@fokus.fraunhofer.de"

WORKDIR /home/vsimrti/bin/fed/omnetpp

COPY ./omnet* ./

RUN \
    apt-get update && \
    apt-get install -y \
    build-essential \
    bison \
    flex \
    libprotobuf-dev \
    libxml2-dev \
    python \
    unzip \
    wget \
    zlib1g-dev && \
    ./omnet_installer.sh --simulator omnetpp-4.6-src.tgz --quiet

VOLUME ["/home/vsimrti/bin/fed/omnetpp/omnetpp-federate/configuration"]

EXPOSE 40001 40002

ENTRYPOINT \
    cp omnetpp-federate/configuration/omnetpp.ini omnetpp-federate/simulations/ && \
    omnetpp-federate/omnetpp-federate -u Cmdenv \
    -f omnetpp-federate/simulations/omnetpp.ini \
    -n 'omnetpp-federate;inet' \
    --vsimrtieventscheduler-host=0.0.0.0 \
    --vsimrtieventscheduler-port=40001 \
    --vsimrticmd-port=40002

