#!/bin/bash -x
# Fetch the perl and python client libraries based on git repo URL
# 
# First param is the destination directory
# All subsequent params are treated as git URLs that need to checked out and
# everything under /lib directory merged into the target directory
#
# sychan
# 9/1/2017

# A suitable temp area for checking out repos
TEMP=/tmp

if [ $# -lt 2 ]; then
   echo "Must supply a target directory and 1 or more URLS for git checkout"
   exit 0
fi

# If the directory doesn't exist try creating it
if [ ! -d $1 ]; then
    mkdir -p $1
fi

if [ ! -w $1 ]; then
    echo "Directory $0 cannot be created or else is not writable"
    exit 0
fi

DEST=`cd $1; pwd`

# Create a temp directory for checking out repos
SRCDIR=$TEMP/repo$$
mkdir $SRCDIR

if [ ! -w $SRCDIR ] ; then
    echo "Could not create git checkout area $SRCDIR"
fi

# Perform a git clone for all the rest of the args
pushd $SRCDIR
shift
for repo in "$@"; do
    git clone $repo
    REPNAME=`basename $repo`
    DIR=${REPNAME%.*}
    cd $DIR/lib
    cp -r . $DEST
    cd ..
    rm -rf $DIR
done

popd
# Cleanup
rm -rf $SRCDIR
