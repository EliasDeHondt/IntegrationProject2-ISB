############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 18/09/2024        #
############################
# This script will create a kubernetes cluster and deploy a:
# Apllication: https://github.com/streamaserver/streama
# Database: MySQL
# Storage: Rook volume

# UI variables
reset="\e[0m"                                                               # Reset
red="\e[0;31m"                                                              # Red
green="\e[0;32m"                                                            # Green

cluster_name="cluster-1"
zone="us-central1-c"
num_nodes=3

# Functie: Error afhandeling.
function error_exit() {
    echo -e "\n*\n* ${red}$1${reset}\n*\n* Exiting script.\n"
    exit 1
}

# Functie: Succes afhandeling.
function success() {
    echo -e "\n*\n* ${green}$1${reset}\n*"
}

# Functie: Enable the required APIs.
function enable_apis() { # Step 1
    gcloud services enable container.googleapis.com > ./deployment-script.log 2>&1
    local EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then success "APIs enabled successfully."; else error_exit "Failed to enable the APIs."; fi
}

# Functie: Create the kubernetes cluster.
function create_cluster() { # Step 2
    gcloud container clusters create $cluster_name --region $zone --num-nodes $num_nodes --enable-ip-alias > ./deployment-script.log 2>&1
    local EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then success "Cluster created successfully."; else error_exit "Failed to create the cluster."; fi
}

# Functie: Get authentication credentials for the cluster.
function get_credentials() { # Step 3
    gcloud container clusters get-credentials $cluster_name --region $zone > ./deployment-script.log 2>&1
    local EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then success "Credentials retrieved successfully."; else error_exit "Failed to retrieve the credentials."; fi
}



# Start of the script.
function main() {
    enable_apis # Step 1
    create_cluster # Step 2
    get_credentials # Step 3
}

main

# kubectl get nodes
# kubectl get pods
# kubectl get deployments
# kubectl get services

# sudo apt-get install google-cloud-cli-gke-gcloud-auth-plugin

# gcloud container clusters delete $cluster_name --region $zone -q