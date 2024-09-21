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
min_nodes=3
max_nodes=5

# Functie: Error afhandeling.
function error_exit() {
    echo -e "\n*\n* ${red}$1${reset}\n*\n* Exiting script.\n"
    exit 1
}

# Functie: Succes afhandeling.
function success() {
    echo -e "\n*\n* ${green}$1${reset}\n*"
}

# Functie: Validate the external resources.
function validate_external_resources() { # Step 0
    if [ ! -f ./application.yaml ]; then error_exit "The application.yaml file is missing."; fi
}

# Functie: Enable the required APIs.
function enable_apis() { # Step 1
    gcloud services enable container.googleapis.com > ./deployment-script.log 2>&1
    local EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then success "APIs enabled successfully."; else error_exit "Failed to enable the APIs."; fi
}

# Functie: Create the kubernetes cluster.
function create_cluster() { # Step 2
    gcloud container clusters create $cluster_name \
        --region=$zone \
        --min-nodes=$min_nodes \
        --max-nodes=$max_nodes \
        --enable-ip-alias \
        --machine-type=n1-standard-4 \
        --enable-autoscaling > ./deployment-script.log 2>&1
    local EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then success "Cluster created successfully."; else error_exit "Failed to create the cluster."; fi
}

# Functie: Get authentication credentials for the cluster.
function get_credentials() { # Step 3
    gcloud container clusters get-credentials $cluster_name --region=$zone > ./deployment-script.log 2>&1
    local EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then success "Credentials retrieved successfully."; else error_exit "Failed to retrieve the credentials."; fi
}

# Functie: Deploy the application.
function deploy_application() { # Step 4
    kubectl apply -f ./apllication.yaml > ./deployment-script.log 2>&1
    local EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then success "Application deployed successfully."; else error_exit "Failed to deploy the application."; fi
}

# Start of the script.
function main() {
    validate_external_resources # Step 0
    enable_apis # Step 1
    create_cluster # Step 2
    get_credentials # Step 3
    deploy_application # Step 4
}

main # Start the script.