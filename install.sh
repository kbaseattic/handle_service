#!/bin/sh 

SERVICE_DIR=$1
TARGET=$2
CONF=$3
BIN_DIR=$TARGET/bin
LIB_DIR=$TARGET/lib
PERL_LIB="/kb/runtime/lib/perl5/site_perl/5.16.0"

if [ ${CONF} = "prod" ]; then
    stop shock
    SHOCK_SITE=/disk0/site                                                                                                                             
    SHOCK_DATA=/disk0/data
else
    mkdir -p /mnt/Shock/data
    mkdir -p /mnt/Shock/logs
    SHOCK_SITE=/mnt/Shock/site                                                                                                                             
    SHOCK_DATA=/mnt/Shock/data
fi

# build shock
echo "installing shock"
export GOPATH=/usr/local/gopath

if [ ! -e ${GOPATH} ]; then
    mkdir ${GOPATH}
else
    rm -rf ${GOPATH}/*
fi

mkdir -p ${GOPATH}/src/github.com/MG-RAST
cp -r Shock ${GOPATH}/src/github.com/MG-RAST/

go get -v github.com/MG-RAST/Shock/...
mkdir -p ${BIN_DIR} ${SERVICE_DIR} ${SERVICE_DIR} ${SERVICE_DIR}/conf ${SERVICE_DIR}/logs/shock ${SERVICE_DIR}/data/temp
cp -v ${GOPATH}/bin/shock-server ${BIN_DIR}
cp -v ${GOPATH}/bin/shock-client ${BIN_DIR}
rm -r ${SHOCK_SITE}
cp -v -r Shock/shock-server/site ${SHOCK_SITE}
rm ${SHOCK_SITE}/assets/misc/README.md
cp -v Shock/README.md ${SHOCK_SITE}/assets/misc/README.md

if [ ${CONF} = "prod" ]; then
    cp -v conf/shock.cfg ${SERVICE_DIR}/conf/shock.cfg
    start shock
else
    cp -v conf/shock-test.cfg ${SERVICE_DIR}/conf/shock.cfg
    cp -v services/shock.conf /etc/init/
fi
