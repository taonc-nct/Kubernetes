#!/bin/bash
set -euo pipefail

# --- Tham số ---
USER_NAME="demo-user"
GROUP_NAME="dev-group"
NAMESPACES=("dev" "staging" "test")  # ← Danh sách namespace đã tồn tại
CSR_NAME="${USER_NAME}-csr"
VALIDITY_SECONDS=$((365*24*60*60))
KUBECONFIG_FILE="${USER_NAME}-kubeconfig.yaml"
CA_FILE="${USER_NAME}-ca.crt"

# --- Cleanup các file cũ nếu có ---
rm -f ${USER_NAME}.key ${USER_NAME}.csr ${USER_NAME}.crt ${CA_FILE} ${KUBECONFIG_FILE}
kubectl delete csr ${CSR_NAME} --ignore-not-found

# --- Thông tin cluster ---
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}' | tr -d '\n\r')
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' | tr -d '\n\r')

# --- Trích xuất CA từ kubeconfig hiện tại ---
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ${CA_FILE}

# --- Tạo key và CSR ---
openssl genrsa -out ${USER_NAME}.key 2048
openssl req -new -key ${USER_NAME}.key -out ${USER_NAME}.csr -subj "/CN=${USER_NAME}/O=${GROUP_NAME}"
CSR_BASE64=$(base64 -w0 < ${USER_NAME}.csr)

# --- Gửi CSR ---
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  request: ${CSR_BASE64}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: ${VALIDITY_SECONDS}
  usages:
  - client auth
EOF

# --- Approve CSR ---
kubectl certificate approve ${CSR_NAME}

# --- Đợi chứng chỉ được cấp ---
echo "⌛ Chờ certificate được cấp..."
while true; do
  CERT=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')
  if [[ -n "$CERT" ]]; then
    echo "$CERT" | base64 -d > ${USER_NAME}.crt
    break
  fi
  sleep 1
done

# --- Tạo kubeconfig ---
kubectl config --kubeconfig=${KUBECONFIG_FILE} set-cluster ${CLUSTER_NAME} \
  --server=${CLUSTER_SERVER} \
  --certificate-authority=${CA_FILE} \
  --embed-certs=true

kubectl config --kubeconfig=${KUBECONFIG_FILE} set-credentials ${USER_NAME} \
  --client-certificate=${USER_NAME}.crt \
  --client-key=${USER_NAME}.key \
  --embed-certs=true

kubectl config --kubeconfig=${KUBECONFIG_FILE} set-context ${USER_NAME}@${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=${USER_NAME} \
  --namespace=${NAMESPACES[0]}

kubectl config --kubeconfig=${KUBECONFIG_FILE} use-context ${USER_NAME}@${CLUSTER_NAME}

# --- Phân quyền trong từng namespace ---
for NAMESPACE in "${NAMESPACES[@]}"; do
  echo "🔒 Thiết lập RBAC cho user trong namespace: ${NAMESPACE}"
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
done

echo "✅ Đã tạo user '${USER_NAME}' với quyền giới hạn trong các namespace. File kubeconfig: ${KUBECONFIG_FILE}"
