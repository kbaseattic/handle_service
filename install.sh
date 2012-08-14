#!/bin/sh 

SERVICE_DIR=$1
export GOPATH=/usr/local/gopath

if [ ! -e ${GOPATH} ]; then
    mkdir ${GOPATH}
fi

mkdir -p ${GOPATH}/src/github.com/MG-RAST
cp -r Shock ${GOPATH}/src/github.com/MG-RAST/

go install github.com/MG-RAST/Shock/...
mkdir -p ${SERVICE_DIR} ${SERVICE_DIR}/bin ${SERVICE_DIR}/conf ${SERVICE_DIR}/logs ${SERVICE_DIR}/data ${SERVICE_DIR}/data/temp
cd ${SERVICE_DIR}/data
ln -s . raw
cd -
cp ${GOPATH}/bin/shock-server ${SERVICE_DIR}/bin/
cp -r Shock/site ${SERVICE_DIR}
rm ${SERVICE_DIR}/site/assets/misc/README.md
cp Shock/README.md ${SERVICE_DIR}/site/assets/misc/README.md
cp shock.cfg ${SERVICE_DIR}/conf/shock.cfg