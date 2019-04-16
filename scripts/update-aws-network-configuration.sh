clusters=$1
loadbalancer=$2
group=$3
eval $(maws login 398053451782_Mesosphere-PowerUser)
aws --region=${REGION} elb create-load-balancer-listeners --load-balancer-name=${loadbalancer} --listeners Protocol=TCP,LoadBalancerPort=8443,InstanceProtocol=TCP,InstancePort=8443
awk -v clusters=${clusters} 'BEGIN { for (i=0; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  aws --region=${REGION} elb create-load-balancer-listeners --load-balancer-name=${loadbalancer} --listeners Protocol=TCP,LoadBalancerPort=80${i},InstanceProtocol=TCP,InstancePort=80${i}
  #aws --region=${REGION} elb create-load-balancer-listeners --load-balancer-name=${loadbalancer} --listeners Protocol=TCP,LoadBalancerPort=90${i},InstanceProtocol=TCP,InstancePort=90${i}
  #aws --region=${REGION} elb create-load-balancer-listeners --load-balancer-name=${loadbalancer} --listeners Protocol=TCP,LoadBalancerPort=100${i},InstanceProtocol=TCP,InstancePort=100${i}
done
#aws --region=${REGION} elb configure-health-check --load-balancer-name=${loadbalancer} --health-check Target=HTTP:9091/_haproxy_health_check,Interval=5,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=2
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=8001-80$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=9001-90$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=10001-100$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
