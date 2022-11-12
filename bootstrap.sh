#!/bin/bash


# Set Root password
echo "Set root password"
echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1

