#!/bin/bash

set -e
# 👤 Thông tin người dùng
USER_NAME="taonc3"
USER_GROUP="dev-group"
NAMESPACES=("dev" "staging" "qa")
ROLE_NAME="pod-reader"
CONTEXT_PREFIX="${USER_NAME}"
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CA_CERT="/etc/kubernetes/pki/ca.crt"
CA_KEY="/etc/kubernetes/pki/ca.key"

WORKDIR="./${USER_NAME}"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "🔐 Tạo key và chứng chỉ cho user: ${USER_NAME}"
openssl genrsa -out ${USER_NAME}.key 2048
openssl req -new -key ${USER_NAME}.key -out ${USER_NAME}.csr -subj "/CN=${USER_NAME}/O=${USER_GROUP}"
openssl x509 -req -in ${USER_NAME}.csr -CA ${CA_CERT} -CAkey ${CA_KEY} \
  -CAcreateserial -out ${USER_NAME}.crt -days 365

kubectl config set-credentials ${USER_NAME} \
  --client-certificate=${USER_NAME}.crt \
  --client-key=${USER_NAME}.key \
  --embed-certs=true

for ns in "${NAMESPACES[@]}"; do
  echo "🚧 Đang xử lý namespace: $ns"

  kubectl get ns "$ns" >/dev/null 2>&1 || kubectl create ns "$ns"

  cat <<EOF | kubectl apply -n "$ns" -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${ROLE_NAME}
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
EOF

  cat <<EOF | kubectl apply -n "$ns" -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${USER_NAME}-binding
subjects:
- kind: User
  name: ${USER_NAME}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ${ROLE_NAME}
  apiGroup: rbac.authorization.k8s.io
EOF

  kubectl config set-context ${CONTEXT_PREFIX}-${ns} \
    --cluster=${CLUSTER_NAME} \
    --user=${USER_NAME} \
    --namespace=${ns}
done

echo "Xuất file kubeconfig riêng cho user: ${USER_NAME}"
kubectl config view --minify --flatten --context=${CONTEXT_PREFIX}-${NAMESPACES[0]} > "${USER_NAME}-kubeconfig.yaml"

echo "🎉 Hoàn tất! Sử dụng kubeconfig: ${WORKDIR}/${USER_NAME}-kubeconfig.yaml"
