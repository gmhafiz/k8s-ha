# Essential tools for linux
install:
	sudo apt update && \
	sudo apt install bridge-utils qemu-kvm virtinst libvirt-dev libvirt-daemon virt-manager && \
	wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list \
	sudo apt update && sudo apt install vagrant && \
	vagrant plugin install vagrant-libvirt vagrant-vbguest && \
	sudo apt install software-properties-common && \
    sudo apt-add-repository --yes --update ppa:ansible/ansible && \
    sudo apt install ansible python3-passlib

# Provision Virtual Machines
up:
	vagrant up

# Create kubernetes cluster
cluster: clear-ssh
	cd ansible && ansible-playbook -i hosts -u root --key-file "vagrant" main.yaml --extra-vars "@vars.yaml"

# Reset remembering ssh keys
clear-ssh:
	ssh-keygen -f ~/.ssh/known_hosts -R 172.16.16.51 && \
	ssh-keygen -f ~/.ssh/known_hosts -R 172.16.16.52 && \
	ssh-keygen -f ~/.ssh/known_hosts -R 172.16.16.101 && \
	ssh-keygen -f ~/.ssh/known_hosts -R 172.16.16.102 && \
	ssh-keygen -f ~/.ssh/known_hosts -R 172.16.16.103 && \
	ssh-keygen -f ~/.ssh/known_hosts -R 172.16.16.201 && \
	ssh-keygen -f ~/.ssh/known_hosts -R 172.16.16.202 && \
	ssh-keygen -f ~/.ssh/known_hosts -R 172.16.16.203

# Reset everything
reset: clear-ssh
	vagrant destroy -f

# Graceful shutdown of Virtual Machines
halt:
	vagrant halt
