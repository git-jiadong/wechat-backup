#!/bin/bash

FIND_PATH=$1
FILES=`find ${FIND_PATH} -name '*⌖*'`

echo $FILES
for FILE in $FILES
do
    FIXED_FILE=${FILE%⌖}
    #echo "mv $FILE $FIXED_FILE"
    mv $FILE $FIXED_FILE
done

FILES=`find ${FIND_PATH} -name '*__hd'`

echo $FILES
for FILE in $FILES
do
    FIXED_FILE=${FILE%%__*d}
    #echo "mv $FILE $FIXED_FILE"
    mv $FILE $FIXED_FILE
done
