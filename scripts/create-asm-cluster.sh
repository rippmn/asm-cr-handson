isASMCluster=$(gcloud container clusters list --filter name="${CLUSTER_NAME}" --format='table[no-heading]("NAME")')

if [ isASMCluster ]; then
	echo "cluster exists already skipping create"
        exit;
fi

gcloud beta container clusters create ${CLUSTER_NAME} \
    --zone ${CLUSTER_ZONE} \
    --release-channel=regular \
    --machine-type=e2-standard-4 \
    --num-nodes=4 \
    --workload-pool=${WORKLOAD_POOL} \
    --enable-stackdriver-kubernetes \
    --subnetwork=default \
    --scopes cloud-platform \
    --labels mesh_id=${MESH_ID} -q --verbosity none & 
