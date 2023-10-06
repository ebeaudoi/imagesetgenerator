#!/bin/bash

## Parameter ##
# From which registry the Operators are coming from 
OPERATORFROM="redhat"
# Red Hat Calalog
CATALOG=registry.redhat.io/redhat/redhat-operator-index:v4.13
# List of operators(separated by a space)
KEEP="advanced-cluster-management"

## Stage 1 - Create a file with the Operator and the default channel
echo "*****************************************************************"
echo "Stage 1 - Create a file with the Operator and the default channel"

# remove previous output file for stage 1
if [[ -f stage1-$OPERATORFROM-operators-v413-withchannels.txt ]]
then
  rm -fr stage1-$OPERATORFROM-operators-v413-withchannels.txt
fi
if [[ -f tmp-stage1-$OPERATORFROM-operators-v413-withchannels.txt ]]
then
  rm -fr tmp-stage1-$OPERATORFROM-operators-v413-withchannels.txt
fi
NBOFOPERATORS=$(echo $KEEP|awk '{print NF}')
COUNTOPS=1;

for OPERATOR in $KEEP;
do 
  echo "$COUNTOPS/$NBOFOPERATORS -- Listing the default channel of the Operator: $OPERATOR"
  oc-mirror list operators --catalog=$CATALOG --package=$OPERATOR>>tmp-stage1-$OPERATORFROM-operators-v413-withchannels.txt;
  ((COUNTOPS++))
done

#Keep only the operators and their default channel
cat tmp-stage1-$OPERATORFROM-operators-v413-withchannels.txt|grep NAME -A1|egrep -v "NAME|--"|awk '{ print $1 "," $NF }' > stage1-$OPERATORFROM-operators-v413-withchannels.txt;

#remove the temporary file
rm tmp-stage1-$OPERATORFROM-operators-v413-withchannels.txt

#Stage 2 - Generate the list of the operator's versions by operator
echo "******************************************************************"
echo "Stage 2 - Generate the list of the operator's versions by operator"
# remove previous output file for stage 2
if [[ -f stage2-$OPERATORFROM-operators-v413-versions-default-channel.txt ]]
then
  rm -fr stage2-$OPERATORFROM-operators-v413-versions-default-channel.txt
fi

COUNTOPS=1;
while read -r line;
do 
  OPNAME=$(echo $line|awk -F, '{print $1}'); CHNAME=$(echo $line|awk -F, '{print $2}');
  echo "$COUNTOPS/$NBOFOPERATORS -- Finding all the version of the operator=$OPNAME with channel=$CHNAME"
  echo "::$OPNAME::$CHNAME" >> stage2-$OPERATORFROM-operators-v413-versions-default-channel.txt;
  oc-mirror list operators --catalog=$CATALOG --package=$OPNAME --channel=$CHNAME |sort -rn|egrep -v ^VERSION >> stage2-$OPERATORFROM-operators-v413-versions-default-channel.txt;
  ((COUNTOPS++))
done < stage1-$OPERATORFROM-operators-v413-withchannels.txt;

#Stage 3 - Generate the ImageSet configuration file
echo "***************************************************************************"
echo "Stage 3 - Generate the ImageSetConfiguration with all the Opertaors/version"
COUNTOPS=1;

echo "kind: ImageSetConfiguration" >$OPERATORFROM-op-v413-config.yaml
echo "apiVersion: mirror.openshift.io/v1alpha2" >>$OPERATORFROM-op-v413-config.yaml
echo "storageConfig:" >>$OPERATORFROM-op-v413-config.yaml
echo "  local:" >>$OPERATORFROM-op-v413-config.yaml
echo "    path: ./metadata/$OPERATORFROM-catalogs" >>$OPERATORFROM-op-v413-config.yaml
echo "mirror:" >>$OPERATORFROM-op-v413-config.yaml
echo "  operators:" >>$OPERATORFROM-op-v413-config.yaml
echo "  - catalog: $CATALOG" >>$OPERATORFROM-op-v413-config.yaml
echo "    targetCatalog: my-$OPERATORFROM-v413-catalog" >>$OPERATORFROM-op-v413-config.yaml
echo "    packages:" >>$OPERATORFROM-op-v413-config.yaml
previousline="";
while read -r line;
do
  #Verify if the previous line is an operator name.  If so, add an entry to the ImageSetConfiguration config file
  if [[ -n $previousline && $previousline = ::* ]]
  then
    opname=$(echo $previousline|awk -F'::' '{print $2}')
    opchannel=$(echo $previousline|awk -F'::' '{print $3}')
    opversion=$(echo $line|awk '{ print $1 }')
    echo "$COUNTOPS/$NBOFOPERATORS -- Adding operator=$opname with channel=$opchannel and version $opversion"
    echo "    - name: $opname" >>$OPERATORFROM-op-v413-config.yaml
    echo "      channels:" >>$OPERATORFROM-op-v413-config.yaml
    echo "      - name: $opchannel" >>$OPERATORFROM-op-v413-config.yaml
    echo "        minVersion: '$line'" >>$OPERATORFROM-op-v413-config.yaml
    echo "        maxVersion: '$line'" >>$OPERATORFROM-op-v413-config.yaml
  fi
  previousline=$line;
done < stage2-$OPERATORFROM-operators-v413-versions-default-channel.txt
