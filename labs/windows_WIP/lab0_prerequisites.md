# Pre-requisites

## Change Directory
To start your labs, cd into the `student` directory
```
cd student
```

## Clear all DC/OS Clusters, If Any, from your Local Machine
```
rm -rf ~/.dcos/clusters
```

Optional: You can also move the directory to /tmp/dcos-clusters as backup:
```
sudo mkdir /tmp/dcos-clusters
sudo mv ~/.dcos/clusters/* /tmp/dcos-clusters 2> /dev/null
sudo mv ~/.dcos/dcos.toml /tmp/dcos-clusters 2> /dev/null
sudo rm -rf ~/.dcos 2> /dev/null
```

## Move Existing Kube Config File, If Any, to an alternate file name
```
mv ~/.kube/config ~/.kube/config.ori
```

## Access the DC/OS UI
Log into the DC/OS Kubernetes cluster with the information provided by your instructor. You can also download the DC/OS CLI to use on your local machine by clicking the dropdown at the top-right --> Install CLI

## Install the DC/OS CLI

Windows:
Follow the instructions located in the top-right dropdown to install the DC/OS CLI on a Windows machine
![Install Windows CLI](https://github.com/djannot/dcos-kubernetes-training/blob/master/images/lab0_1.png)

## Set up DC/OS CLI Using HTTPS (required by Kubernetes)
Run the following command to setup the DC/OS CLI:
```
dcos cluster setup https://<IP provided by the instructor>
```

To validate that you are authenticated to the DC/OS CLI using HTTPS: run:
```
dcos config show core.dcos_url
```

Additionally, if the TLS certificate used by DC/OS is not trusted, you can run the following command to disable TLS verification:
```
dcos config set core.ssl_verify false
```

## Install the DC/OS Enterprise CLI
Run the following command to add the DC/OS Enterprise extensions to the DC/OS CLI:

```
dcos package install --yes --cli dcos-enterprise-cli
```

## Lab Variables
Run the following command to export the environment variables needed during the labs:

```
set APPNAME=training
set PUBLICIP=<PUBLIC IP PROVIDED BY INSTRUCTOR>
set CLUSTER=<the number assigned by the instructor: 01, 02, ..>
```

## Install kubectl on your local machine
Install the kubectl CLI using the instructions available at the URL below:

[https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

### Popular methods of installing kubectl:

Using Choco on Windows:
```
choco install kubernetes-cli
```

## Add DNS Hostname to your Windows Hosts file (`c:\Windows\System32\Drivers\etc\hosts`) for our Labs
Add the following line to your /etc/hosts (or c:\Windows\System32\Drivers\etc\hosts) file:
```
echo "$PUBLICIP training.prod.k8s.cluster$CLUSTER.mesos.lab" >> /etc/hosts
```

We will be using this hostname translation when connecting to our kubernetes clusters using kubectl


## Finished with the Lab 0 - Prerequisites

[Move to Lab 1 - Deploying Kubernetes](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/lab1_deploying_kubernetes.md)
