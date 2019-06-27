## CHANGE THIS EVERY TIME!!!
export APPNAME=training
export PUBLICIP=54.81.182.214
export CLUSTER=djannot
export REGION=us-east-1
export clusters=2
export maws=110465657741_Mesosphere-PowerUser

#### Remove all DC/OS Clusters
rm -rf ~/.dcos/clusters

#### SETUP MASTER URL VARIABLE

# NOTE: elb url is not used in this script (yet) TODO
if [[ $1 == "" ]]
then
        echo
        echo " A master node's URL was not entered. Aborting."
        echo
        exit 1
fi

MASTER_URL=$1

#### SETUP CLI

./scripts/setup_cli.sh $MASTER_URL

loadbalancer=ext-$CLUSTER
eval $(maws login ${maws})
# The group ID of the AWS Security Group of the DC/OS public nodes
group=$(aws --region=$REGION ec2 describe-instances |  jq --raw-output ".Reservations[].Instances[] | select((.Tags | length) > 0) | select(.Tags[].Value | test(\"${CLUSTER}-publicagent\")) | select(.State.Name | test(\"running\")) | .SecurityGroups[] | [.GroupName, .GroupId] | \"\(.[0]) \(.[1])\"" | grep public-agents-lb-firewall | awk '{ print $2 }' | sort -u)

./scripts/create-and-attach-volumes.sh ${maws}
./scripts/create-csi-iam-policy.sh ${maws}
./scripts/update-aws-network-configuration.sh ${clusters} ${loadbalancer} ${group} ${maws}

dcos package install --yes --cli dcos-enterprise-cli

nodes=$(dcos node --json | jq --raw-output ".[] | select((.type | test(\"agent\")) and (.attributes.public_ip == null)) | .id" | wc -l | awk '{ print $1 }')
sed "s/NODES/${nodes}/g" scripts/options-portworx.json.template > scripts/options-portworx.json

./scripts/deploy-portworx.sh

./scripts/deploy-kubernetes-mke.sh
./scripts/check-kubernetes-mke-status.sh

./scripts/deploy-dcos-monitoring.sh

./create-pool-edgelb-all.sh ${clusters}
./scripts/deploy-edgelb.sh
./scripts/check-app-status.sh infra/network/dcos-edgelb/pools/all

sed "/mesos.lab/d" /etc/hosts > ./hosts
awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "$PUBLICIP ${APPNAME}.prod.k8s.cluster${i}.mesos.lab" >>./hosts
done
sudo mv hosts /etc/hosts
