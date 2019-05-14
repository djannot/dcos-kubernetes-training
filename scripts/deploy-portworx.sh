path=infra/storage/portworx
serviceaccount=infra-storage-portworx

dcos security org service-accounts keypair private-${serviceaccount}.pem public-${serviceaccount}.pem
dcos security org service-accounts delete ${serviceaccount}
dcos security org service-accounts create -p public-${serviceaccount}.pem -d /${path} ${serviceaccount}
dcos security secrets delete /${path}/private-${serviceaccount}
dcos security secrets create-sa-secret --strict private-${serviceaccount}.pem ${serviceaccount} /${path}/private-${serviceaccount}

dcos security org users grant ${serviceaccount} dcos:superuser full

dcos security org users grant dcos_marathon dcos:mesos:master:task:user:root create

dcos security org users create -p password portworx
dcos security org users grant portworx dcos:secrets:default:/infra/storage/portworx/secrets/* full

dcos package install --yes portworx --options=scripts/options-portworx.json --package-version=1.3.5-2.0.3
