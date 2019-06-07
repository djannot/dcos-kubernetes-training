export SERVICEPATH=${APPNAME}/prod/k8s/cluster${CLUSTER}
export SERVICEACCOUNT=$(echo ${SERVICEPATH} | sed 's/\//-/g')
export ROLE=$(echo ${SERVICEPATH} | sed 's/\//__/g')-role

./create-service-account.sh
./grant-permissions.sh

dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:task:user:root create
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:agent:task:user:root create
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:framework:role:slave_public/${ROLE} create
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:framework:role:slave_public/${ROLE} read
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:reservation:role:slave_public/${ROLE} create
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:volume:role:slave_public/${ROLE} create
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:framework:role:slave_public read
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:agent:framework:role:slave_public read

mv private-training-prod-k8s-cluster${CLUSTER}.pem /tmp
mv public-training-prod-k8s-cluster${CLUSTER}.pem /tmp
