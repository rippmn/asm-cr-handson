isCloudRunCluster=$(gcloud container clusters list --filter name="${CLUSTER2_NAME}" --format='table[no-heading]("NAME")')

if [ isCloudRunCluster ]; then
        echo "cluster ${CLUSTER2_NAME} already provsioned skipping create"
        exit;
fi

gcloud beta container clusters create ${CLUSTER2_NAME} \
    --zone ${CR_CLUSTER_ZONE} \
    --release-channel=regular \
    --machine-type=e2-standard-2 \
    --num-nodes=3 \
    --enable-stackdriver-kubernetes \
    --subnetwork=default \
    --scopes cloud-platform \
    --addons=HttpLoadBalancing,CloudRun -q --verbosity none &
