/var/lib/rancher/rke2/server/token
INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts sh install.sh

systemctl enable rke2-server.service
systemctl start rke2-server.service

curl -kv https://192.168.94.143:9345/cacerts
curl -vk https://192.168.94.143:9345:6443/healthz

/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes

rke2-uninstall.sh



# RKE2 commands

* Updated on May 29 to accommodate etcd container not having `/bin/sh` available anymore.

## Install

```
curl -sL https://get.rke2.io | sh
systemctl daemon-reload
systemctl start rke2-server
```

More options to define RKE2 version

```
# Stable channel
# curl https://update.rke2.io/v1-release/channels/stable
curl -sL https://get.rke2.io | INSTALL_RKE2_CHANNEL=stable sh
# Latest channel
# curl https://update.rke2.io/v1-release/channels/latest
curl -sL https://get.rke2.io | INSTALL_RKE2_CHANNEL=latest sh
# Testing channel
# curl https://update.rke2.io/v1-release/channels/testing
curl -sL https://get.rke2.io | INSTALL_RKE2_CHANNEL=testing sh
# Minor channel for latest available patch version
# curl https://update.rke2.io/v1-release/channels/v1.27
curl -sL https://get.rke2.io | INSTALL_RKE2_CHANNEL=v1.27 sh
# Minor channel for latest available patch version
# curl https://update.rke2.io/v1-release/channels/v1.26
curl -sL https://get.rke2.io | INSTALL_RKE2_CHANNEL=v1.26 sh
# Configure specific version
curl -sL https://get.rke2.io | INSTALL_RKE2_VERSION=v1.27.5+rke2r1 sh
```

Various exploration/debug commmands for RKE2

## binaries

```
$ ls -1 /var/lib/rancher/rke2/bin/*
/var/lib/rancher/rke2/bin/containerd
/var/lib/rancher/rke2/bin/containerd-shim
/var/lib/rancher/rke2/bin/containerd-shim-runc-v1
/var/lib/rancher/rke2/bin/containerd-shim-runc-v2
/var/lib/rancher/rke2/bin/crictl
/var/lib/rancher/rke2/bin/ctr
/var/lib/rancher/rke2/bin/kubectl
/var/lib/rancher/rke2/bin/kubelet
/var/lib/rancher/rke2/bin/runc
```

## tar.gz contents

```
lib/
lib/systemd/
lib/systemd/system/
lib/systemd/system/rke2-agent.service
lib/systemd/system/rke2-agent.env
lib/systemd/system/rke2-server.service
lib/systemd/system/rke2-server.env
share/
share/rke2/
share/rke2/rke2-cis-sysctl.conf
share/rke2/LICENSE.txt
share/rke2-windows/
bin/
bin/rke2.exe
bin/rke2
bin/rke2-uninstall.ps1
bin/rke2-uninstall.sh
bin/rke2-killall.sh
```

## systemd

* `/usr/local/lib/systemd/system/rke2-server.service`
* `/usr/local/lib/systemd/system/rke2-agent.service`

## kubeconfig

```
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
/var/lib/rancher/rke2/bin/kubectl get nodes
```

```
/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes
```

## containerd

* socket located at `/run/k3s/containerd/containerd.sock`

### ctr

List containers using ctr

```
/var/lib/rancher/rke2/bin/ctr --address /run/k3s/containerd/containerd.sock --namespace k8s.io container ls
```

### crictl

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
/var/lib/rancher/rke2/bin/crictl ps
```

```
/var/lib/rancher/rke2/bin/crictl --config /var/lib/rancher/rke2/agent/etc/crictl.yaml ps
```

```
/var/lib/rancher/rke2/bin/crictl --runtime-endpoint unix:///run/k3s/containerd/containerd.sock ps -a
```

## logging

* `journalctl -f -u rke2-server`
* `/var/lib/rancher/rke2/agent/containerd/containerd.log`
* `/var/lib/rancher/rke2/agent/logs/kubelet.log`

## etcd

### using kubectl

* `etcdctl check perf`

```
for etcdpod in $(kubectl -n kube-system get pod -l component=etcd --no-headers -o custom-columns=NAME:.metadata.name); do kubectl -n kube-system exec $etcdpod -- etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt check perf; done
```

* `etcdctl endpoint status`

```
for etcdpod in $(kubectl -n kube-system get pod -l component=etcd --no-headers -o custom-columns=NAME:.metadata.name); do kubectl -n kube-system exec $etcdpod -- etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt endpoint status; done
```

* `etcdctl endpoint health`

```
for etcdpod in $(kubectl -n kube-system get pod -l component=etcd --no-headers -o custom-columns=NAME:.metadata.name); do kubectl -n kube-system exec $etcdpod -- etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt endpoint health; done
```

* `etcdctl alarm list`


```
for etcdpod in $(kubectl -n kube-system get pod -l component=etcd --no-headers -o custom-columns=NAME:.metadata.name); do kubectl -n kube-system exec $etcdpod -- etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt alarm list; done
```

* `etcdctl compact`

```
rev=$(kubectl -n kube-system exec $(kubectl -n kube-system get pod -l component=etcd --no-headers -o custom-columns=NAME:.metadata.name | head -1) -- etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt endpoint status --write-out fields | grep Revision | cut -d: -f2)
kubectl -n kube-system exec $(kubectl -n kube-system get pod -l component=etcd --no-headers -o custom-columns=NAME:.metadata.name | head -1) -- etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt compact \"$(echo $rev)\"
```

* `etcdctl defrag`

```
kubectl -n kube-system exec $(kubectl -n kube-system get pod -l component=etcd --no-headers -o custom-columns=NAME:.metadata.name | head -1) -- etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt defrag --cluster
```

* curl metrics

Older versions of the etcd image have a version of curl in the image that does not work with EC certificate keys.

Since k8s 1.28, `curl` is no longer present in the image

```
kubectl -n kube-system exec $(kubectl -n kube-system get pod -l component=etcd --no-headers -o custom-columns=NAME:.metadata.name | head -1) -- curl -L --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key -s https://127.0.0.1:2379/metrics
```
* curl health

```
kubectl -n kube-system exec $(kubectl -n kube-system get pod -l component=etcd --no-headers -o custom-columns=NAME:.metadata.name | head -1) -- curl -L --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key -s https://127.0.0.1:2379/health
```

### on the etcd host itself

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
```

* `etcdctl check perf`

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt check perf
```

* `etcdctl endpoint status`

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt endpoint status --cluster --write-out=table
```

* `etcdctl endpoint health`

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt endpoint health --cluster --write-out=table
```

* `etcdctl alarm list`

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt alarm list
```

* `etcdctl compact`

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
rev=$(/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt endpoint status --write-out fields | grep Revision | cut -d: -f2)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt compact $rev
```

* `etcdctl defrag`

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt defrag --cluster
```

* curl metrics

```
curl -L --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key https://127.0.0.1:2379/metrics
```

* curl health

```
curl -L --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key https://127.0.0.1:2379/health
```

* Check etcd connectivity between members on HTTP/2379

```
for endpoint in $(/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt member list |cut -d, -f5); do    echo "Validating connection to ${endpoint}/health";    curl -L --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key "${endpoint}/health";   echo ""; done
```

* Watching etcd changes

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt watch --prefix /registry
```

* Query etcd directly

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt get /registry --prefix=true --keys-only
```

* etcd list of count per key

```
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
etcdcontainer=$(/var/lib/rancher/rke2/bin/crictl ps --label io.kubernetes.container.name=etcd --quiet)
/var/lib/rancher/rke2/bin/crictl exec $etcdcontainer etcdctl --cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt --key /var/lib/rancher/rke2/server/tls/etcd/server-client.key --cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt get /registry --prefix=true --keys-only | grep -v ^$ | awk -F'/' '{ if ($3 ~ /cattle.io/) {h[$3"/"$4]++} else { h[$3]++ }} END { for(k in h) print h[k], k }' | sort -nr
```
