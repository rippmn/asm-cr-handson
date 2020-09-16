date
. scripts/env_vars.sh

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

sleep 10

scripts/create-cr-cluster.sh

sleep 10


#gcloud components install kpt
sudo apt-get install google-cloud-sdk-kpt -y

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

docker pull rippmn/hello-bg-app:1.0
docker tag rippmn/hello-bg-app:1.0 gcr.io/${PROJECT_ID}/hello-bg-app:1.0
docker push gcr.io/${PROJECT_ID}/hello-bg-app:1.0
docker pull rippmn/hello-bg-app:2.0
docker tag rippmn/hello-bg-app:2.0 gcr.io/${PROJECT_ID}/hello-bg-app:2.0
docker push gcr.io/${PROJECT_ID}/hello-bg-app:2.0

cd ~/asm-cr-handson

scripts/cr-setup.sh
scripts/asm-setup.sh

echo "Script Completed your environment is now ready"

date
