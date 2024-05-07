ALB will also need to be installed in the EKS cluster:

```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=url-app-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=alb-ingress-controller
```

