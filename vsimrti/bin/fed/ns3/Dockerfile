FROM debian:jessie

LABEL \
    description="Docker image containing the VSimRTI adapted OMNET++ federate" \
    version="17.0" \
    maintainer="vsimrti@fokus.fraunhofer.de"

WORKDIR /home/vsimrti/bin/fed/ns3

COPY ./ns* ./

RUN \
  apt-get update && \
  apt-get install -y \
  build-essential \
  gcc \
  g++ \
  lbzip2 \
  libprotobuf-dev \
  libsqlite3-dev \
  libxml2-dev \
  patch \
  python \
  unzip \
  rsync \
  wget && \
  ./ns3_installer.sh --quiet

VOLUME ["/home/vsimrti/bin/fed/ns3/scratch"]

EXPOSE 40001 40002

ENTRYPOINT \
    cp scratch/* ns-allinone/ns/scratch && \
    ./run.sh 40001 40002


