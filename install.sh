#!/bin/sh 

SERVICE_DIR=$1
BIN_DIR=$2
CONF=$3
PERL_LIB="/kb/runtime/lib/perl5/site_perl/5.16.0"

if [ ${CONF} = "prod" ]; then
    SHOCK_SITE=/disk0/site                                                                                                                             
    SHOCK_DATA=/disk0/data
else
    mkdir /mnt/Shock
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
stop shock
mkdir -p ${BIN_DIR} ${SERVICE_DIR} ${SERVICE_DIR} ${SERVICE_DIR}/conf ${SERVICE_DIR}/logs/shock ${SERVICE_DIR}/data/temp
cp ${GOPATH}/bin/shock-server ${BIN_DIR}
rm -r ${SHOCK_SITE}
cp -r Shock/shock-server/site ${SHOCK_SITE}
rm ${SHOCK_SITE}/assets/misc/README.md
cp Shock/README.md ${SHOCK_SITE}/assets/misc/README.md

if [ ${CONF} = "prod" ]; then
    cp conf/shock.cfg ${SERVICE_DIR}/conf/shock.cfg
else
    cp conf/shock-test.cfg ${SERVICE_DIR}/conf/shock.cfg
fi