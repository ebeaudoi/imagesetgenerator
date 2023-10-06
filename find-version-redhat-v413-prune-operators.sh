#!/bin/bash

## Parameter ##
OPERATORTYPE="redhat"
# Red Hat Calalog
CATALOG=registry.redhat.io/redhat/redhat-operator-index:v4.13
# List of operators(separated by a space)
KEEP="advanced-cluster-management"

#Create a file with the Operator and the default channel
echo "Stage 1 - Create a file with the Operator and the default channel"
NBOFOPERATORS=$(echo $KEEP|awk '{print NF}')
COUNTOPS=1;
for OPERATOR in $KEEP;
do 
  echo "$COUNTOPS/$NBOFOPERATORS -- Listing Operator's default channel of $OPERATOR --"
  oc-mirror list operators --catalog=$CATALOG --package=$OPERATOR>>tmp-stage1-$OPERATORTYPE-operators-v413-withchannels.txt;
  ((COUNTOPS++))
done

#Keep only the operators and their default channel
cat tmp-stage1-$OPERATORTYPE-operators-v413-withchannels.txt|grep NAME -A1|egrep -v "NAME|--"|awk '{ print $1 "," $NF }' > stage1-$OPERATORTYPE-operators-v413-withchannels.txt;

#remove the temporary file
rm tmp-stage1-$OPERATORTYPE-operators-v413-withchannels.txt

#Generate the list of the operator's versions by operator
echo "Stage 2 - Generate the list of the operator's versions by operator"
COUNTOPS=1;
while read -r line;
do 
  OPNAME=$(echo $line|awk -F, '{print $1}'); CHNAME=$(echo $line|awk -F, '{print $2}');
  echo "$COUNTOPS/$NBOFOPERATORS -- Finding all the version of the operator=$OPNAME with channel=$CHNAME"
  echo "::$OPNAME::$CHNAME" >> stage2-$OPERATORTYPE-operators-v413-versions-default-channel.txt;
  oc-mirror list operators --catalog=$CATALOG --package=$OPNAME --channel=$CHNAME |sort -rn|egrep -v ^VERSION >> stage2-$OPERATORTYPE-operators-v413-versions-default-channel.txt;
  ((COUNTOPS++))
done < stage1-$OPERATORTYPE-operators-v413-withchannels.txt;
