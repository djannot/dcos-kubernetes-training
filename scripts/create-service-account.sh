cd $(dirname $0)

dcos security org service-accounts keypair private-${SERVICEACCOUNT}.pem public-${SERVICEACCOUNT}.pem
dcos security org service-accounts delete ${SERVICEACCOUNT}
dcos security org service-accounts create -p public-${SERVICEACCOUNT}.pem -d /${SERVICEPATH} ${SERVICEACCOUNT}
dcos security secrets delete /${SERVICEPATH}/private-${SERVICEACCOUNT}
dcos security secrets create-sa-secret --strict private-${SERVICEACCOUNT}.pem ${SERVICEACCOUNT} /${SERVICEPATH}/private-${SERVICEACCOUNT}
