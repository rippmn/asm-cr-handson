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
istioVersion="1.9"
mkdir asm_script
cd asm_script

curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_${istioVersion} > install_asm

curl https://storage.googleapis.com/csm-artifacts/asm/install_asm_${istioVersion}.sha256 > install_asm.sha256

verify=$(sha256sum -c --ignore-missing install_asm.sha256)

if [ "$verify" == "install_asm: OK" ];
then
  echo "install script verify. Installing ASM now"
  chmod +x install_asm
  mkdir asm-dist 
  ./install_asm \
  --project_id ${PROJECT_ID} \
  --cluster_name ${CLUSTER_NAME} \
  --cluster_location ${CLUSTER_ZONE} \
  --mode install \
  --output_dir asm-dist \
  --enable_all   

else
 echo "Error verifying asm install script exiting"
 exit
fi

cd asm-dist/istioi-*

#/home/student_00_31279f0a4ea6/asm-cr-handson/asm_script/asm-dist/istio-1.7.3-asm.6
kubectl create namespace bookinfo

rev=$(kubectl -n istio-system get pods -l app=istiod -o jsonpath={.items[0].metadata.labels.'istio\.io/rev'})
kubectl label namespace bookinfo istio.io/rev=${rev} --overwrite
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml -n bookinfo

kubectl wait pod --all --for=condition=ready --namespace bookinfo --timeout 300s
kubectl create namespace load

cd ../../..

export ASMINGRESSIP=$(kubectl get service istio-ingressgateway -n istio-system -o jsonpath={.status.loadBalancer.ingress[0].ip})
sed "s/INGRESSIP/${ASMINGRESSIP}/g" bookinfo-load-job.yaml | kubectl apply -f -

echo "ASM setup completed"
