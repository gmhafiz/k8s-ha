# -*- mode: ruby -*-
# vi: set ft=ruby :

# ENV['VAGRANT_NO_PARALLEL'] = 'yes'
# ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'

VAGRANT_BOX               = "generic/ubuntu2004"
VAGRANT_BOX_VERSION       = "3.3.0"
# VAGRANT_BOX               = "generic/ubuntu2204"
# VAGRANT_BOX_VERSION       = "4.0.2"
# VAGRANT_BOX_VERSION       = "4.2.0"
CPUS_LB_NODE              = 1
CPUS_CONTROL_PLANE_NODE   = 2
CPUS_WORKER_NODE          = 2
MEMORY_LB_NODE            = 512
MEMORY_CONTROL_PLANE_NODE = 2048
MEMORY_WORKER_NODE        = 2048
DISK_LB_NODE              = '1GB'
DISK_CONTROL_PLANE_NODE   = '20GB'
DISK_WORKER_NODE          = '150GB'

LOAD_BALANCER_COUNT = 2
CONTROL_PLANE_COUNT = 3
WORKER_COUNT        = 3

Vagrant.configure(2) do |config|

  config.vm.provision "shell", path: "bootstrap.sh"

  (1..LOAD_BALANCER_COUNT).each do |i|

    config.vm.define "loadbalancer#{i}" do |lb|

      lb.vm.box               = VAGRANT_BOX
      lb.vm.box_check_update  = false
      lb.vm.box_version       = VAGRANT_BOX_VERSION
      lb.vm.hostname          = "loadbalancer#{i}"
      # lb.disksize.size        = DISK_LB_NODE

      lb.vm.network "private_network", ip: "172.17.17.5#{i}"

      ssh_pub_key = File.readlines("./ansible/vagrant.pub").first.strip
      config.vm.provision 'shell', inline: 'mkdir -p /root/.ssh'
      config.vm.provision 'shell', inline: "echo #{ssh_pub_key} >> /root/.ssh/authorized_keys"
      # config.vm.provision 'shell', inline: "echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys", privileged: false

      lb.vm.provider :libvirt do |v|
        v.memory  = MEMORY_LB_NODE
        v.cpus    = CPUS_LB_NODE
      end

      lb.vm.provider :virtualbox do |v|
        v.name   = "loadbalancer#{i}"
        v.memory = MEMORY_LB_NODE
        v.cpus   = CPUS_LB_NODE
      end

    end

  end

  (1..CONTROL_PLANE_COUNT).each do |i|

    config.vm.define "kcontrolplane#{i}" do |cpnode|

      cpnode.vm.box               = VAGRANT_BOX
      cpnode.vm.box_check_update  = false
      cpnode.vm.box_version       = VAGRANT_BOX_VERSION
      cpnode.vm.hostname          = "kcontrolplane#{i}"
      # cpnode.disksize.size        = DISK_CONTROL_PLANE_NODE

      cpnode.vm.network "private_network", ip: "172.17.17.10#{i}"

      ssh_pub_key = File.readlines("./ansible/vagrant.pub").first.strip
      config.vm.provision 'shell', inline: 'mkdir -p /root/.ssh'
      config.vm.provision 'shell', inline: "echo #{ssh_pub_key} >> /root/.ssh/authorized_keys"
      # config.vm.provision 'shell', inline: "echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys", privileged: false

      cpnode.vm.provider :libvirt do |v|
        v.nested  = true
        v.memory  = MEMORY_CONTROL_PLANE_NODE
        v.cpus    = CPUS_CONTROL_PLANE_NODE
      end

      cpnode.vm.provider :virtualbox do |v|
        v.name   = "kcontrolplane#{i}"
        v.memory = MEMORY_CONTROL_PLANE_NODE
        v.cpus   = CPUS_CONTROL_PLANE_NODE
      end

    end

  end

  (1..WORKER_COUNT).each do |i|

    config.vm.define "kworker#{i}" do |workernode|

      workernode.vm.box               = VAGRANT_BOX
      workernode.vm.box_check_update  = false
      workernode.vm.box_version       = VAGRANT_BOX_VERSION
      workernode.vm.hostname          = "kworker#{i}"
      # workernode.disksize.size        = DISK_WORKER_NODE

      workernode.vm.network "private_network", ip: "172.17.17.20#{i}"

      ssh_pub_key = File.readlines("./ansible/vagrant.pub").first.strip
      config.vm.provision 'shell', inline: 'mkdir -p /root/.ssh'
      config.vm.provision 'shell', inline: "echo #{ssh_pub_key} >> /root/.ssh/authorized_keys"
      # config.vm.provision 'shell', inline: "echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys", privileged: false

      workernode.vm.provider :libvirt do |v|
        v.nested  = true
        v.memory  = MEMORY_WORKER_NODE
        v.cpus    = CPUS_WORKER_NODE
      end

      workernode.vm.provider :virtualbox do |v|
        v.name   = "kworker#{i}"
        v.memory = MEMORY_WORKER_NODE
        v.cpus   = CPUS_WORKER_NODE
      end

    end

  end

end
