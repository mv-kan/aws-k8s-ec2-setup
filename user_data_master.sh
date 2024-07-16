#!/bin/bash -xe

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
hostnamectl set-hostname master-node-0
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet

apt-get update -y
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt install -y containerd.io
systemctl enable --now containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd

swapoff -a  
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

sysctl --system

kubeadm config images pull

NODENAME="master-node-0"
POD_CIDR="172.16.0.0/12"
MASTER_PRIVATE_IP=$(hostname -I | awk '{print $1}')
kubeadm init \
 --apiserver-advertise-address="$MASTER_PRIVATE_IP" \
 --apiserver-cert-extra-sans="$MASTER_PRIVATE_IP" \
 --pod-network-cidr="$POD_CIDR" \
 --node-name "$NODENAME" \
 --ignore-preflight-errors=Mem

mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown "$(id -u)":"$(id -g)" /root/.kube/config

apt install -y git 
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml