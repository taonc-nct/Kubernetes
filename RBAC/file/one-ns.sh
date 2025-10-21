#!/bin/bash
set -euo pipefail

# --- Tham số ---
USER_NAME="taonc"
GROUP_NAME="dev"
NAMESPACE="demo-namespace"
VALIDITY_DAYS=365
KUBECONFIG_FILE="${USER_NAME}-kubeconfig.yaml"

# --- Thông tin cluster ---
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_CERT="/etc/kubernetes/pki/ca.crt"
CA_KEY="/etc/kubernetes/pki/ca.key"

# --- Kiểm tra quyền truy cập CA ---
if [[ ! -f "$CA_KEY" ]]; then
  echo "❌ Không tìm thấy file $CA_KEY. Phải chạy script này trên control-plane có CA."
  exit 1
fi

# --- Tạo key và cert ---
openssl genrsa -out ${USER_NAME}.key 2048
openssl req -new -key ${USER_NAME}.key -out ${USER_NAME}.csr -subj "/CN=${USER_NAME}/O=${GROUP_NAME}"
openssl x509 -req -in ${USER_NAME}.csr -CA ${CA_CERT} -CAkey ${CA_KEY} \
  -CAcreateserial -out ${USER_NAME}.crt -days ${VALIDITY_DAYS} -sha256

# --- Tạo kubeconfig riêng ---
kubectl config --kubeconfig=${KUBECONFIG_FILE} set-cluster ${CLUSTER_NAME} \
  --server=${CLUSTER_SERVER} \
  --certificate-authority=${CA_CERT} \
  --embed-certs=true

kubectl config --kubeconfig=${KUBECONFIG_FILE} set-credentials ${USER_NAME} \
  --client-certificate=${USER_NAME}.crt \
  --client-key=${USER_NAME}.key \
  --embed-certs=true

kubectl config --kubeconfig=${KUBECONFIG_FILE} set-context ${USER_NAME}@${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=${USER_NAME} \
  --namespace=${NAMESPACE}

kubectl config --kubeconfig=${KUBECONFIG_FILE} use-context ${USER_NAME}@${CLUSTER_NAME}

# --- Tạo namespace nếu chưa có ---
kubectl get ns ${NAMESPACE} >/dev/null 2>&1 || kubectl create ns ${NAMESPACE}

# --- Tạo Role + RoleBinding ---
kubectl apply -n ${NAMESPACE} -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${USER_NAME}-rb
subjects:
- kind: User
  name: ${USER_NAME}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF

echo "✅ User '${USER_NAME}' đã được tạo và lưu kubeconfig tại: ${KUBECONFIG_FILE}"
