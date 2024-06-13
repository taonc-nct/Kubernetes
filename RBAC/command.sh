openssl genrsa -out "private.key" 2048
openssl req -new -key "private.key" -out "private.csr" -subj /CN=taonc/O=dev
cat "private.csr" | base64 | tr -d '\n'
kubectl get crs taonc -o yaml
kubectl get crs
kubectl certificate approve taonc
kubectl get csr taonc -o yaml | yq e '.status.certificate'


kubectl get csr taonc -o jsonpath='{.status.certificate}'| base64 -d > myuser.crt