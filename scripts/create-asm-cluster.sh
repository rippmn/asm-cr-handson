gcloud beta container clusters create ${CLUSTER_NAME} \
    --release-channel=regular \
    --machine-type=e2-standard-4 \
    --num-nodes=4 \
    --workload-pool=${WORKLOAD_POOL} \
    --enable-stackdriver-kubernetes \
    --subnetwork=default \
    --scopes cloud-platform \
    --labels mesh_id=${MESH_ID} -q --verbosity none & 
