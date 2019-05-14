# Teardown

## Variables
Run the following command to export the environment variables needed for teardown:
```
export REGION=<Terraform Cluster Region>
export CLUSTER=<Terraform Cluster Name>
```

## Detatch and Delete EBS Volumes
Because the EBS volumes used by Portworx were created out-of-band to Terraform, run the script below to remove these resources
```
./detach-and-delete-volumes.sh
```

## Remove AWS IAM Policy for CSI through the AWS Console
Because the AWS IAM Policy for CSI was created out-of-band to Terraform, navigate to the AWS Console --> IAM --> Cluster Name to remove the CSI policy

![IAM Policy](https://github.com/ably77/dcos-kubernetes-training/blob/master/images/instructor_1.png)

## Destroy your Terraform Cluster
```
export AWS_DEFAULT_REGION="us-west-2"
export AWS_PROFILE=110465657741_Mesosphere-PowerUser
terraform destroy
```
