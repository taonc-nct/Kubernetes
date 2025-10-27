# Kubernetes Manifests for Jenkins Deployment

Refer https://devopscube.com/setup-jenkins-on-kubernetes-cluster/ for step by step process to use these manifests.
# Set up cluster
Change PV, PVC.

# Take password Jenkins
kubectl exec -it <jenkins-pod-name> -- bash
cat /var/jenkins_home/secrets/initialAdminPassword

# Copy plugins pod -> local
kubectl cp devops-tools/jenkins-58c85cb467-fm6xf:/var/jenkins_home/plugins .\jenkins-plugins

# DNS 
http://jenkins-service.devops-tools.svc.cluster.local:8080

# ERROR
Agent timeout can't connect to agent controller