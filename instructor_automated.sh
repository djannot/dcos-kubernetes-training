## CHANGE THIS EVERY TIME!!!
export APPNAME=training
export PUBLICIP=54.149.137.143
export CLUSTER=k8straining-clustertest
export REGION=us-west-2
clusters=40

#### SETUP MASTER URL VARIABLE

# NOTE: elb url is not used in this script (yet) TODO
if [[ $1 == "" ]]
then
        echo
        echo " A master node's URL was not entered. Aborting."
        echo
        exit 1
fi

# For the master change http to https so kubectl setup doesn't break
MASTER_URL=$(echo $1 | sed 's/http/https/')

#### SETUP CLI

./scripts/setup_cli.sh $MASTER_URL

loadbalancer=ext-$CLUSTER
eval $(maws login 110465657741_Mesosphere-PowerUser)
# The group ID of the AWS Security Group of the DC/OS public nodes
group=$(aws --region=$REGION ec2 describe-instances |  jq --raw-output ".Reservations[].Instances[] | select((.Tags | length) > 0) | select(.Tags[].Value | test(\"${CLUSTER}-publicagent\")) | select(.State.Name | test(\"running\")) | .SecurityGroups[] | [.GroupName, .GroupId] | \"\(.[0]) \(.[1])\"" | grep public-agents-lb-firewall | awk '{ print $2 }' | sort -u)

./scripts/create-and-attach-volumes.sh
./scripts/create-csi-iam-policy.sh
./scripts/update-aws-network-configuration.sh ${clusters} ${loadbalancer} ${group}

dcos package install --yes --cli dcos-enterprise-cli

nodes=$(dcos node --json | jq --raw-output ".[] | select((.type | test(\"agent\")) and (.attributes.public_ip == null)) | .id" | wc -l | awk '{ print $1 }')
sed "s/NODES/${nodes}/g" scripts/options-portworx.json.template > scripts/options-portworx.json

./scripts/deploy-portworx.sh

./scripts/deploy-kubernetes-mke.sh
./scripts/check-kubernetes-mke-status.sh

./create-pool-edgelb-all.sh ${clusters}
./scripts/deploy-edgelb.sh
./scripts/check-app-status.sh infra/network/dcos-edgelb/pools/all

sed "/mesos.lab/d" /etc/hosts > ./hosts
awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "$PUBLICIP ${APPNAME}.prod.k8s.cluster${i}.mesos.lab" >>./hosts
done
sudo mv hosts /etc/hosts
