argocd app delete url-app --cascade

kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

helm delete aws-load-balancer-controller -n kube-system

helm template deployment/eks/helm/alb | kubectl delete -f -

cd deployment/eks/terraform || exit 1
terraform destroy -auto-approve

# Return to the original directory
cd - >/dev/null || exit 1
