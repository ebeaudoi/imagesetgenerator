#!/bin/bash

## Parameter ##
OPERATORTYPE="redhat"
# Red Hat Calalog
CATALOG=registry.redhat.io/redhat/redhat-operator-index:v4.13
# List of operators(separated by a space)
KEEP="advanced-cluster-management"

#Stage 1 - Create a file with the Operator and the default channel
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

#Stage 2 - Generate the list of the operator's versions by operator
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

#Stage 3 - Generate the ImageSet configuration file
echo "Stage 3 - Generate the ImageSetConfiguration with all the Opertaors/version"
COUNTOPS=1;

echo "kind: ImageSetConfiguration" >$OPERATORTYPE-op-v413-config.yaml
echo "apiVersion: mirror.openshift.io/v1alpha2" >>$OPERATORTYPE-op-v413-config.yaml
echo "storageConfig:" >>$OPERATORTYPE-op-v413-config.yaml
echo "  local:" >>$OPERATORTYPE-op-v413-config.yaml
echo "    path: ./metadata/$OPERATORTYPE-catalogs" >>$OPERATORTYPE-op-v413-config.yaml
echo "mirror:" >>$OPERATORTYPE-op-v413-config.yaml
echo "  operators:" >>$OPERATORTYPE-op-v413-config.yaml
echo "  - catalog: $CATALOG" >>$OPERATORTYPE-op-v413-config.yaml
echo "    targetCatalog: my-$OPERATORTYPE-v413-catalog" >>$OPERATORTYPE-op-v413-config.yaml
echo "    packages:" >>$OPERATORTYPE-op-v413-config.yaml
previousline="";
while read -r line;
do
  #Verify if the previous line is an operator name.  If so, add an entry to the ImageSetConfiguration config file
  echo "previous ==> $previousline"
  echo "line     ==> $line"
  if [[ -n $previousline && $previousline = ::* ]]
  then
    opname=$(echo $previousline|awk -F'::' '{print $2}')
    opchannel=$(echo $previousline|awk -F'::' '{print $3}')
    opversion=$(echo $line|awk '{ print $1 }')
    echo "$COUNTOPS/$NBOFOPERATORS -- Adding operator=$opname with channel=$opchannel and version $opversion"
    echo "    - name: $opname" >>$OPERATORTYPE-op-v413-config.yaml
    echo "      channels:" >>$OPERATORTYPE-op-v413-config.yaml
    echo "      - name: $opchannel" >>$OPERATORTYPE-op-v413-config.yaml
    echo "        minVersion: '$line'" >>$OPERATORTYPE-op-v413-config.yaml
    echo "        maxVersion: '$line'" >>$OPERATORTYPE-op-v413-config.yaml
  fi
  previousline=$line;
done < stage2-$OPERATORTYPE-operators-v413-versions-default-channel.txt
