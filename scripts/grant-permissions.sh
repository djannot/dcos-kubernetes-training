cd $(dirname $0)

dcos security org users grant ${SERVICEACCOUNT} dcos:secrets:default:/${SERVICEPATH}/* full
dcos security org users grant ${SERVICEACCOUNT} dcos:secrets:list:default:/${SERVICEPATH} full
dcos security org users grant ${SERVICEACCOUNT} dcos:adminrouter:ops:ca:rw full
dcos security org users grant ${SERVICEACCOUNT} dcos:adminrouter:ops:ca:ro full
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:framework:role:${ROLE} create
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:reservation:role:${ROLE} create
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:reservation:principal:${SERVICEACCOUNT} delete
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:volume:role:${ROLE} create
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:volume:principal:${SERVICEACCOUNT} delete
dcos security org users grant ${SERVICEACCOUNT} dcos:mesos:master:task:user:nobody create
