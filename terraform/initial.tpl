#!/bin/env bash

sudo hostnamectl set-hostname $hostname
sudo hostnamectl set-hostname $hostname --pretty
echo "${hostname}" > /etc/hostname

# Update the /etc/hosts in each instance
echo "127.0.0.1 localhost" | sudo tee /etc/hosts
echo "${controller_ip} controller" | sudo tee -a /etc/hosts
echo "${worker1_ip} worker1" | sudo tee -a /etc/hosts
echo "${worker2_ip} worker2" | sudo tee -a /etc/hosts


# Install and configure containerd
cat << EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat << EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo apt update && sudo apt -y install containerd

sudo mkdir -p /etc/containerd

sudo containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd

sudo swapoff -a 

sudo apt update && sudo apt -y install apt-transport-https curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt update

sudo apt -y install kubelet=1.24.0-00 kubeadm=1.24.0-00 kubectl=1.24.0-00

sudo apt-mark hold kubelet kubeadm kubectl # Just to make sure that these packages do not get upgraded

host = $(hostname)

if [[ $hostname == "controller" ]] || [[ $host == "ip-10-0-1-50" ]]
then
    sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version=1.24.0
    sudo mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl get nodes >> $HOME/isitrunning.txt
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    kubeadm token create --print-join-command >> token.sh
else
    touch $HOME/else.txt
    echo "else clause" > $HOME/else.txt
fi