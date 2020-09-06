project=$(gcloud projects list --filter name='qwiklabs-gcp*' --format='table[no-heading]("PROJECT_ID")')
date
gcloud config set project $project 

gcloud services enable \
    container.googleapis.com \
    compute.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com \
    cloudtrace.googleapis.com \
    meshca.googleapis.com \
    meshtelemetry.googleapis.com \
    meshconfig.googleapis.com \
    anthos.googleapis.com \
    iamcredentials.googleapis.com \
    gkeconnect.googleapis.com \
    gkehub.googleapis.com \
    sourcerepo.googleapis.com \
    cloudbuild.googleapis.com \
    cloudresourcemanager.googleapis.com
    
export PROJECT_ID=$(gcloud config get-value project)
export ENVIRON_PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")
export CLUSTER_NAME=anthos-mesh-cluster
export CLUSTER_ZONE=us-central1-f
export CLUSTER2_NAME=cloud-run-cluster
export CR_CLUSTER_ZONE=us-west4-c
export WORKLOAD_POOL=${PROJECT_ID}.svc.id.goog
export MESH_ID="proj-${ENVIRON_PROJECT_NUMBER}"

ownerTest=$(gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:user:$(gcloud config get-value core/account 2>/dev/null)" | grep roles/owner)
echo $ownerTest
if [ "$ownerTest" ];
then 
   echo "good"
else
   echo "role owner required"
   exit
fi

gcloud config set compute/zone ${CLUSTER_ZONE}
gcloud beta container clusters create ${CLUSTER_NAME} \
    --release-channel=regular \
    --machine-type=e2-standard-4 \
    --num-nodes=4 \
    --workload-pool=${WORKLOAD_POOL} \
    --enable-stackdriver-kubernetes \
    --subnetwork=default \
    --labels mesh_id=${MESH_ID} -q --verbosity none & 

sleep 10

gcloud beta container clusters create ${CLUSTER2_NAME} \
    --zone ${CR_CLUSTER_ZONE} \
    --release-channel=regular \
    --machine-type=n1-standard-2 \
    --num-nodes=3 \
    --enable-stackdriver-kubernetes \
    --subnetwork=default \
    --addons=HttpLoadBalancing,CloudRun -q --verbosity none &

sleep 10
#gcloud components install kpt
sudo apt-get install google-cloud-sdk-kpt -y

###INSERT WAIT HERE
clusters=( ${CLUSTER_NAME} ${CLUSTER2_NAME} )
#waiting 30 seconds to be sure the clusters are availble to query
echo "waiting on clusters to create"
sleep 30
status="none"

while [ "$status" != "RUNNING" ];
do
  status=$(gcloud container clusters describe ${CLUSTER_NAME} --zone ${CLUSTER_ZONE} --format='table[no-heading]("status")')
  echo "still waiting on cluster ${CLUSTER_NAME} start. Current status $status"
  sleep 15
done
status="none"
while [ "$status" != "RUNNING" ];
do
  status=$(gcloud container clusters describe ${CLUSTER2_NAME} --zone ${CR_CLUSTER_ZONE} --format='table[no-heading]("status")')
  echo "still waiting on cluster ${CLUSTER2_NAME} start. Current status $status"
  sleep 15
done

##THEN DLETE KUBE CONFIG
rm ~/.kube/config

##DO CLOUD RUN STUFF
#gcloud iam service-accounts create metrics-cr-sa

#gcloud projects add-iam-policy-binding ${PROJECT_ID} \
# --member="serviceAccount:metrics-cr-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
# --role="roles/monitoring.metricWriter"

#cloud run cluster workload setup
gcloud container clusters get-credentials ${CLUSTER2_NAME} --zone ${CR_CLUSTER_ZONE}
NAMESPACE=default 

docker pull rippmn/hello-bg-app:1.0
docker pull rippmn/hello-bg-app:2.0
docker pull rippmn/hello-bg-app:0.1
docker tag rippmn/hello-bg-app:1.0 gcr.io/${PROJECT_ID}/hello-bg-app:1.0
docker tag rippmn/hello-bg-app:2.0 gcr.io/${PROJECT_ID}/hello-bg-app:2.0
docker tag rippmn/hello-bg-app:0.1 gcr.io/${PROJECT_ID}/hello-bg-app:0.1
docker push gcr.io/${PROJECT_ID}/hello-bg-app:1.0
docker push gcr.io/${PROJECT_ID}/hello-bg-app:2.0
docker push gcr.io/${PROJECT_ID}/hello-bg-app:0.1

git config --global user.email $(gcloud config get-value core/account)
git config --global user.name "Qwiklabs Student"


gcloud source repos create hello-bg-app
gcloud source repos clone hello-bg-app ~/hello-bg-app
cp hello-bg-app/* ~/hello-bg-app/.
cd ~/hello-bg-app
git add -A
git commit -a -m "initial commit"
git push

cd ~/asm-cr-handson


#kubectl create serviceaccount --namespace ${NAMESPACE} cloud-run-sa

#gcloud iam service-accounts add-iam-policy-binding \
#--role roles/iam.workloadIdentityUser \
#--member "serviceAccount:${PROJECT_ID}.svc.id.goog[${NAMESPACE}/cloud-run-sa]" \
#metrics-cr-sa@${PROJECT_ID}.iam.gserviceaccount.com

#kubectl annotate serviceaccount \
#--namespace ${NAMESPACE} \
# cloud-run-sa \
# iam.gke.io/gcp-service-account=metrics-cr-sa@${PROJECT_ID}.iam.gserviceaccount.com

ingress_ip=""
while [ ! $ingress_ip ];
do
  sleep 2
  ingress_ip=$(kubectl get service istio-ingress -n gke-system -o jsonpath={.status.loadBalancer.ingress[0].ip})
done

configExists=$(kubectl get configmap config-domain -n knative-serving)
sleep 2
while [ ! $configExists ];
do
  sleep 2
  configExists=$(kubectl get configmap config-domain -n knative-serving)
done

kubectl patch configmap config-domain --namespace knative-serving --patch \
  '{"data": {"example.com": null, "'${ingress_ip}'.xip.io": ""}}'
gcloud beta run deploy hello-load-app --namespace default --image  gcr.io/${PROJECT_ID}/hello-bg-app:0.1 \
--max-instances 3 --platform gke --cluster=${CLUSTER2_NAME} --cluster-location=${CR_CLUSTER_ZONE} --concurrency=40
#--service-account cloud-run-sa
kubectl create namespace load
sed "s/INGRESS_IP/$ingress_ip/g" hello-app-load-job.yaml | kubectl apply -f -
#end of cloud run stuff
##THEN DELETE KUBECOFIG
sleep 10
rm ~/.kube/config
##THEN DO ASM

gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${CLUSTER_ZONE}

#make sure user is admin
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user="$(gcloud config get-value core/account)"



curl --request POST \
  --header "Authorization: Bearer $(gcloud auth print-access-token)" \
  --data '' \
  "https://meshconfig.googleapis.com/v1alpha1/projects/${PROJECT_ID}:initialize"


gcloud iam service-accounts create connect-sa

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
 --member="serviceAccount:connect-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
 --role="roles/gkehub.connect"

gcloud iam service-accounts keys create connect-sa-key.json \
  --iam-account=connect-sa@${PROJECT_ID}.iam.gserviceaccount.com

gcloud container hub memberships register ${CLUSTER_NAME}-connect \
   --gke-cluster=${CLUSTER_ZONE}/${CLUSTER_NAME}  \
   --service-account-key-file=./connect-sa-key.json

#check that connect registraion finished 
meshcheck=$(gcloud projects get-iam-policy ${PROJECT_ID} | grep -B 1 'roles/meshdataplane.serviceAgent')
if [ "$meshcheck" ];
then
 echo "$meshcheck"
else
 echo "Error"
 exit
fi
####
istioVersion="istio-1.6.8-asm.9"

curl -LO https://storage.googleapis.com/gke-release/asm/${istioVersion}-linux-amd64.tar.gz

curl -LO https://storage.googleapis.com/gke-release/asm/${istioVersion}-linux-amd64.tar.gz.1.sig

cat <<'EOF' > pk
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEWZrGCUaJJr1H8a36sG4UUoXvlXvZ
wQfk16sxprI2gOJ2vFFggdq3ixF2h4qNBt0kI7ciDhgpwS8t+/960IsIgw==
-----END PUBLIC KEY-----
EOF

verify=$(openssl dgst -verify pk -signature ${istioVersion}-linux-amd64.tar.gz.1.sig ${istioVersion}-linux-amd64.tar.gz)

echo $verify

if [ "$verify" ];
then
 rm pk
 rm ${istioVersion}-linux-amd64.tar.gz.1.sig
else
 echo "Error"
 exit
fi

tar xzf ${istioVersion}-linux-amd64.tar.gz
rm ${istioVersion}-linux-amd64.tar.gz

cd ${istioVersion}
export PATH=$PWD/bin:$PATH

cd ..
mkdir asm-install
cd asm-install

kpt pkg get \
https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm@release-1.6-asm .

kpt cfg set asm gcloud.container.cluster ${CLUSTER_NAME}

kpt cfg set asm gcloud.core.project ${PROJECT_ID}

kpt cfg set asm gcloud.project.environProjectNumber ${ENVIRON_PROJECT_NUMBER}

kpt cfg set asm gcloud.compute.location ${CLUSTER_ZONE}

kpt cfg set asm anthos.servicemesh.profile asm-gcp

istioctl install -f asm/cluster/istio-operator.yaml

kubectl apply -f asm/canonical-service/controller.yaml

cd ..

kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled --overwrite
kubectl apply -f istio-1.6.8-asm.9/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
kubectl apply -f istio-1.6.8-asm.9/samples/bookinfo/networking/bookinfo-gateway.yaml -n bookinfo
kubectl wait pod --all --for=condition=ready --namespace bookinfo --timeout 90s
kubectl create namespace load
export INGRESSIP=$(kubectl get service istio-ingressgateway -n istio-system -o jsonpath={.status.loadBalancer.ingress[0].ip})
sed "s/INGRESSIP/${INGRESSIP}/g" bookinfo-load-job.yaml | kubectl apply -f -
date
