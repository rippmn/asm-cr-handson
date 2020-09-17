project=$(gcloud projects list --filter name='qwiklabs-gcp*' --format='table[no-heading]("PROJECT_ID")')

if [ ! $project ];
then
  echo "ERROR - There appears to be a problem with your Cloud Shell setup. Restart of shell necessary."
  export BADSHELL=TRUE
  exit
fi


gcloud config set project $project 

#find zone
zone=$(cut -d'/' -f4 <<< $(curl metadata/computeMetadata/v1/instance/zone))

c_zone="us-central1-f"
gcr_region="us"

if [[ "$zone" == *"europe"* ]]; then
  c_zone="europe-west3-b";
  gcr_region="eu"
elif [[ "$zone" == *"asia"* ]]; then
  c_zone="asia-southeast1-a";
  gcr_region="asia"

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
export GCR_REGION=$gcr_region

