clusters=$1
loadbalancer=$2
group=$3
maws=$4
eval $(maws login ${maws})
#aws --region=${REGION} elb create-load-balancer-listeners --load-balancer-name=${loadbalancer} --listeners Protocol=TCP,LoadBalancerPort=8443,InstanceProtocol=TCP,InstancePort=8443
#awk -v clusters=${clusters} 'BEGIN { for (i=0; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do#
  #aws --region=${REGION} elb create-load-balancer-listeners --load-balancer-name=${loadbalancer} --listeners Protocol=TCP,LoadBalancerPort=80${i},InstanceProtocol=TCP,InstancePort=80${i}
  #aws --region=${REGION} elb create-load-balancer-listeners --load-balancer-name=${loadbalancer} --listeners Protocol=TCP,LoadBalancerPort=90${i},InstanceProtocol=TCP,InstancePort=90${i}
  #aws --region=${REGION} elb create-load-balancer-listeners --load-balancer-name=${loadbalancer} --listeners Protocol=TCP,LoadBalancerPort=100${i},InstanceProtocol=TCP,InstancePort=100${i}
#done
#aws --region=${REGION} elb configure-health-check --load-balancer-name=${loadbalancer} --health-check Target=HTTP:9091/_haproxy_health_check,Interval=5,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=2
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=8001-80$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=9001-90$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=9101-91$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=10001-100$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=10101-101$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=10201-102$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=10301-103$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=10401-104$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=10501-105$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=10601-106$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=10701-107$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
aws --region=${REGION} ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=10801-108$(echo ${clusters} | awk '{printf("%02d\n", $0)}') --cidr=0.0.0.0/0
