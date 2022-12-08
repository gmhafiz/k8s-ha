# Provision Virtual Machines
up:
	vagrant up

# Create kubernetes cluster
cluster: clear-ssh
	cd ansible && ansible-playbook -i hosts -u root --key-file "vagrant" main.yaml --extra-vars "@vars.json"

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