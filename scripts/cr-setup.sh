###INSERT WAIT HERE
#waiting 30 seconds to be sure the clusters are availble to query
sleep 30
status="none"

while [ "$status" != "RUNNING" ];
do
  status=$(gcloud container clusters describe ${CLUSTER2_NAME} --zone ${CR_CLUSTER_ZONE} --format='table[no-heading]("status")')
  echo "still waiting on cluster ${CLUSTER2_NAME} start. Current status $status"
  sleep 15
done

#cloud run cluster workload setup
rm ~/.kube/config

gcloud container clusters get-credentials ${CLUSTER2_NAME} --zone ${CR_CLUSTER_ZONE}
cp ~/.kube/config ~/.kube/cloudrun
NAMESPACE=default 

ingress_ip=""
while [ ! $ingress_ip ];
do
  sleep 2
  ingress_ip=$(kubectl get service istio-ingress -n gke-system -o jsonpath={.status.loadBalancer.ingress[0].ip})
done

configExists=$(kubectl get configmap config-domain -n knative-serving -o jsonpath={.metadata.name})
sleep 2
while [ ! $configExists ];
do
  sleep 2
  configExists=$(kubectl get configmap config-domain -n knative-serving -o jsonpath={.metadata.name})
done

kubectl patch configmap config-domain --namespace knative-serving --patch \
  '{"data": {"example.com": null, "'${ingress_ip}'.xip.io": ""}}'
gcloud beta run deploy hello-load-app --namespace default --image  rippmn/hello-bg-app:0.1 \
--max-instances 3 --platform gke --cluster=${CLUSTER2_NAME} --cluster-location=${CR_CLUSTER_ZONE} --concurrency=40
#--service-account cloud-run-sa
kubectl create namespace load
sed "s/INGRESS_IP/$ingress_ip/g" hello-app-load-job.yaml | kubectl apply --kubeconfig ~/.kube/cloudrun -f -
#end of cloud run stuff
echo "Cloud Run setup completed"
