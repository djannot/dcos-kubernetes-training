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

Mac/OS:
```
[ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin &&
curl https://downloads.dcos.io/binaries/cli/darwin/x86-64/dcos-1.13/dcos -o dcos &&
sudo mv dcos /usr/local/bin &&
sudo chmod +x /usr/local/bin/dcos
```

Linux:
```
[ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin &&
curl https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.13/dcos -o dcos &&
sudo mv dcos /usr/local/bin &&
sudo chmod +x /usr/local/bin/dcos
```

## Set up DC/OS CLI Using HTTPS (required by Kubernetes)
Run the following command to setup the DC/OS CLI:
```
dcos cluster setup https://<IP provided by the instructor>
```

To validate that you are authenticated to the DC/OS CLI using https: run:
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
export APPNAME=training
export PUBLICIP=<PUBLIC IP PROVIDED BY INSTRUCTOR>
export CLUSTER=<the number assigned by the instructor: 01, 02, ..>
```

## Install kubectl on your local machine
Install the kubectl CLI using the instructions available at the URL below:

[https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

### Popular methods of installing kubectl:

Using Brew on MacOS:
```
brew install kubernetes-cli
```

Using CentOS / RHEL / Fedora:
```
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
```

## Add DNS Hostname to your /etc/hosts or Windows Hosts file for our Labs
Add the following line to your /etc/hosts (or c:\Windows\System32\Drivers\etc\hosts) file:
```
echo "$PUBLICIP training.prod.k8s.cluster$CLUSTER.mesos.lab" >> /etc/hosts
```

We will be using this hostname translation when connecting to our kubernetes clusters using kubectl

## Verify Entry
Verify that the entry in your /etc/hosts is correct
```
cat /etc/hosts
```

Output should look similar to below:
```
$ cat /etc/hosts
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1	localhost
255.255.255.255	broadcasthost
::1             localhost
34.221.133.99 training.prod.k8s.cluster01.mesos.lab
```

## Finished with the Lab 0 - Prerequisites

[Move to Lab 1 - Deploying Kubernetes](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/linux-macOS/lab1_deploying_kubernetes.md)
