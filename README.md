# Introduction

Create a highly available kubernetes cluster v1.26 using `kubeadm`, `libvirt`,  `ansible`, `containerd`, `calico`, VMs deployed by vagrant with 1 virtual IP, 2 load balancers, 3 control planes and 3 worker nodes on Debian Bullseye 11. Heavily adapted from https://youtu.be/c1SCdv2hYDc 

# In Short

If you do not want to read the rest, tldr:

```sh
git clone https://github.com/gmhafiz/k8s-ha
cd k8s-ha
make install
make up
make cluster
```

## Vagrant Environment

| Role          | Host Name      | IP            | OS                 | RAM   | CPU |
|---------------|----------------|---------------|--------------------|-------|-----|
| Load Balancer | loadbalancer1  | 172.16.16.51  | Debian Bullseye 11 | 512MB | 1   |
| Load Balancer | loadbalancer1  | 172.16.16.52  | Debian Bullseye 11 | 512MB | 1   |
| Control Plane | kcontrolplane1 | 172.16.16.101 | Debian Bullseye 11 | 2G    | 2   |
| Control Plane | kcontrolplane2 | 172.16.16.102 | Debian Bullseye 11 | 2G    | 2   |
| Control Plane | kcontrolplane3 | 172.16.16.103 | Debian Bullseye 11 | 2G    | 2   |
| Worker        | kworker1       | 172.16.16.201 | Debian Bullseye 11 | 2G    | 2   |
| Worker        | kworker2       | 172.16.16.202 | Debian Bullseye 11 | 2G    | 2   |
| Worker        | kworker3       | 172.16.16.203 | Debian Bullseye 11 | 2G    | 2   |


Host Machine Requirements

 - 14 cores
 - 13G memory
 - CPUs can host hardware accelerated KVM virtual machines.

Note that vagrant creates the IP address we are concerned with at `eth1`.

# Preparation

If everything has been prepared, skip to [Kubernetes Cluster](#Kubernetes Cluster) section.

## On host machine

Needs kvm and libvirt for virtualization. The command `kvm-ok` should give you an 'ok' if
virtualization is supported by the CPU.

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

Install ansible

```sh
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
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
ssh-keygen -t rsa -b 4096 -f ansible/vagrant
chmod 600 ansible/vagrant
chmod 644 ansible/vagrant.pub
```

# Kubernetes Cluster

You only need a single command!

```sh
make up && make cluster
```

For manual steps, read on...

Provision the VMs and change directory to `ansible`.

```sh
vagrant up
cd ansible
```

If those IP addresses have been used (or you have provisioned before), need to clear them 
up.

```sh
{
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.16.16.51
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.16.16.52
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.16.16.101
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.16.16.102
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.16.16.103
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.16.16.201
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.16.16.202
    ssh-keygen -f $HOME/.ssh/known_hosts -R 172.16.16.203
}
```

Create a kubernetes cluster by running this single command:

```sh
ansible-playbook -u root --key-file "vagrant" main.yaml --extra-vars "@vars.yaml"
```

or one by one,

```sh
ansible-playbook -u root --key-file "vagrant" 01-initial.yaml --extra-vars "@vars.yaml"
ansible-playbook -u root --key-file "vagrant" 02-packages.yaml
ansible-playbook -u root --key-file "vagrant" 03-lb.yaml --extra-vars "@vars.yaml"
ansible-playbook -u root --key-file "vagrant" 04-k8s.yaml --extra-vars "@vars.yaml"
ansible-playbook -u root --key-file "vagrant" 05-control-plane.yaml --extra-vars "@vars.yaml"
ansible-playbook -u root --key-file "vagrant" 06-worker.yaml
ansible-playbook -u root --key-file "vagrant" 07-k8s-config.yaml
```

Once step 1 is completed, may ssh into each server with either commands

```sh
ssh -i ./vagrant vagrant@172.16.16.101 # If you use the newly generated public-private key pair
ssh kubeadmin@172.16.16.101            # If using existing ~/.ssh/id_rsa.pub key
```

If the step 5, initialization of k8s cluster fails, reset with this playbook and re-run 
from step 5 onwards.

```sh
ansible-playbook -u root --key-file "vagrant" XX-kubeadm_reset.yaml
```

If everything is successful, check if it is working from the host machine. The 
final playbook copies `/etc/kubernetes/admin.conf` into your `~/.kube/config` to 
allow you to manage from the host. But to use `kubectl` command, we need to
install it on local machine:

```sh
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
sudo apt-mark hold kubectl
```

then,

```sh
kubectl cluster-info
kubectl get no
```

It can take some time before everything is up, watch every second:

```sh
watch -n 1 kubectl get no
```

Cluster is ready when all status is `Ready`

```
$ kubectl get no
NAME             STATUS   ROLES           AGE     VERSION
kcontrolplane1   Ready    control-plane   11m     v1.26.0
kcontrolplane2   Ready    control-plane   39s     v1.26.0
kcontrolplane3   Ready    control-plane   8m50s   v1.26.0
kworker1         Ready    <none>          7m51s   v1.26.0
kworker2         Ready    <none>          7m51s   v1.26.0
kworker3         Ready    <none>          7m51s   v1.26.0
```

# Deploy Container

To test that the cluster is working, let us try to deploy an nginx server. On the 
host machine create a deployment and expose the service.

```sh
kubectl create deployment nginx-deployment --image=nginx
kubectl expose deployment nginx-deployment --port=80 --target-port=80
```

Check if the pods are up

```sh
kubectl get po -o wide
```

Also, if service is created

```sh
kubectl get svc
```

The way we are accessing the container is by doing a port forward. In production,
you would want to look at ingress like metallb or nginx. We will explore that 
option in part three. For now, a port forward from the deployment to local 
suffice. We are doing a port forward from 80 to 8080 of that service

```sh
kubectl port-forward deployment/nginx-deployment 8080:80
```

You will see this output

```
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

Access http://localhost:8080 in the browser.

---

# TODO

 - [ ] Adjust disk space on VMs
 - [x] Multi control plane kubernetes cluster
 - [x] High Available (HA) cluster
 - [ ] Backup and restore etcd data
 - [ ] Deploy 
   - [ ] SPA frontend
   - [ ] api backend
   - [ ] one DB
 - [ ] Ingress controller


# Reference

The guide is not created from vacuum. Several guides were referred:

Major source of reference
 - https://youtu.be/c1SCdv2hYDc
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

Make Vagrant Debian use rsync instead of nfsd
 - https://wiki.debian.org/Vagrant#Failure_to_start_on_NFS

Hint for Debian 11
 - https://www.linuxtechi.com/install-kubernetes-cluster-on-debian/
