path=${APPNAME}/prod/k8s/cluster${1}

serviceaccount=$(echo $path | sed 's/\//-/g')
role=$(echo $path | sed 's/\//__/g')-role

dcos security org service-accounts keypair private-${serviceaccount}.pem public-${serviceaccount}.pem
dcos security org service-accounts delete ${serviceaccount}
dcos security org service-accounts create -p public-${serviceaccount}.pem -d /${path} ${serviceaccount}
dcos security secrets delete /${path}/private-${serviceaccount}
dcos security secrets create-sa-secret --strict private-${serviceaccount}.pem ${serviceaccount} /${path}/private-${serviceaccount}

dcos security org users grant ${serviceaccount} dcos:secrets:default:/${path}/* full
dcos security org users grant ${serviceaccount} dcos:secrets:list:default:/${path} full
dcos security org users grant ${serviceaccount} dcos:adminrouter:ops:ca:rw full
dcos security org users grant ${serviceaccount} dcos:adminrouter:ops:ca:ro full
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:role:${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:principal:${serviceaccount} delete
dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:role:${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:principal:${serviceaccount} delete
dcos security org users grant ${serviceaccount} dcos:mesos:master:task:user:nobody create
dcos security org users grant ${serviceaccount} dcos:mesos:master:task:user:root create
dcos security org users grant ${serviceaccount} dcos:mesos:agent:task:user:root create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public/${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public/${role} read
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:role:slave_public/${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:role:slave_public/${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public read
dcos security org users grant ${serviceaccount} dcos:mesos:agent:framework:role:slave_public read

dcos kubernetes cluster create --yes --options=options-kubernetes-cluster${1}.json --package-version=2.2.1-1.13.4
#dcos kubernetes cluster create --yes --options=options-kubernetes-cluster${1}.json --package-version=2.2.0-1.13.3
