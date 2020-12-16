#cloud run cluster workload setup
rm ~/.kube/config

gcloud container clusters get-credentials ${CLUSTER2_NAME} --zone ${CR_CLUSTER_ZONE}
cp ~/.kube/config ~/.kube/cloudrun
NAMESPACE=default 

ingress_ip=""
echo "waiting for ingress to be completed"
while [[ ! $ingress_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];
do
  sleep 2
  ingress_ip=$(kubectl get service istio-ingress -n gke-system -o jsonpath={.status.loadBalancer.ingress[0].ip} --kubeconfig ~/.kube/cloudrun)
done

domainCheck=$(kubectl get configmap config-domain -n knative-serving -o json | jq -r '.data | keys[0]')

sleep 2
echo "updating default domain to $ingress_ip.xip.io"
while [ ! "$domainCheck" == "${ingress_ip}.xip.io" ];
do
  sleep 2
  kubectl patch configmap config-domain --kubeconfig ~/.kube/cloudrun --namespace knative-serving --patch \
    '{"data": {"example.com": null, "'${ingress_ip}'.xip.io": ""}}'
  domainCheck=$(kubectl get configmap config-domain -n knative-serving -o json | jq -r '.data | keys[0]')
done
#gcloud beta run deploy hello-load-app --namespace default --image  gcr.io/${PROJECT_ID}/load-app:1.0 \
gcloud beta run deploy hello-load-app --namespace default --image  rippmn/hello-bg-app:0.1 \
--max-instances 3 --platform gke --cluster=${CLUSTER2_NAME} --cluster-location=${CR_CLUSTER_ZONE} --concurrency=40
#--service-account cloud-run-sa
kubectl create namespace load
sed "s/INGRESS_IP/$ingress_ip/g" hello-app-load-job.yaml | kubectl apply --kubeconfig ~/.kube/cloudrun -f -
#end of cloud run stuff
echo "Cloud Run setup completed"
