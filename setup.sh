start_time=$(date)
echo $start_time

. scripts/env_vars.sh

if [ $BADSHELL ];
then
  echo "ERROR - There appears to be a problem with your Cloud Shell setup. Restart of shell necessary"
  exit -1;
fi

scripts/api_enable.sh

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

scripts/create-asm-cluster.sh

scripts/create-cr-cluster.sh


#gcloud components install kpt
kpt_test=$(which kpt)
if [ "$kpt_test" ];
then 
   echo "kpt already installed. Moving on"
else
   echo "kpt being installed."
   sudo apt-get install google-cloud-sdk-kpt -y
fi

jq_test=$(which jq)
if [ "$jq_test" ];
then 
   echo "jq already installed. Moving on"
else
   echo "jq being installed."
   sudo apt-get install jq -y
fi

git config --global user.email $(gcloud config get-value core/account)
git config --global user.name "Qwiklabs Student"

gcloud source repos create hello-bg-app
gcloud source repos clone hello-bg-app ~/hello-bg-app
cp demo-app/* ~/hello-bg-app/.
cd ~/hello-bg-app
git add -A
git commit -a -m "initial commit"
git push

cd ~/asm-cr-handson
rm -rf demo-app

docker pull rippmn/hello-bg-app:1.0
docker tag rippmn/hello-bg-app:1.0 ${GCR_REGION}.gcr.io/${PROJECT_ID}/hello-bg-app:1.0
docker pull rippmn/hello-bg-app:2.0
docker tag rippmn/hello-bg-app:2.0 ${GCR_REGION}.gcr.io/${PROJECT_ID}/hello-bg-app:2.0
docker push ${GCR_REGION}.gcr.io/${PROJECT_ID}/hello-bg-app

gsutil defacl ch -u AllUsers:R gs://${GCR_REGION}.artifacts.${PROJECT_ID}.appspot.com
gsutil acl ch -r -u AllUsers:R gs://${GCR_REGION}.artifacts.${PROJECT_ID}.appspot.com
gsutil acl ch -u AllUsers:R gs://${GCR_REGION}.artifacts.${PROJECT_ID}.appspot.com


cd ~/asm-cr-handson

for cluster in ${CLUSTER_NAME} ${CLUSTER2_NAME};
do
        status=$(gcloud container clusters describe $cluster --zone ${CLUSTER_ZONE} --format='table[no-heading]("status")')
        while [ "$status" != "RUNNING" ];
        do
          status=$(gcloud container clusters describe $cluster --zone ${CLUSTER_ZONE} --format='table[no-heading]("status")')
          echo "still waiting on cluster $cluster start. Current status $status"
          sleep 15
        done
done

scripts/cr-setup.sh
scripts/asm-setup.sh

echo "Script Completed your environment is now ready"

echo "Start:$start_time End:$(date)"
