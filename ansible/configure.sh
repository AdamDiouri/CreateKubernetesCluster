sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version=1.25.5
echo "##################################################"
mkdir -p $HOME/.kube
echo "##################################################"
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
echo "##################################################"
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "##################################################"
echo "export KUBECONFIG=/home/ubuntu/.kube/config" >> /home/ubuntu/.bashrc
echo "##################################################"
source ~/.bashrc
echo "##################################################"
kubectl get nodes >> $HOME/isitrunning.txt
echo "##################################################"
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml >> pod_network.txt
echo "##################################################"
kubeadm token create --print-join-command >> token.sh
echo "##################################################"