##THEN DLETE KUBE CONFIG
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
istioVersion="istio-1.6.11-asm.1"
asmKptReleaseTag="release-1.6-asm"

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
https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm@${asmKptReleaseTag} asm

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
kubectl apply -f ${istioVersion}/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
kubectl apply -f ${istioVersion}/samples/bookinfo/networking/bookinfo-gateway.yaml -n bookinfo

kubectl wait pod --all --for=condition=ready --namespace bookinfo --timeout 300s
kubectl create namespace load
export ASMINGRESSIP=$(kubectl get service istio-ingressgateway -n istio-system -o jsonpath={.status.loadBalancer.ingress[0].ip})
sed "s/INGRESSIP/${ASMINGRESSIP}/g" bookinfo-load-job.yaml | kubectl apply -f -

echo "ASM setup completed"
