# Introduction

Create a kubernetes cluster v1.25 using libvirt, VMs deployed by vagrant with 3 
control planes and 3 worker nodes on Ubuntu 22.04 machines. Heavily adapted from 
https://youtu.be/c1SCdv2hYDc 

## Vagrant Environment
| Role          | Host Name      | IP            | OS           | RAM | CPU |
|---------------|----------------|---------------|--------------|-----|-----|
| Control Plane | kcontrolplane1 | 172.17.17.101 | Ubuntu 22.04 | 2G  | 2   |
| Control Plane | kcontrolplane2 | 172.17.17.102 | Ubuntu 22.04 | 2G  | 2   |
| Control Plane | kcontrolplane3 | 172.17.17.103 | Ubuntu 22.04 | 2G  | 2   |
| Worker        | kworker1       | 172.17.17.201 | Ubuntu 22.04 | 2G  | 2   |
| Worker        | kworker2       | 172.17.17.202 | Ubuntu 22.04 | 2G  | 2   |
| Worker        | kworker3       | 172.17.17.203 | Ubuntu 22.04 | 2G  | 2   |


Host Machine Requirements

 - 12 cores
 - 12G memory
 - CPU can host hardware accelerated KVM virtual machines.

Note that vagrant creates the IP address we are concerned with at `eth1`.

# Preparation

If everything has been prepared, skip to [Kubernetes Cluster](#Kubernetes Cluster) section.

## On host machine

Needs kvm and libvirt for virtualization. The command `kvm-ok` should give you an 'ok' if
virtualization is supported by CPU.

```sh
sudo apt update && sudo apt upgrade
sudo apt install bridge-utils qemu-kvm virtinst libvirt-dev libvirt-daemon virt-manager
kvm-ok
```

Provision VMs using an automated tool called vagrant. Install with libvirt plugin.

```sh
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
vagrant plugin install vagrant-libvirt vagrant-disksize vagrant-vbguest
```

Install kubectl

```sh
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

To gain access with ssh into the VMs, we copy a public key at initialization. Either
modify the `Vagrantfile` file `ssh_pub_key = File.readlines("./ansible/vagrant.pub").first.strip`
to point into your `~/.ssh/id_rsa.pub`, or create a new one:

```sh
ssh-keygen -t rsa -b 4096 -f vagrant
chmod 600 vagrant
chmod 644 vagrant.pub
```


# Kubernetes Cluster

Provision the VMs and change directory to `ansible`.

```sh
vagrant up
cd ansible
```

If those IP addresses have been used (or you have provisioned before), need to clear them 
up.

```sh
{
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.17.17.101
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.17.17.102
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.17.17.103
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.17.17.201
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.17.17.202
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.17.17.203
}
```

Make ansible happy

```sh
export ANSIBLE_HOST_KEY_CHECKING=False
```

Create a kubernetes cluster by running this single command:

```sh
ansible-playbook -i hosts -u root --key-file "vagrant" main.yaml --extra-vars "@vars.json"
```

or one by one,

```sh
ansible-playbook -i hosts -u root --key-file "vagrant" 01-initial.yaml
ansible-playbook -i hosts -u root --key-file "vagrant" 02-packages.yaml
ansible-playbook -i hosts -u root --key-file "vagrant" 03-lb.yaml --extra-vars "@vars.json"
ansible-playbook -i hosts -u root --key-file "vagrant" 04-k8s.yaml --extra-vars "@vars.json"
ansible-playbook -i hosts -u root --key-file "vagrant" 05-control-plane.yaml --extra-vars "@vars.json"
ansible-playbook -i hosts -u root --key-file "vagrant" 06-worker.yaml
ansible-playbook -i hosts -u root --key-file "vagrant" 07-k8s-config.yaml
```

Once step 1 is completed, may ssh into each server with either commands

```sh
ssh -i ./vagrant vagrant@172.17.17.101 # If you use the newly generated public-private key pair
ssh kubeadmin@172.17.17.101            # If using existing ~/.ssh/id_rsa.pub key
```

If the step 5, initialization of k8s cluster fails, reset with this playbook and re-run 
from step 5 onwards.

```sh
ansible-playbook -i hosts -u root --key-file "vagrant" XX-kubeadm_reset.yaml
```


If everything is successful, check if it is working from host machine. The last playbook
copies `/etc/kubernetes/admin.conf` into your `~/.kube/config` to allow you to manage
from host.

```sh
kubectl cluster-info
kubectl get no
```

It can take sometime before everything is up, watch every second:

```sh
watch -n 1 kubectl get no
```

Cluster is ready when all status is `Ready`

```
$ kubectl get no
NAME             STATUS   ROLES           AGE     VERSION
kcontrolplane1   Ready    control-plane   11m     v1.25.3
kcontrolplane2   Ready    control-plane   39s     v1.25.3
kcontrolplane3   Ready    control-plane   8m50s   v1.25.3
kworker1         Ready    <none>          7m51s   v1.25.3
kworker2         Ready    <none>          7m51s   v1.25.3
kworker3         Ready    <none>          7m51s   v1.25.3
```

# Deploy Container

To test that the cluster is working, try to deploy an nginx server. On host machine create
a deployment and expose the service.

```sh
kubectl create deployment nginx-deployment --image=nginx
kubectl expose deployment nginx-deployment --port=8070 --target-port=80
```

Check if the pods are up and to get its name

```sh
kubectl get po -o wide
```

Port forward 80 to 8070 of that pod

```sh
kubectl port-forward nginx-deployment-<REPLACE-ME> 8070:80
```

Access localhost:8070 in the browser.

---

# TODO

 - [x] Multi control plane kubernetes cluster
 - [ ] High Available (HA) cluster


# Reference

The guide is not created from vacuum. Several guides were referred:

Major source of reference
 - https://www.youtube.com/watch?v=c1SCdv2hYDc&list=PL34sAs7_26wNBRWM6BDhnonoA5FMERax0&index=8
 - https://github.com/justmeandopensource/kubernetes

Tip for High Available (HA) kubernetes cluster using keepalived and haproxy
 - https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing

Idea for unicast option on haproxy 
 - https://kacangisnuts.com/2021/04/kubernetes-control-plane-resiliency-with-haproxy-and-keepalived/

Second reference for `--apiserver-advertise-address` option
 - https://devopscube.com/setup-kubernetes-cluster-kubeadm/

Gives me the idea of putting haproxy and keepalived on control planes
 - https://kvaps.medium.com/for-make-this-scheme-more-safe-you-can-add-haproxy-layer-between-keepalived-and-kube-apiservers-62c344283076

Copied some ansible commands
 - https://www.adminz.in/2022/01/kubernetes-with-containerd-using-ansible.html?m=0
