#!/bin/sh

PACKAGE_DIR='handle_service'
rm -rf $PACKAGE_DIR

# check that the arg is a valid directory from which we'll try
# to get the KBase auth client libs.
# Check for proper number of command line args.

EXPECTED_ARGS=2
E_BADARGS=65

if [ $# -ne $EXPECTED_ARGS ]
then
	echo "\nUsage: `basename $0` /path/to/auth/lib /path/to/kbapi_common/lib"
  	echo "\nneed to pass in location of auth libs and exception lib, for example:"
        echo "prepare.sh /kb/dev_container/modules/auth/lib /kb/dev_container/modules/kbapi_common/lib/\n"
  	exit $E_BADARGS
fi


AUTH_LIB=$1
KBAPI_COMMON_LIB=$2

if [ -d $AUTH_LIB ] 
then
	echo "\nusing $AUTH_LIB for source of auth libs\n";
else
	echo "\n$1 doesn't appear to be a valid directory\n"
	exit
fi
if [ -d $KBAI_COMMON_LIB ] 
then
        echo "\nusing $KBAPI_COMMON_LIB for source of kb common libs\n";
else
        echo "\n$2 doesn't appear to be a valid directory\n"
        exit
fi

# make a directory in which to package everything
mkdir -p $PACKAGE_DIR/lib

# copy the auth libraries into the package directory
rsync -arv --exclude '.git' $AUTH_LIB/. $PACKAGE_DIR/lib/.
rsync -arv --exclude '.git' $KBAPI_COMMON_LIB/. $PACKAGE_DIR/lib/.

# copy the files into the package directory.
rsync --exclude COMMANDS --exclude hsi.sql --exclude handle_service.spec --exclude '.git' --exclude 'dist' --exclude 'Makefile' --exclude 'deploy.cfg' --exclude 'DEPENDENCIES' -arv ../. $PACKAGE_DIR/.

# insert #!/usr/bin/env perl at the top of each script
for s in $PACKAGE_DIR/scripts/*.pl
do
	# filename="${s%.*}"
	echo '#!/usr/bin/env perl' | cat - $s > temp && mv temp $s
	# cp $s $filename
done

# put the build script in place
cp Makefile.PL $PACKAGE_DIR/
cp INSTALL.txt $PACKAGE_DIR/
cp TUTORIAL.txt $PACKAGE_DIR/
cp -r t $PACKAGE_DIR/


cd $PACKAGE_DIR
perl ./Makefile.PL
make manifest
make realclean
# rm -f MANIFEST.SKIP.bak
cd ..

tar -cvf $PACKAGE_DIR.tar $PACKAGE_DIR
gzip $PACKAGE_DIR.tar
# rm -rf $PACKAGE_DIR
