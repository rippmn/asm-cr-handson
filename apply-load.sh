ingress_ip=$(kubectl get service istio-ingress -n gke-system -o jsonpath={.status.loadBalancer.ingress[0].ip} --kubeconfig ~/.kube/cloudrun) 
sed "s/INGRESS_IP/$ingress_ip/g" hello-app-more-load-job.yaml | kubectl apply --kubeconfig ~/.kube/cloudrun -f -

