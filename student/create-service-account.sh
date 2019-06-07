cd $(dirname $0)

dcos security org service-accounts keypair private-${SERVICEACCOUNT}.pem public-${SERVICEACCOUNT}.pem
dcos security org service-accounts show ${SERVICEACCOUNT} > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "Deleting the existing service account"
  dcos security org service-accounts delete ${SERVICEACCOUNT}
fi
dcos security org service-accounts create -p public-${SERVICEACCOUNT}.pem -d /${SERVICEPATH} ${SERVICEACCOUNT}
test=$(dcos security secrets list / | grep -c ${SERVICEPATH}/private-${SERVICEACCOUNT})
if [ $test -ne 0 ]; then
  echo "Deleting the existing secret"
  dcos security secrets delete /${SERVICEPATH}/private-${SERVICEACCOUNT}
fi
dcos security secrets create-sa-secret --strict private-${SERVICEACCOUNT}.pem ${SERVICEACCOUNT} /${SERVICEPATH}/private-${SERVICEACCOUNT}
