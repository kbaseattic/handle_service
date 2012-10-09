#!/bin/sh 

SERVICE_DIR=$1
BIN_DIR=$2
PERL_LIB="/kb/runtime/lib/perl5/site_perl/5.16.0"
SHOCK_SITE=/disk0/site                                                                                                                             
SHOCK_DATA=/disk0/data

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

go get github.com/MG-RAST/Shock/...
mkdir -p ${BIN_DIR} ${SERVICE_DIR} ${SERVICE_DIR} ${SERVICE_DIR}/conf ${SERVICE_DIR}/logs/shock ${SERVICE_DIR}/data/temp
cp ${GOPATH}/bin/shock-server ${BIN_DIR}
rm -r ${SHOCK_SITE}
cp -r Shock/site ${SHOCK_SITE}
rm ${SHOCK_SITE}/assets/misc/README.md
cp Shock/README.md ${SHOCK_SITE}/assets/misc/README.md
cp conf/shock.cfg ${SERVICE_DIR}/conf/shock.cfg

# install uploader
#echo "installing uploader"

# service nginx stop
# apt-get update
# apt-get install apache2-mpm-itk
# echo "AddHandler cgi-script .cgi" >> /etc/apache2/mods-enabled/mime.conf 
# rm /etc/apache2/sites-enabled/000-default

#cp -r uploader ${SERVICE_DIR}
#./setup.pl -input conf/uploader.cfg -output ${SERVICE_DIR}/uploader/UploaderConfig.pm
#cp conf/uploader.apache.conf /etc/apache2/sites-enabled

#cd Bio-KBase-Auth
#/kb/runtime/bin/perl Build.PL 
#/kb/runtime/bin/perl Build installdeps --install_path arch=${PERL_LIB}
#/kb/runtime/bin/perl Build install --install_path arch=${PERL_LIB}
#cd -

# services
cp services/* ${SERVICE_DIR}