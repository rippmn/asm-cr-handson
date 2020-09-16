project=$(gcloud projects list --filter name='qwiklabs-gcp*' --format='table[no-heading]("PROJECT_ID")')

if [ ! $project ];
then
  echo "ERROR - There appears to be a problem with your Cloud Shell setup. Restart of shell necessary."
  export BADSHELL=TRUE
  exit
fi


gcloud config set project $project 

zone=$(cut -d'/' -f4 <<< $(curl metadata/computeMetadata/v1/instance/zone))

if [[ "$zone" == *"central"* ]]; then
  echo "It's there."
fi

#find zone
zone=$(cut -d'/' -f4 <<< $(curl metadata/computeMetadata/v1/instance/zone))

c_zone="us-central1-f"

if [[ "$zone" == *"europe"* ]]; then
  c_zone="europe-west3-b";
elif [[ "$zone" == *"asia"* ]]; then
  c_zone="asia-south1-b";

fi

export PROJECT_ID=$(gcloud config get-value project)
export ENVIRON_PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")
export CLUSTER_NAME=anthos-mesh-cluster
export CLUSTER_ZONE=${c_zone}
export CLUSTER2_NAME=cloud-run-cluster
#export CR_CLUSTER_ZONE=us-west4-c
export CR_CLUSTER_ZONE=${c_zone}
export WORKLOAD_POOL=${PROJECT_ID}.svc.id.goog
export MESH_ID="proj-${ENVIRON_PROJECT_NUMBER}"

