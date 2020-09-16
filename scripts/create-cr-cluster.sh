gcloud beta container clusters create ${CLUSTER2_NAME} \
    --zone ${CR_CLUSTER_ZONE} \
    --release-channel=regular \
    --machine-type=e2-standard-2 \
    --num-nodes=3 \
    --enable-stackdriver-kubernetes \
    --subnetwork=default \
    --scopes cloud-platform \
    --addons=HttpLoadBalancing,CloudRun -q --verbosity none &
