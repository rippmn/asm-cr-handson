##THEN DLETE KUBE CONFIG
rm ~/.kube/config

##THEN DO ASM

gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${CLUSTER_ZONE}

asmVersion="1.11"
mkdir asm_script
cd asm_script

curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_${asmVersion} > asmcli

chmod +x asmcli

./asmcli install \
-p ${PROJECT_ID} \
-l ${CLUSTER_ZONE} \
-n ${CLUSTER_NAME} \
--fleet_id ${PROJECT_ID} \
--managed \
--verbose \
--output_dir ${CLUSTER_NAME} \
--enable-all

rev=asm-managed-rapid

kubectl create namespace asm-gateway

kubectl label namespace asm-gateway istio-injection- istio.io/rev=${rev} --overwrite

###INSTALL GATEWAY
kubectl apply -n asm-gateway -f ${CLUSTER_NAME}/samples/gateways/istio-ingressgateway

#####

#cd asm-dist/istio-*

#/home/student_00_31279f0a4ea6/asm-cr-handson/asm_script/asm-dist/istio-1.7.3-asm.6
#
#rev=$(kubectl -n istio-system get pods -l app=istiod -o jsonpath={.items[0].metadata.labels.'istio\.io/rev'})
#kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
#kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml -n bookinfo

#kubectl wait pod --all --for=condition=ready --namespace bookinfo --timeout 300s
#kubectl create namespace load

#cd ../../..

#export ASMINGRESSIP=$(kubectl get service istio-ingressgateway -n istio-system -o jsonpath={.status.loadBalancer.ingress[0].ip})
#sed "s/INGRESSIP/${ASMINGRESSIP}/g" bookinfo-load-job.yaml | kubectl apply -f -

#echo "ASM setup completed"

###


kubectl create namespace bookinfo
kubectl label namespace bookinfo istio.io/rev=${rev} --overwrite

cd ${CLUSTER_NAME}/istio-*

#/home/student_00_31279f0a4ea6/asm-cr-handson/asm_script/asm-dist/istio-1.7.3-asm.6
#
#rev=$(kubectl -n istio-system get pods -l app=istiod -o jsonpath={.items[0].metadata.labels.'istio\.io/rev'})
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml -n bookinfo

kubectl wait pod --all --for=condition=ready --namespace bookinfo --timeout 300s
kubectl create namespace load

cd ../../..

export ASMINGRESSIP=$(kubectl get service istio-ingressgateway -n istio-system -o jsonpath={.status.loadBalancer.ingress[0].ip})
sed "s/INGRESSIP/${ASMINGRESSIP}/g" bookinfo-load-job.yaml | kubectl apply -f -

echo "ASM setup completed"
