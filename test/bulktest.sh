#!/bin/bash

## These values must be configured for a running instance of Shock
#####################################################################

SHOCK_IP=140.221.92.74
SHOCK_USER=mike
SHOCK_PASS=1234


## These can be changed to better control file and directory names
#####################################################################

UPLOAD_PREFIX=shocktest.upload
DOWNLOAD_PREFIX=shocktest.download
TESTFILE=shockfile


## Help and Usage
#####################################################################

if [[ $# -eq 0 ]]
then
  echo "bulktest.sh [GENERATE | UPLOAD | QUERY | DOWNLOAD]"
  echo ""
  echo "1. bulktest.sh GENERATE <numfiles>"
  echo "   Generates <numfiles> short files in the directory $UPLOAD_PREFIX.DATE"
  echo "   and uploads them to shock. Includes attributes json file with date field set"
  echo "   Example: bulktest.sh GENERATE 100"
  echo ""
  echo "2. bulktest.sh UPLOAD <directory>"
  echo "   Uploads all the files in directory to shock"
  echo "   Generates attributes json file with the date field set"
  echo "   Example: bulktest.sh UPLOAD uploaddir" 
  echo ""
  echo "3. bulktest.sh QUERY <querystring>"
  echo "   Query the shock server with the specified query string"
  echo "   Example: bulktest.sh QUERY date=Wed_Aug_15_12:24:31_CDT_2012"
  echo ""
  echo "4. bulktest.sh DOWNLOAD <querystring>"
  echo "   Downloads all the files with the specified query string to the directory"
  echo "   $DOWNLOAD_PREFIX.QUERYSTRING. Assumes the filename file is set."
  echo "   Example: bulktest.sh DOWNLOAD date=Wed_Aug_15_12:24:31_CDT_2012"
  echo ""
  
  exit 0
fi

MODE=$1
shift

DATE=`date | tr ' ' '_'`

set -e

if [[ $MODE == "GENERATE" ]]
then
  
  ## GENERATE
  #############################################################################
  
  if [[ $# -eq 0 ]]
  then
    echo "Usage: bulktest.sh GENERATE <numfiles>"
    exit 1
  fi
 
  TESTS=$1
 
  UPDIR=$UPLOAD_PREFIX.$DATE

  rm -rf $UPDIR
  mkdir $UPDIR

  NUMUP=0

  for (( i = 1; i <= $TESTS; i++))
  do
    echo ""
    echo "Preparing test $i"

    echo "{"                                     >  $UPDIR/$TESTFILE.$i.json
    echo " \"filename\": \"$TESTFILE.$i.txt\","  >> $UPDIR/$TESTFILE.$i.json
    echo " \"date\":     \"$DATE\""              >> $UPDIR/$TESTFILE.$i.json
    echo "}"                                     >> $UPDIR/$TESTFILE.$i.json

    echo $DATE > $UPDIR/$TESTFILE.$i.txt

    for (( j = 1; j <= $i; j++))
    do
      echo $i >> $UPDIR/$TESTFILE.$i.txt
    done

    curl -X POST --user $SHOCK_USER:$SHOCK_PASS \
         -F "attributes=@$UPDIR/$TESTFILE.$i.json"\
         -F "upload=@$UPDIR/$TESTFILE.$i.txt" http://$SHOCK_IP:8000/node/

    let NUMUP=NUMUP+1

  done

  echo
  echo
  echo "Generated and uploaded $NUMUP files with date=$DATE"

elif [[ $MODE == "UPLOAD" ]]
then

  ## UPLOAD
  #############################################################################

  if [[ $# -eq 0 ]]
  then
    echo "Usage: bulktest.sh UPLOAD <uploaddir>"
    exit 1
  fi

  UPDIR=$1; shift;

  NUMUP=0

  for ff in `/bin/ls $UPDIR/* | grep -v 'json'`
  do
    f=`basename $ff`
    echo $ff $f

    echo "{"                            >  $UPDIR/$f.json
    echo " \"filename\": \"$f\","       >> $UPDIR/$f.json
    echo " \"date\":     \"$DATE\""     >> $UPDIR/$f.json
    echo "}"                            >> $UPDIR/$f.json

    curl -X POST --user $SHOCK_USER:$SHOCK_PASS \
         -F "attributes=@$UPDIR/$f.json"\
         -F "upload=@$UPDIR/$f" http://$SHOCK_IP:8000/node/

    let NUMUP=NUMUP+1

  done

  echo
  echo
  echo "Uploaded $NUMUP files with date=$DATE"

elif [[ $MODE == "QUERY" ]]
then

  ## QUERY
  #############################################################################

  if [[ $# -eq 0 ]]
  then
    echo "Usage: bulktest.sh QUERY <querystring>"
    exit 1
  fi
  
  QS=$1; shift;

  curl -X GET --user $SHOCK_USER:$SHOCK_PASS "http://$SHOCK_IP:8000/node/?query&$QS"

elif [[ $MODE == "DOWNLOAD" ]]
then

  ## DOWNLOAD
  #############################################################################

  if [[ $# -eq 0 ]]
  then
    echo "Usage: bulktest.sh DOWNLOAD <querystring>"
    exit 1
  fi

  QS=$1; shift;

  DOWNDIR=$DOWNLOAD_PREFIX.$QS

  rm -rf $DOWNDIR
  mkdir $DOWNDIR

  echo "Downloading all files matching query string: $QS "

  NUMDOWN=0

  for id in `curl -X GET --user $SHOCK_USER:$SHOCK_PASS "http://$SHOCK_IP:8000/node/?query&$QS" | tr '[{,}]' '\n' | grep "\"id\"" | cut -f2 -d':' | tr -d '"'`
  do
    filename=`curl -X GET --user $SHOCK_USER:$SHOCK_PASS "http://$SHOCK_IP:8000/node/$id" | tr '[{,}]' '\n' | grep "\"filename\"" | cut -f2 -d':' | tr -d '"'`
    echo $id $filename

    curl -X GET --user $SHOCK_USER:$SHOCK_PASS \
         "http://$SHOCK_IP:8000/node/$id?download" -o $DOWNDIR/$filename 
    
    let NUMDOWN=NUMDOWN+1

  done

  echo
  echo
  echo "Downloaded $NUMDOWN files to $DOWNDIR"

else

  ## UNKNOWN
  #############################################################################

  echo "ERROR Unknown MODE: $MODE"
fi

